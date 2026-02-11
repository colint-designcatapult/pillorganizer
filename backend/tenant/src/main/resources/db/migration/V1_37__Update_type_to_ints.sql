alter table device_schedule_strategy alter column type type smallint USING type::smallint;
alter table device_dispense_time alter column type type smallint USING type::smallint;