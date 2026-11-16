package compiler

import (
	"strings"

	"github.com/sqlc-dev/sqlc/internal/sql/ast"
	"github.com/sqlc-dev/sqlc/internal/sql/astutils"
	"github.com/sqlc-dev/sqlc/internal/sql/catalog"
)

// rangeTyper types the expressions over ranges and multiranges that the
// compiler can type without analysis: a column or a cast, a function over a
// range whose result is polymorphic, and a range operator, however they
// nest, as lower(during * $1::tstzrange) does. It answers nothing for any
// other expression, which is left to the compiler's other rules.
type rangeTyper struct {
	cat *catalog.Catalog
	// column is the type of a column reference, or "" when it is not known.
	column func(*ast.ColumnRef) string
	// subquery is the type of the one column a scalar subquery returns, or
	// "" when it is not known; nil when the caller cannot type one.
	subquery func(*ast.SelectStmt) string
}

// rangeType is what a rangeTyper knows of an expression: its type name, ""
// when not known, and whether it may be NULL whatever its operands are, as a
// bound of a range may.
type rangeType struct {
	name     string
	nullable bool
	// ranged is whether a range decided the type: the expression is a
	// range or multirange, or a range function or operator computed it.
	ranged bool
}

// typeOf types an expression as far as the typer can.
func (r rangeTyper) typeOf(n ast.Node) rangeType {
	switch n := n.(type) {
	case *ast.ColumnRef:
		if hasStarRef(n) {
			return rangeType{}
		}
		return r.value(r.column(n))
	case *ast.TypeCast:
		if n.TypeName == nil {
			return rangeType{}
		}
		col := toColumn(n.TypeName)
		if col.IsArray {
			return rangeType{}
		}
		return r.value(col.DataType)
	case *ast.FuncCall:
		argTypes := r.argTypes(n)
		fun, err := r.cat.ResolveFuncCallWithArgTypes(n, argTypes)
		if err != nil {
			return rangeType{}
		}
		if t, ok := r.funcResult(fun, argTypes); ok {
			return t
		}
		// A function that names its result type, as the tstzrange
		// constructor does, returns that type whatever it is called with.
		if fun.ReturnType != nil && !isPseudoType(fun.ReturnType.Name) {
			return r.value(dataType(fun.ReturnType))
		}
		return rangeType{}
	case *ast.A_Expr:
		t, _ := r.operatorResult(astutils.Join(n.Name, ""), r.typeOf(n.Lexpr).name, r.typeOf(n.Rexpr).name)
		return t
	case *ast.SubLink:
		// A scalar subquery has the type of the column it returns.
		if n.SubLinkType == ast.EXPR_SUBLINK && r.subquery != nil {
			if sel, ok := n.Subselect.(*ast.SelectStmt); ok {
				return r.value(r.subquery(sel))
			}
		}
	case *ast.List:
		// The values of a list, as BETWEEN and IN test against, share a
		// type, which any of them may say.
		for _, item := range n.Items {
			if t := r.typeOf(item); t.name != "" {
				return t
			}
		}
	case *ast.CoalesceExpr:
		// The alternatives of a COALESCE share a type, which any of them
		// may say.
		if n.Args != nil {
			for _, arg := range n.Args.Items {
				if t := r.typeOf(arg); t.name != "" {
					return t
				}
			}
		}
	case *ast.CaseExpr:
		// So do the results of a CASE, the default among them.
		results := []ast.Node{n.Defresult}
		if n.Args != nil {
			for _, item := range n.Args.Items {
				if when, ok := item.(*ast.CaseWhen); ok {
					results = append(results, when.Result)
				}
			}
		}
		for _, result := range results {
			if result == nil {
				continue
			}
			if t := r.typeOf(result); t.name != "" {
				return rangeType{name: t.name, ranged: t.ranged}
			}
		}
	}
	return rangeType{}
}

// isPseudoType reports whether a function's declared result says nothing
// of the type it returns: a polymorphic type, or no type at all.
func isPseudoType(typeName string) bool {
	name := strings.ToLower(typeName)
	return strings.HasPrefix(name, "any") || name == "void" || name == "record" ||
		name == "trigger" || name == "event_trigger" || name == "internal" || name == "unknown"
}

// value types a value of a known type, which a range decided when it is a
// range or multirange.
func (r rangeTyper) value(typeName string) rangeType {
	_, _, ranged := r.rangeOf(typeName)
	return rangeType{name: typeName, ranged: ranged}
}

// argTypes is the type of each positional argument of a call, as far as the
// typer can tell.
func (r rangeTyper) argTypes(call *ast.FuncCall) []string {
	if call.Args == nil {
		return nil
	}
	types := make([]string, len(call.Args.Items))
	for i, arg := range call.Args.Items {
		types[i] = r.typeOf(arg).name
	}
	return types
}

// rangeOf reports the range type a range or multirange type holds, and the
// multirange type itself when it is one.
func (r rangeTyper) rangeOf(typeName string) (rng, multirange string, ok bool) {
	if typeName == "" {
		return "", "", false
	}
	if _, ok := r.cat.RangeElement(typeName); ok {
		return typeName, "", true
	}
	if rng, ok := r.cat.MultirangeRange(typeName); ok {
		return rng, typeName, true
	}
	return "", "", false
}

// funcResult types the result of a function whose first parameter is a
// polymorphic range or multirange, for the range or multirange it was called
// with: its subtype, nullable since an empty or unbounded range has no
// bound on that side, as lower returns; its range type, as range_merge and
// unnest return; or its multirange type, as range_agg returns.
func (r rangeTyper) funcResult(fun *catalog.Function, argTypes []string) (rangeType, bool) {
	params := fun.InArgs()
	if len(params) == 0 || len(argTypes) == 0 || params[0].Type == nil || fun.ReturnType == nil {
		return rangeType{}, false
	}
	param := rangePolymorphism(params[0].Type.Name)
	if param != polyRange && param != polyMultirange {
		return rangeType{}, false
	}
	rng, multirange, ok := r.rangeOf(argTypes[0])
	if !ok || (param == polyMultirange) != (multirange != "") {
		return rangeType{}, false
	}
	switch rangePolymorphism(fun.ReturnType.Name) {
	case polyElement:
		element, ok := r.cat.RangeElement(rng)
		if !ok {
			return rangeType{}, false
		}
		return rangeType{name: element, nullable: true, ranged: true}, true
	case polyRange:
		return rangeType{name: rng, ranged: true}, true
	case polyMultirange:
		if multirange == "" {
			if multirange, ok = r.cat.RangeMultirange(rng); !ok {
				return rangeType{}, false
			}
		}
		return rangeType{name: multirange, ranged: true}, true
	}
	return rangeType{}, false
}

// operatorResult types an operator applied to a range or multirange: the
// operators that compare ranges, or a range and an element, are predicates,
// and union, difference and intersection return the operands' type, a
// multirange when either is one. It reports false when neither operand is a
// range or multirange, whatever the operator.
func (r rangeTyper) operatorResult(op, left, right string) (rangeType, bool) {
	_, leftMulti, leftOK := r.rangeOf(left)
	_, rightMulti, rightOK := r.rangeOf(right)
	if !leftOK && !rightOK {
		return rangeType{}, false
	}
	switch op {
	case "&&", "@>", "<@", "-|-", "<<", ">>", "&<", "&>":
		return rangeType{name: "bool", ranged: true}, true
	case "+", "-", "*":
		if leftMulti != "" || (leftOK && rightMulti == "") {
			return rangeType{name: left, ranged: true}, true
		}
		return rangeType{name: right, ranged: true}, true
	}
	return rangeType{}, false
}

// The kinds of polymorphic type the range functions relate: an element, a
// range of elements and a multirange of ranges.
const (
	polyOther = iota
	polyElement
	polyRange
	polyMultirange
)

// rangePolymorphism classifies a polymorphic type by what it stands for
// among the range functions' parameters and results.
func rangePolymorphism(typeName string) int {
	switch strings.ToLower(typeName) {
	case "anyelement", "anycompatible", "anynonarray", "anycompatiblenonarray":
		return polyElement
	case "anyrange", "anycompatiblerange":
		return polyRange
	case "anymultirange", "anycompatiblemultirange":
		return polyMultirange
	}
	return polyOther
}
