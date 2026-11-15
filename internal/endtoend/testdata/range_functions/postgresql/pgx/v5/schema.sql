CREATE TABLE reservations (
    id         integer   NOT NULL,
    name       text      NOT NULL,
    during     tstzrange NOT NULL,
    wall_clock tsrange   NOT NULL,
    days       daterange NOT NULL,
    seats      int4range NOT NULL,
    row_ids    int8range NOT NULL,
    price      numrange  NOT NULL
);
