-- name: GetAuthor :one
SELECT * FROM authors WHERE id = $1;

-- name: GetBook :one
SELECT * FROM books WHERE author_id = $1 AND isbn = $2;

-- name: GetTag :one
SELECT * FROM tags WHERE slug = $1;
