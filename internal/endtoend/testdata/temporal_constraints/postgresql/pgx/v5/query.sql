-- name: GetRoomAt :one
SELECT * FROM rooms
WHERE id = $1 AND valid_at @> sqlc.arg(at)::timestamptz;

-- name: ListRoomCodes :many
SELECT * FROM room_codes WHERE room_id = $1;

-- name: CreateBooking :one
INSERT INTO bookings (id, room_id, valid_at, guest)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: ListBookingsDuring :many
SELECT b.id, b.guest, r.name AS room_name
FROM bookings b
JOIN rooms r ON r.id = b.room_id AND r.valid_at && b.valid_at
WHERE b.valid_at && sqlc.arg(during)::tstzrange;

-- name: SetRoomRate :exec
INSERT INTO room_rates (room_id, valid_at, amount) VALUES ($1, $2, $3);
