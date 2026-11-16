-- name: ListViewBounds :many
-- A range a view passes on reaches a range function as the table's does,
-- and the view is a model in both analyzers.
SELECT lower(during) AS starts_at FROM reservation_periods;
