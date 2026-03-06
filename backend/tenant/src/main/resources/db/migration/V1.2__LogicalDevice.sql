CREATE TABLE logical_device (
    id text PRIMARY KEY,
    physical_device_id TEXT,
    nickname TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    disabled_at TIMESTAMP,
    version BIGINT
);
