CREATE TABLE device_schedule (
    id            TEXT PRIMARY KEY,
    device_id     TEXT NOT NULL REFERENCES logical_device(id),
    schedule_json TEXT NOT NULL,
    status        TEXT NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP,
    created_by_id TEXT NOT NULL REFERENCES users(id)
);
