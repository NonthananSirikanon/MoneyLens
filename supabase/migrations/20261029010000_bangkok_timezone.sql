-- Show timestamps and `current_date` in Thai time.
--
-- `timestamptz` columns always store an absolute instant (UTC internally);
-- this only changes how new sessions display and interpret them, so existing
-- rows keep the same instants. It also makes the birth-date check
-- (`birth_date <= current_date`) use the Thai calendar day.
alter database postgres set timezone to 'Asia/Bangkok';
