create table device (
    id              bigint not null primary key,
    device_class    int not null,
    serial_no       bytea unique
);
CREATE SEQUENCE device_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;

create unique index device_serial on device (serial_no);

create table device_event (
    id              bigint not null primary key,
    device_id       bigint not null,
    ts              timestamp not null,
    event_type      int not null
);
CREATE SEQUENCE device_event_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;

create table device_schedule (
    id                  bigint not null primary key,
    device_id           bigint not null,
    bin_id              int not null,
    day_of_week         int not null,
    seconds_from_00     int not null
);
CREATE SEQUENCE device_schedule_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;

create index device_schedule_device_id on device_schedule(device_id);
create unique index device_schedule_device_bin on device_schedule(device_id, bin_id)