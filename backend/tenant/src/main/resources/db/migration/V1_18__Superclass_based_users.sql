drop table anonymous_user;

ALTER TABLE users ADD COLUMN user_type char not null default 'U';
ALTER TABLE users ADD COLUMN secret bytea;
