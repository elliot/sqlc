package core

import (
	"context"
	"fmt"

	"github.com/sqlc-dev/sqlc/internal/core/catalogdb"
)

func (c *Catalog) CreateClass(namespaceOID int64, name string, kind string) (int64, error) {
	oid, err := c.q.CreateClass(context.Background(), catalogdb.CreateClassParams{
		NamespaceOid: namespaceOID,
		Name:         name,
		Kind:         kind,
	})
	if err != nil {
		return 0, fmt.Errorf("create class %q: %w", name, err)
	}
	return oid, nil
}

// CreateDeclaredClass records a relation the schema declares, as against
// one the dialect seeds.
func (c *Catalog) CreateDeclaredClass(namespaceOID int64, name string, kind string) (int64, error) {
	oid, err := c.q.CreateDeclaredClass(context.Background(), catalogdb.CreateDeclaredClassParams{
		NamespaceOid: namespaceOID,
		Name:         name,
		Kind:         kind,
	})
	if err != nil {
		return 0, fmt.Errorf("create class %q: %w", name, err)
	}
	return oid, nil
}

func (c *Catalog) ClassOID(namespaceOID int64, name string) (int64, error) {
	oid, err := c.q.ClassOID(context.Background(), catalogdb.ClassOIDParams{
		NamespaceOid: namespaceOID,
		Name:         name,
	})
	if err != nil {
		return 0, fmt.Errorf("class %q: %w", name, err)
	}
	return oid, nil
}

func (c *Catalog) ClassOIDByName(name string) (int64, error) {
	oid, err := c.q.ClassOIDByName(context.Background(), name)
	if err != nil {
		return 0, fmt.Errorf("class %q: %w", name, err)
	}
	return oid, nil
}

func (c *Catalog) DropClass(classOID int64) error {
	ctx := context.Background()
	if err := c.q.DeleteAttributesByClass(ctx, classOID); err != nil {
		return fmt.Errorf("drop class %d attributes: %w", classOID, err)
	}
	if err := c.q.DeleteClass(ctx, classOID); err != nil {
		return fmt.Errorf("drop class %d: %w", classOID, err)
	}
	return nil
}

func (c *Catalog) RenameClass(classOID int64, name string) error {
	err := c.q.RenameClass(context.Background(), catalogdb.RenameClassParams{
		Oid:     classOID,
		NewName: name,
	})
	if err != nil {
		return fmt.Errorf("rename class %d: %w", classOID, err)
	}
	return nil
}

type ClassInfo struct {
	OID  int64
	Name string
}

// ModelClassesInNamespace lists the relations codegen makes models of: every
// table and, with views, the views the schema declares, as against the
// system views a dialect seeds.
func (c *Catalog) ModelClassesInNamespace(namespaceOID int64, views bool) ([]ClassInfo, error) {
	ctx := context.Background()
	var out []ClassInfo
	if views {
		rows, err := c.q.ListModelClassesInNamespace(ctx, namespaceOID)
		if err != nil {
			return nil, fmt.Errorf("list relations in namespace %d: %w", namespaceOID, err)
		}
		for _, r := range rows {
			out = append(out, ClassInfo{OID: r.Oid, Name: r.Name})
		}
		return out, nil
	}
	rows, err := c.q.ListTablesInNamespace(ctx, namespaceOID)
	if err != nil {
		return nil, fmt.Errorf("list tables in namespace %d: %w", namespaceOID, err)
	}
	for _, r := range rows {
		out = append(out, ClassInfo{OID: r.Oid, Name: r.Name})
	}
	return out, nil
}
