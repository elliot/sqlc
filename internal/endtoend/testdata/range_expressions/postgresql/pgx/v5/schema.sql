CREATE TABLE reservations (
    id      integer   NOT NULL,
    during  tstzrange NOT NULL,
    blocked tstzrange NOT NULL,
    days    daterange NOT NULL,
    hold    tstzrange
);
