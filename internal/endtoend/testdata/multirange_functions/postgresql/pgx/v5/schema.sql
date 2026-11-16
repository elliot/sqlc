CREATE TABLE schedules (
    id       integer        NOT NULL,
    slot     tstzrange      NOT NULL,
    busy     tstzmultirange NOT NULL,
    days_off datemultirange NOT NULL,
    seats    int4multirange NOT NULL
);
