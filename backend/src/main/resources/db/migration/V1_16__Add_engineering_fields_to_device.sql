ALTER TABLE device ADD COLUMN engr_mode boolean not null default false;
ALTER TABLE device ADD COLUMN engr_data jsonb default null;
ALTER TABLE device ADD COLUMN engr_req jsonb default null;
