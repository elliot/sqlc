CREATE TABLE reservations (
    id     integer   NOT NULL,
    during tstzrange NOT NULL
);

CREATE VIEW reservation_periods AS SELECT id, during FROM reservations;
