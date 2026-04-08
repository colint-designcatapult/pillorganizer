CREATE TABLE device_event (
    id               UUID PRIMARY KEY,
    logical_device_id TEXT NOT NULL,
    timestamp        TIMESTAMPTZ NOT NULL,
    event_type       TEXT NOT NULL,
    bin_id           INTEGER,
    metadata         TEXT,
    schedule_id      TEXT,
    CONSTRAINT uq_device_event UNIQUE NULLS NOT DISTINCT (logical_device_id, timestamp, event_type, bin_id)
);
