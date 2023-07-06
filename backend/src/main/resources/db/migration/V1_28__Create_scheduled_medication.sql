
create table "scheduled_medication" (
    id              bigint not null primary key,
    med_name        varchar not null,
    shape           int,
    color           int
);

CREATE SEQUENCE scheduled_medication_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;


create table "dose_schedule" (
    id              bigint not null primary key,
    medication_id   bigint not null,
    days_of_week    int not null default 0,
    secondsFrom00   int not null default 0,
    quantity        int not null default 0
);

CREATE SEQUENCE dose_schedule_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;