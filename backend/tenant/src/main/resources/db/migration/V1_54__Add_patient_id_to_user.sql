-- Add patient_id column to store Takecare patient identifier
ALTER TABLE users ADD COLUMN takecare_patient_id varchar(255);

-- Create index for patient_id lookups (optional but recommended for performance)
CREATE INDEX idx_users_takecare_patient_id ON users (takecare_patient_id);

-- Add comment to document the purpose of this column
COMMENT ON COLUMN users.takecare_patient_id IS 'Takecare FHIR patient identifier for validated users'; 