alter table device_event add column epoch_week timestamptz,
                         add column scheduled_time timestamptz;