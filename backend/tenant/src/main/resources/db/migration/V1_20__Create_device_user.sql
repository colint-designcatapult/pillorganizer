create table "device_user" (
    id              bigint not null primary key,
    device_id       bigint not null,
    user_id         bigint not null
);
create unique index device_user_unique on "device_user" (device_id, user_id);

CREATE SEQUENCE device_user_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;