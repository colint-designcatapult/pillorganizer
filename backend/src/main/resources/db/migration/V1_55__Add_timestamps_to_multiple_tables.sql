-- Add timestamp columns to device_schedule
ALTER TABLE device_schedule
    ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN deleted_at timestamp with time zone;

-- Add timestamp columns to device_schedule_strategy
ALTER TABLE device_schedule_strategy
    ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN deleted_at timestamp with time zone;

-- Add timestamp columns to device_state
ALTER TABLE device_state
    ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN deleted_at timestamp with time zone;

-- Add timestamp columns to device_user
ALTER TABLE device_user
    ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN deleted_at timestamp with time zone;

-- Add timestamp columns to dose_schedule
ALTER TABLE dose_schedule
    ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN deleted_at timestamp with time zone;

-- Add timestamp columns to medication_dispense_time
ALTER TABLE medication_dispense_time
    ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN deleted_at timestamp with time zone;

-- Add timestamp columns to scheduled_medication
ALTER TABLE scheduled_medication
    ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ADD COLUMN deleted_at timestamp with time zone;

-- Add triggers to automatically update the updated_at column
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for each table
CREATE TRIGGER update_device_schedule_modtime
BEFORE UPDATE ON device_schedule
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_device_schedule_strategy_modtime
BEFORE UPDATE ON device_schedule_strategy
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_device_state_modtime
BEFORE UPDATE ON device_state
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_device_user_modtime
BEFORE UPDATE ON device_user
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_dose_schedule_modtime
BEFORE UPDATE ON dose_schedule
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_medication_dispense_time_modtime
BEFORE UPDATE ON medication_dispense_time
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_scheduled_medication_modtime
BEFORE UPDATE ON scheduled_medication
FOR EACH ROW EXECUTE FUNCTION update_modified_column();
