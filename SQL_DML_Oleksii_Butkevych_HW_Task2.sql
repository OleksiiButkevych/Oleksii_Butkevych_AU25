--Make sure to turn autocommit on in connection settings before attempting the following tasks. Otherwise you might get an error at SOME point.

--1. Create table ‘table_to_delete’ and fill it with the following query:

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)

/*
-- Created. Statistics:
Updated Rows	10000000
Execute time	8.165s
Start time	Mon Nov 10 06:16:11 EET 2025
Finish time	Mon Nov 10 06:16:19 EET 2025
Query	CREATE TABLE table_to_delete AS
	SELECT 'veeeeeeery_long_string' || x AS col
	FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
*/



--2. Lookup how much space this table consumes with the following query:


               SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';

-- Statistics:
-- total_bytes = 602,611,712           
-- toast_bytes = 8,192
-- table_bytes = 602,603,520
-- total = 575 MB
               
               

--3. Issue the following DELETE operation on ‘table_to_delete’:

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows

/*Statistics:
Updated Rows	3333333
Execute time	5.650s
Start time	Mon Nov 10 06:42:50 EET 2025
Finish time	Mon Nov 10 06:42:55 EET 2025
Query	DELETE FROM table_to_delete
	WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows
*/

--a) Note how much time it takes to perform this DELETE statement;
-- 5.650s
--b) Lookup how much space this table consumes after previous DELETE;
-- the same as it was before deleting:
-- total_bytes = 602,611,712           
-- toast_bytes = 8,192
-- table_bytes = 602,603,520
-- total = 575 MB
--c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 
VACUUM FULL VERBOSE table_to_delete;
/*Completed. Statistics:
Updated Rows	0
Execute time	2.504s
Start time	Mon Nov 10 06:50:28 EET 2025
Finish time	Mon Nov 10 06:50:30 EET 2025
Query	VACUUM FULL VERBOSE table_to_delete
*/

--d) Check space consumption of the table once again and make conclusions;
-- total_bytes = 401,580,032           
-- toast_bytes = 8,192
-- table_bytes = 401,571,840
-- total = 383 MB
-- Space consumption reduced by 1/3 (as 1/3 rows were deleted)

--e) Recreate ‘table_to_delete’ table;
-- recreated.


--4. Issue the following TRUNCATE operation: 
TRUNCATE table_to_delete;

-- Done. Statistics:
--Updated Rows	0
--Execute time	1.080s
--Start time	Mon Nov 10 06:57:00 EET 2025
--Finish time	Mon Nov 10 06:57:01 EET 2025
--Query	TRUNCATE table_to_delete

--a) Note how much time it takes to perform this TRUNCATE statement.
-- Execute time	1.080s
--b) Compare with previous results and make conclusion.
-- It took 5.650s to DELETE 1/3 of rows and only 1.080s to TRUNCATE all of them. 
--c) Check space consumption of the table once again and make conclusions;
-- total_bytes = 8,192           
-- toast_bytes = 8,192
-- table_bytes = 0
-- total = 8,192 bytes 
               


--5. Hand over your investigation's results to your trainer. The results must include:
--a) Space consumption of ‘table_to_delete’ table before and after each operation;
-- After it was created: 602,611,712 bytes
-- After 1/3 rows DELETE operation: 602,611,712 bytes
-- After VACUUM FULL VERBOSE operation: 401,580,032 bytes (1/3 less)
-- After TRUNCATE operation: 8,192 bytes 

--b) Duration of each operation (DELETE, TRUNCATE)
-- duration of CREATE - 8.165s
-- duration of DELETE (of 1/3 rows) - 5.650s
-- duration of VACUUM FULL VERBOSE: 2.504s
-- duration of TRUNCATE (of all rows) - 1.080s

--CONCLUSION on DELETE:
-- does not release the allocated space back to the database file immediately;
-- the table size on disk doesn’t shrink;
-- The physical file size stays the same unless you manually reclaim it.

--CONCLUSION on TRUNCATE: 
-- Much faster than DELETE;
-- Frees up the data pages allocated to the table.

