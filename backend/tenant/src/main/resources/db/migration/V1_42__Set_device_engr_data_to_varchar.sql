alter table device alter column engr_data type varchar using engr_data::text;
alter table device alter column engr_req type varchar using engr_req::text;