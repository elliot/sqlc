-- name: ListNestedBounds :many
-- A bound of a range expression has the range's subtype, however the
-- range was computed.
SELECT
    lower(during * blocked)                AS overlap_start,
    upper(range_merge(during, blocked))    AS hull_end,
    lower(days + days)                     AS first_day
FROM reservations;

-- name: ListRangePredicates :many
-- Range operators that compare ranges, or a range and an element, are
-- predicates.
SELECT
    id,
    during && blocked AS overlaps_block,
    during @> now()   AS contains_now,
    now() <@ during   AS now_within,
    during -|- blocked AS adjoins_block,
    during << blocked AS before_block,
    during >> blocked AS after_block,
    during &< blocked AS ends_by_block_end,
    upper_inf(during) AS is_current,
    isempty(during)   AS is_empty
FROM reservations;

-- name: ListByBounds :many
-- A parameter compared with a bound has the range's subtype, and is
-- nullable as the bound is.
SELECT id FROM reservations
WHERE lower(during) >= sqlc.arg(starts_after)
  AND upper(during) < sqlc.arg(ends_before);

-- name: ListByFirstDay :many
SELECT id FROM reservations WHERE lower(days) = sqlc.arg(first_day);

-- name: ListOverlapping :many
-- A parameter compared with a range is a range.
SELECT id FROM reservations WHERE during && sqlc.arg(window);

-- name: ListContaining :many
SELECT id FROM reservations WHERE during @> sqlc.arg(at)::timestamptz;

-- name: ListComputedBounds :many
-- A range a function builds, or COALESCE or CASE chooses, is typed as well.
SELECT
    upper(tstzrange(lower(during), now()))                 AS span_end,
    lower(coalesce(hold, during))                          AS effective_start,
    lower(CASE WHEN id > 0 THEN during ELSE blocked END)   AS chosen_start
FROM reservations;

-- name: ListStartingBetween :many
-- A parameter in a BETWEEN or an IN list compared with a bound has the
-- range's subtype, and is nullable as the bound is.
SELECT id FROM reservations
WHERE lower(during) BETWEEN sqlc.arg(from_time) AND sqlc.arg(to_time);

-- name: ListByFirstDays :many
SELECT id FROM reservations
WHERE lower(days) IN (sqlc.arg(first_day), sqlc.arg(other_day));
