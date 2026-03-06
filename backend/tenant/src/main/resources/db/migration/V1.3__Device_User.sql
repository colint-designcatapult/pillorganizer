CREATE TABLE device_user (
    id UUID NOT NULL PRIMARY KEY,
    device_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    primary_user BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unique(user_id, device_id)
);
