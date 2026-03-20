ALTER TABLE logical_device
    ADD COLUMN current_schedule_id   TEXT,
    ADD COLUMN requested_schedule_id TEXT;
