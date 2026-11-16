-- PostgreSQL 18 temporal constraints: WITHOUT OVERLAPS on primary keys and
-- unique constraints, and PERIOD on foreign keys. GiST needs btree_gist to
-- index the scalar key columns alongside the range.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- The key columns are declared without NOT NULL: the temporal primary key
-- makes them NOT NULL, just like an ordinary primary key.
CREATE TABLE rooms (
    id       integer,
    valid_at tstzrange,
    name     text NOT NULL,
    CONSTRAINT rooms_pkey PRIMARY KEY (id, valid_at WITHOUT OVERLAPS)
);

-- A temporal unique constraint does not make its columns NOT NULL.
CREATE TABLE room_codes (
    code     text,
    room_id  integer NOT NULL,
    valid_at tstzrange,
    UNIQUE (code, valid_at WITHOUT OVERLAPS)
);

CREATE TABLE bookings (
    id       integer,
    room_id  integer NOT NULL,
    valid_at tstzrange,
    guest    text,
    PRIMARY KEY (id, valid_at WITHOUT OVERLAPS),
    FOREIGN KEY (room_id, PERIOD valid_at) REFERENCES rooms (id, PERIOD valid_at)
);

CREATE TABLE room_rates (
    room_id  integer NOT NULL,
    valid_at tstzrange NOT NULL,
    amount   numeric NOT NULL
);

ALTER TABLE room_rates
    ADD CONSTRAINT room_rates_uniq UNIQUE (room_id, valid_at WITHOUT OVERLAPS);

ALTER TABLE room_rates
    ADD CONSTRAINT room_rates_room_fk
    FOREIGN KEY (room_id, PERIOD valid_at) REFERENCES rooms (id, PERIOD valid_at);

-- A temporal primary key added by ALTER TABLE makes its columns NOT NULL as
-- well, which is how a migration usually introduces one.
CREATE TABLE room_closures (
    room_id  integer,
    valid_at tstzrange,
    reason   text
);

ALTER TABLE room_closures
    ADD CONSTRAINT room_closures_pkey PRIMARY KEY (room_id, valid_at WITHOUT OVERLAPS);
