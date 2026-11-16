-- A range the schema declares comes with a multirange, named after it or
-- as multirange_type_name says.
CREATE TYPE floatrange AS RANGE (subtype = float8);
CREATE TYPE textspan AS RANGE (subtype = text, multirange_type_name = textspans);

CREATE TABLE schedules (
    id       integer         NOT NULL,
    slot     tstzrange       NOT NULL,
    busy     tstzmultirange  NOT NULL,
    days_off datemultirange  NOT NULL,
    seats    int4multirange  NOT NULL,
    ratios   floatmultirange NOT NULL,
    labels   textspans       NOT NULL
);
