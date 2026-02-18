ALTER TABLE device_schedule DROP CONSTRAINT device_schedule_pkey;
ALTER TABLE device_schedule DROP COLUMN id;
ALTER TABLE device_schedule ADD CONSTRAINT device_schedule_pkey  PRIMARY KEY (device_id, bin_id)