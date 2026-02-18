create table "anonymous_user" (
    id   bigint not null primary key,
    secret   bytea
);

CREATE SEQUENCE anonymous_user_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;