-- Disable foreign key constraints temporarily
SET CONSTRAINTS ALL DEFERRED;

-- Truncate all tables
TRUNCATE TABLE device_state CASCADE;
TRUNCATE TABLE device_schedule CASCADE;
TRUNCATE TABLE device_event CASCADE;
TRUNCATE TABLE device_provision CASCADE;
TRUNCATE TABLE device_schedule_strategy CASCADE;
TRUNCATE TABLE scheduled_medication CASCADE;
TRUNCATE TABLE device_user CASCADE;
TRUNCATE TABLE device CASCADE;
TRUNCATE TABLE device_caregiver_code CASCADE;
TRUNCATE TABLE device_dispense_time CASCADE;
TRUNCATE TABLE dose_schedule CASCADE;
TRUNCATE TABLE medication_dispense_time CASCADE;
TRUNCATE TABLE users CASCADE;

-- Re-enable foreign key constraints
SET CONSTRAINTS ALL IMMEDIATE;