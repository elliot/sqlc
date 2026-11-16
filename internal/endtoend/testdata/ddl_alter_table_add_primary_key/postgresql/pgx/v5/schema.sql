-- A primary key makes its columns NOT NULL, whether CREATE TABLE declares
-- it or ALTER TABLE adds it later.
CREATE TABLE authors (
    id   bigint,
    name text
);
ALTER TABLE authors ADD PRIMARY KEY (id);

CREATE TABLE books (
    author_id bigint,
    isbn      text,
    title     text
);
ALTER TABLE books ADD CONSTRAINT books_pkey PRIMARY KEY (author_id, isbn);

-- A unique constraint does not.
CREATE TABLE tags (
    slug  text,
    label text
);
ALTER TABLE tags ADD UNIQUE (slug);
