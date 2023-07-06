create table "medication_dispense_time" (
                               id              bigint not null primary key,
                               medication_id   bigint not null,
                               dispense_id     bigint not null,
                               quantity        int not null
);
create unique index medication_dispense_time_unique on "medication_dispense_time" (medication_id, dispense_id);

CREATE SEQUENCE medication_dispense_time_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;