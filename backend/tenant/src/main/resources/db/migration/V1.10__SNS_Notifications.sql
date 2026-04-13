ALTER TABLE logical_device
    ADD COLUMN IF NOT EXISTS topic_arn VARCHAR(512);
