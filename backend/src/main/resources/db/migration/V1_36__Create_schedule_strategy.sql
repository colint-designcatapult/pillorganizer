create table device_schedule_strategy (
                        id              bigint not null primary key,
                        type            char not null,
                        device_id       bigint not null
);
CREATE SEQUENCE device_schedule_strategy_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;

create table device_dispense_time (
                                          id              bigint not null primary key,
                                          type            char not null,
                                          schedule_id     bigint not null,
                                          time            time
);
CREATE SEQUENCE device_dispense_time_seq MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 100;
