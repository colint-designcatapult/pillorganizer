CREATE TABLE device_schedule (
    id            UUID PRIMARY KEY,
    device_id     TEXT NOT NULL,
    schedule_json TEXT NOT NULL,
    status        TEXT NOT NULL,
    take_effect   TEXT NOT NULL DEFAULT 'IMMEDIATE',
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP,
    created_by_id TEXT NOT NULL
);
