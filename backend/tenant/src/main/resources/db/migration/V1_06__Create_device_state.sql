create table device_state (
    device_id           bigint not null,
    bin_id              int not null,
    bin_status          int not null,
    scheduled_time      timestamp,
    version             bigint,
    primary key(device_id, bin_id)
);
create index device_state_device_id_idx on device_state (device_id);
CREATE SEQUENCE device_state_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;
