-- name: ListMultirangeBounds :many
-- A bound of a multirange has its ranges' subtype, and is NULL when the
-- multirange is empty or unbounded on that side.
SELECT
    lower(busy)     AS busy_from,
    upper(busy)     AS busy_until,
    lower(days_off) AS first_day_off,
    upper(seats)    AS max_seat
FROM schedules;

-- name: ListHulls :many
-- range_merge() of a multirange is a range; multirange() of a range, and
-- multirange operators, are multiranges.
SELECT
    id,
    range_merge(busy)        AS busy_hull,
    busy * busy              AS busy_overlap,
    busy + multirange(slot)  AS busy_with_slot
FROM schedules;

-- name: GetCoverage :one
-- range_agg() gathers ranges into a multirange.
SELECT range_agg(slot) AS coverage FROM schedules;

-- name: ListBusyPieces :many
-- unnest() of a multirange returns its ranges.
SELECT unnest(busy) AS piece FROM schedules;

-- name: ListMultirangePredicates :many
SELECT
    id,
    busy @> slot  AS covers_slot,
    busy && slot  AS overlaps_slot,
    busy -|- slot AS adjoins_slot
FROM schedules;

-- name: ListBusyAt :many
SELECT id FROM schedules WHERE busy @> sqlc.arg(at)::timestamptz;
