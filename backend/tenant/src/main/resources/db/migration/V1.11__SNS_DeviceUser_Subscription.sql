ALTER TABLE device_user
    ADD COLUMN IF NOT EXISTS subscription_arn VARCHAR(512);
