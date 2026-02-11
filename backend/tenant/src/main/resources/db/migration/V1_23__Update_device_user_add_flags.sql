ALTER TABLE device_user ADD COLUMN owner boolean default false;
ALTER TABLE device_user ADD COLUMN primary_user boolean default false;

create unique index device_user_one_owner on "device_user" (device_id, owner);
create unique index device_user_one_primary_user on "device_user" (device_id, primary_user);
