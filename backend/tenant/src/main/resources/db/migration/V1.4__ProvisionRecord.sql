CREATE TABLE provision_record (
    device_id TEXT PRIMARY KEY,
    serial_no TEXT NOT NULL,
    claim_token TEXT NOT NULL,
    device_class TEXT NOT NULL,
    logical_device_id UUID,
    provisioned_by_id TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    disabled_at TIMESTAMP,
    version BIGINT
);