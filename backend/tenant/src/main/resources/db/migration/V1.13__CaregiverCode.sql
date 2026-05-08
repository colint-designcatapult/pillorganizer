CREATE TABLE caregiver_code (
    id          UUID        PRIMARY KEY,
    device_id   TEXT        NOT NULL,
    patient_id  TEXT        NOT NULL,
    nickname    TEXT        NOT NULL,
    code        INTEGER     NOT NULL,
    expires_at  TIMESTAMP   NOT NULL,
    deleted     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);