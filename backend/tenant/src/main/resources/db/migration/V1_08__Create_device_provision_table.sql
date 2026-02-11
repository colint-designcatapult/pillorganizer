create table device_provision (
    id              bigint not null primary key,
    device_id       bigint not null,
    active          bool not null,
    oob_key         bytea not null,
    bssid           macaddr,
    ssid            varchar,
    version         bigint not null default 0,
    created         timestamp,
    updated         timestamp
);
CREATE SEQUENCE device_provision_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;
