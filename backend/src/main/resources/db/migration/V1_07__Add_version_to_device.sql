ALTER TABLE device ADD COLUMN version bigint DEFAULT 0;
ALTER TABLE device ADD COLUMN state_hash bigint DEFAULT null;