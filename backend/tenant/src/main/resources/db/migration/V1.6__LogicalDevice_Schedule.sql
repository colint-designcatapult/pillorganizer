ALTER TABLE logical_device
    ADD COLUMN current_schedule_id   UUID,
    ADD COLUMN requested_schedule_id UUID;
