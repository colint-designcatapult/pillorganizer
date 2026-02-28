CREATE TABLE device (
    id VARCHAR(255) PRIMARY KEY,
    device_class VARCHAR(255) NOT NULL,
    serial_no VARCHAR(255) NOT NULL UNIQUE,
    claim_token VARCHAR(255) NOT NULL,
    version BIGINT NOT NULL DEFAULT 0,
    nickname VARCHAR(255)
);
