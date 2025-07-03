-- Add device_user_id column to device_state
ALTER TABLE device_state
    ADD COLUMN device_user_id bigint;

-- Update device_state relationships
UPDATE device_state ds
SET device_user_id = du.id
FROM device_user du
WHERE ds.device_id = du.device_id
AND du.primary_user = true;

-- Make device_user_id not null after migration
ALTER TABLE device_state
    ALTER COLUMN device_user_id SET NOT NULL,
    ADD CONSTRAINT fk_device_state_device_user
        FOREIGN KEY (device_user_id)
        REFERENCES device_user(id);

-- Add device_user_id column to device_event
ALTER TABLE device_event
    ADD COLUMN device_user_id bigint;

-- Update device_event relationships
UPDATE device_event de
SET device_user_id = du.id
FROM device_user du
WHERE de.device_id = du.device_id
AND du.primary_user = true;

-- Make device_user_id not null after migration
ALTER TABLE device_event
    ALTER COLUMN device_user_id SET NOT NULL,
    ADD CONSTRAINT fk_device_event_device_user
        FOREIGN KEY (device_user_id)
        REFERENCES device_user(id);

-- Add device_user_id to scheduled_medication
ALTER TABLE scheduled_medication
    ADD COLUMN device_user_id bigint;

-- Update scheduled_medication relationships
UPDATE scheduled_medication sm
SET device_user_id = du.id
FROM device_user du
WHERE sm.device_id = du.device_id
AND du.primary_user = true;

-- Make device_user_id not null after migration
ALTER TABLE scheduled_medication
    ALTER COLUMN device_user_id SET NOT NULL,
    ADD CONSTRAINT fk_scheduled_medication_device_user
        FOREIGN KEY (device_user_id)
        REFERENCES device_user(id);

-- Drop old device_id columns and constraints where they're no longer needed
ALTER TABLE device_event
    DROP COLUMN IF EXISTS device_id;

ALTER TABLE scheduled_medication
    DROP COLUMN IF EXISTS device_id;

-- Add event counter to device table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'device' AND column_name = 'event_counter') THEN
        ALTER TABLE device ADD COLUMN event_counter bigint NOT NULL DEFAULT 0;
    END IF;
END $$;

-- Add device_user_id column to device_schedule_strategy
ALTER TABLE device_schedule_strategy
    ADD COLUMN device_user_id bigint;

-- Update device_schedule_strategy relationships
UPDATE device_schedule_strategy dss
SET device_user_id = du.id
FROM device_user du
WHERE dss.device_id = du.device_id
AND du.primary_user = true;

-- Make device_user_id not null after migration
ALTER TABLE device_schedule_strategy
    ALTER COLUMN device_user_id SET NOT NULL,
    ADD CONSTRAINT fk_device_schedule_strategy_device_user
        FOREIGN KEY (device_user_id)
        REFERENCES device_user(id);

-- Drop old device_id column and constraints
ALTER TABLE device_schedule_strategy
    DROP COLUMN IF EXISTS device_id;

-- Drop old foreign key constraints if they exist
ALTER TABLE device_state
    DROP CONSTRAINT IF EXISTS fk_device_state_device;

ALTER TABLE device_event
    DROP CONSTRAINT IF EXISTS fk_device_event_device;

ALTER TABLE device_schedule_strategy
    DROP CONSTRAINT IF EXISTS fk_device_schedule_strategy_device;

-- Drop any indexes that might reference these constraints
DROP INDEX IF EXISTS idx_device_state_device;
DROP INDEX IF EXISTS idx_device_event_device;
DROP INDEX IF EXISTS idx_device_schedule_strategy_device;

-- Add device_user_id column to device_schedule
ALTER TABLE device_schedule
    ADD COLUMN device_user_id bigint;

-- Make device_user_id not null after migration
ALTER TABLE device_schedule
    ALTER COLUMN device_user_id SET NOT NULL,
    ADD CONSTRAINT fk_device_schedule_device_user
        FOREIGN KEY (device_user_id)
        REFERENCES device_user(id);

-- Drop the device_id column from the composite primary key
-- First, drop the existing primary key constraint
ALTER TABLE device_schedule
DROP CONSTRAINT IF EXISTS device_schedule_pkey;

-- Create new primary key without device_id
ALTER TABLE device_schedule
    ADD PRIMARY KEY (device_user_id, bin_id);

-- Drop old device_id column and constraints
ALTER TABLE device_schedule
DROP CONSTRAINT IF EXISTS fk_device_schedule_device,
    DROP COLUMN IF EXISTS device_id;

 -- Drop existing constraints and indexes
ALTER TABLE device_state DROP CONSTRAINT IF EXISTS fk_device_state_device;
DROP INDEX IF EXISTS idx_device_state_device;

-- Remove device_id column
ALTER TABLE device_state DROP COLUMN IF EXISTS device_id;

-- Update foreign key constraint for device_user_id if it doesn't exist
ALTER TABLE device_state
DROP CONSTRAINT IF EXISTS fk_device_state_device_user;
ALTER TABLE device_state
    ADD CONSTRAINT fk_device_state_device_user
        FOREIGN KEY (device_user_id)
            REFERENCES device_user(id);

-- Add index on device_user_id for performance
CREATE INDEX IF NOT EXISTS idx_device_state_device_user
    ON device_state(device_user_id);