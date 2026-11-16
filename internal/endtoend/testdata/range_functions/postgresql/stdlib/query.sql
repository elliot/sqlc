-- name: ListBounds :many
-- lower() and upper() return a bound of the range, typed as the range's
-- subtype. A bound is NULL when the range is empty or unbounded on that
-- side, so it is nullable even though the column is not. A range the
-- schema declares has the subtype it declares.
SELECT
    lower(during)     AS starts_at,
    upper(during)     AS ends_at,
    lower(wall_clock) AS wall_clock_start,
    lower(days)       AS first_day,
    upper(days)       AS day_after_last,
    lower(seats)      AS min_seats,
    upper(seats)      AS max_seats,
    lower(row_ids)    AS first_row_id,
    lower(price)      AS min_price,
    lower(ratio)      AS min_ratio,
    upper(ratio)      AS max_ratio
FROM reservations;

-- name: ListNames :many
-- A text argument still picks the text overloads of lower() and upper().
SELECT lower(name) AS lower_name, upper(name) AS upper_name FROM reservations;

-- name: ListOverlaps :many
-- Range operators, and functions that combine ranges, return the range type.
SELECT
    id,
    during * sqlc.arg(window)::tstzrange             AS overlap,
    range_merge(during, sqlc.arg(window)::tstzrange) AS spanning,
    days + days                                      AS days_union,
    seats - seats                                    AS seats_left
FROM reservations
WHERE during && sqlc.arg(window)::tstzrange;
