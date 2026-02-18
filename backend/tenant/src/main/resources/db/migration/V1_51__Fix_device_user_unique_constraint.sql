DROP INDEX device_user_unique;

CREATE UNIQUE INDEX device_user_unique_not_deleted 
ON device_user (device_id, user_id) 
WHERE deleted = false;