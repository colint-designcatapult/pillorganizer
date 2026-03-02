CREATE TABLE logical_device (
    id UUID PRIMARY KEY,
    physical_device_id TEXT NOT NULL,
    nickname TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    disabled_at TIMESTAMP,
    version BIGINT
);
