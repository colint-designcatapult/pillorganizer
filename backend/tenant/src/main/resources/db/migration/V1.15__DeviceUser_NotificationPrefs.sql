ALTER TABLE device_user
    ADD COLUMN notify_take_now BOOLEAN,
    ADD COLUMN notify_taken    BOOLEAN,
    ADD COLUMN notify_missed   BOOLEAN;
