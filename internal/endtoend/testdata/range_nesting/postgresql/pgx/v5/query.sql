-- A range reaches a range function the same way whatever it comes from.

-- name: ListFunctionBounds :many
SELECT lower(active_period(id)) AS starts_at FROM reservations;

-- name: ListSubqueryBounds :many
SELECT lower((SELECT during FROM reservations LIMIT 1)) AS starts_at FROM reservations;

-- name: ListCteBounds :many
WITH periods AS (SELECT during FROM reservations)
SELECT lower(during) AS starts_at FROM periods;

-- name: ListDerivedBounds :many
SELECT lower(p.during) AS starts_at FROM (SELECT during FROM reservations) p;

-- A parameter compared with a bound has the range's subtype wherever the
-- comparison stands.

-- name: ListActiveAt :many
SELECT id FROM reservations WHERE sqlc.arg(at) BETWEEN lower(during) AND upper(during);

-- name: ListByAnyFirstDay :many
SELECT id FROM reservations WHERE lower(days) = ANY(sqlc.arg(first_days));

-- name: ListByFirstDaySlice :many
SELECT id FROM reservations WHERE lower(days) IN (sqlc.slice(first_days));

-- name: ListChangedEnd :many
SELECT id FROM reservations WHERE upper(during) IS DISTINCT FROM sqlc.arg(ends_at);

-- name: ListNotBefore :many
SELECT id FROM reservations WHERE NOT (lower(during) < sqlc.arg(since));

-- name: ListCteSince :many
WITH periods AS (SELECT id, during FROM reservations)
SELECT id FROM periods WHERE lower(during) >= sqlc.arg(since);

-- name: ListPhases :many
SELECT CASE WHEN lower(during) > sqlc.arg(cutoff) THEN 'late' ELSE 'early' END AS phase
FROM reservations;

-- name: MoveStart :exec
UPDATE reservations SET days = daterange(sqlc.arg(first_day), upper(days))
WHERE lower(days) < sqlc.arg(before_day);
