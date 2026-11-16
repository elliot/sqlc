-- name: ListViewBounds :many
-- A range a view passes on reaches a range function as the table's does.
SELECT lower(during) AS starts_at FROM reservation_periods;
