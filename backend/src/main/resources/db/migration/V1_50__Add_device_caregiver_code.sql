-- Create sequence for device_caregiver_code primary keys if not exists
CREATE SEQUENCE IF NOT EXISTS device_code_seq
    INCREMENT BY 1
    START WITH 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Create the device_caregiver_code table
CREATE TABLE device_caregiver_code (
                                       id bigint not null primary key,
                                       patient_id BIGINT NOT NULL,
                                       device_id BIGINT NOT NULL,
                                       code BIGINT NOT NULL,
                                       expires_at TIMESTAMP NOT NULL,
                                       deleted BOOLEAN DEFAULT FALSE NOT NULL
);

-- Add unique constraints (indexes)
ALTER TABLE device_caregiver_code
    ADD CONSTRAINT uk_device_caregiver_code_expires
        UNIQUE (code, expires_at);

-- Add foreign keys to link to the BaseUser entity (table name is 'users')
ALTER TABLE device_caregiver_code
    ADD CONSTRAINT fk_device_caregiver_code_patient
        FOREIGN KEY (patient_id)
            REFERENCES users(id);

-- Add foreign keys to link to the Device entity (table name is 'device')
ALTER TABLE device_caregiver_code
    ADD CONSTRAINT fk_device_caregiver_code_device
        FOREIGN KEY (device_id)
            REFERENCES device(id);
