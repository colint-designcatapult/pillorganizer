ALTER TABLE logical_device
    ADD COLUMN current_schedule_id   TEXT REFERENCES device_schedule(id),
    ADD COLUMN requested_schedule_id TEXT REFERENCES device_schedule(id);
