ALTER TABLE users drop column user_type;
ALTER TABLE users ADD COLUMN user_type int not null default 0;
