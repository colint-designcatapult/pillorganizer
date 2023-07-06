create table "user" (
    id              bigint not null primary key,
    email           varchar(255),
    password_hash   bytea
);
create unique index on "user" (email);

CREATE SEQUENCE user_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;