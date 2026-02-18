ALTER TABLE device ALTER COLUMN serial_no TYPE bigint USING get_byte(serial_no, 0)::bigint << 8
    | get_byte(serial_no, 1) << 8
    | get_byte(serial_no, 2) << 8
    | get_byte(serial_no, 3) << 8
    | get_byte(serial_no, 4) << 8
    | get_byte(serial_no, 5);
