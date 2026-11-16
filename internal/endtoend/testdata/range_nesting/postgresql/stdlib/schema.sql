CREATE TABLE reservations (
    id     integer   NOT NULL,
    during tstzrange NOT NULL,
    days   daterange NOT NULL
);

CREATE FUNCTION active_period(rid integer) RETURNS tstzrange
    LANGUAGE sql AS $$ SELECT during FROM reservations WHERE id = rid $$;
