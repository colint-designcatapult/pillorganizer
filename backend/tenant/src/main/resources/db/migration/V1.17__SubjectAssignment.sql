CREATE TABLE subject_assignment (
    id UUID PRIMARY KEY,
    serial_no TEXT NOT NULL UNIQUE,
    subject_id TEXT NOT NULL UNIQUE,
    version BIGINT
);
