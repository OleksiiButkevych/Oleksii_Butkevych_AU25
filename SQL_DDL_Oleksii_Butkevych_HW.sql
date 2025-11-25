-- Creating a physical DB based on the logical model presented earlier.
/*
1. Create a physical database with a separate database and schema and give it an appropriate domain-related name. 
Use the relational model you've created while studying DB Basics module. Task 2 (designing a logical data model 
on the chosen topic). Make sure you have made any changes to your model after your mentor's comments. 
2. Ensure your physical database is in 3NF. Do not add extra columns, tables, or relations not specified in the logical model.
3. Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
4. Create relationships between tables using primary and foreign keys. 
5. Create tables in the correct DDL order: parent tables before child tables to avoid foreign key errors
*/
 



-- Create the database 
CREATE DATABASE  metro_db;

-- Schema
CREATE SCHEMA IF NOT EXISTS metro;
SET search_path = metro;

-- 1. Lines
CREATE TABLE IF NOT EXISTS metro.line (
    line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    color_hex VARCHAR(7)
);

-- 2. Stations
CREATE TABLE IF NOT EXISTS metro.station (
    station_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    district VARCHAR(100)
);

-- 3. Station-Line (many-to-many)
CREATE TABLE IF NOT EXISTS metro.station_line (
    station_id BIGINT NOT NULL,
    line_id BIGINT NOT NULL,
    sequence_no INTEGER NOT NULL,
    PRIMARY KEY (station_id, line_id), -- composite key
    CONSTRAINT fk_sl_station FOREIGN KEY (station_id) REFERENCES station(station_id),
    CONSTRAINT fk_sl_line FOREIGN KEY (line_id) REFERENCES line(line_id)
);

-- 4. Trains
CREATE TABLE IF NOT EXISTS metro.train (
    train_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fleet_number VARCHAR(50) NOT NULL UNIQUE,
    capacity INTEGER CHECK (capacity >= 0)
);

-- 5. Crew
CREATE TABLE IF NOT EXISTS metro.crew (
    crew_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    role VARCHAR(50) NOT NULL
);

-- 6. Train-Crew assignment (many-to-many)
CREATE TABLE IF NOT EXISTS metro.train_crew_assignment (
    assignment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    train_id BIGINT NOT NULL,
    crew_id BIGINT NOT NULL,
    start_ts TIMESTAMP NOT NULL,
    end_ts TIMESTAMP,
    CONSTRAINT fk_tca_train FOREIGN KEY (train_id) REFERENCES train(train_id),
    CONSTRAINT fk_tca_crew FOREIGN KEY (crew_id) REFERENCES crew(crew_id)
);

-- 7. Schedule
CREATE TABLE IF NOT EXISTS metro.schedule (
    schedule_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    train_id BIGINT NOT NULL,
    line_id BIGINT NOT NULL,
    service_date DATE NOT NULL,
    scheduled_start TIMESTAMP NOT NULL,
    scheduled_end TIMESTAMP NOT NULL,
    CONSTRAINT fk_schedule_train FOREIGN KEY (train_id) REFERENCES train(train_id),
    CONSTRAINT fk_schedule_line FOREIGN KEY (line_id) REFERENCES line(line_id)
);

-- 8. Schedule station (composite key)
CREATE TABLE IF NOT EXISTS metro.schedule_station (
    schedule_id BIGINT NOT NULL,
    station_id BIGINT NOT NULL,
    arrival_ts TIMESTAMP,
    departure_ts TIMESTAMP,
    PRIMARY KEY (schedule_id, station_id),
    CONSTRAINT fk_ss_schedule FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id),
    CONSTRAINT fk_ss_station FOREIGN KEY (station_id) REFERENCES station(station_id)
);

-- 9. Passengers
CREATE TABLE IF NOT EXISTS metro.passenger (
    passenger_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(200),
    email VARCHAR(200)
);

-- 10. Tickets (connected to passenger, schedule, and optionally start/end station)
CREATE TABLE IF NOT EXISTS metro.ticket (
    ticket_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    passenger_id BIGINT NOT NULL,
    schedule_id BIGINT NOT NULL,
    start_station_id BIGINT NOT NULL,
    end_station_id BIGINT NOT NULL,
    purchase_ts TIMESTAMP NOT NULL DEFAULT now(),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    CONSTRAINT fk_ticket_passenger FOREIGN KEY (passenger_id) REFERENCES passenger(passenger_id),
    CONSTRAINT fk_ticket_schedule FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id),
	CONSTRAINT fk_ticket_start_station FOREIGN KEY (start_station_id) REFERENCES station(station_id),
    CONSTRAINT fk_ticket_end_station FOREIGN KEY (end_station_id) REFERENCES station(station_id)
);




-- additional tasks. 
--6. Apply five check constraints across the tables to restrict certain values, including
--date to be inserted, which must be greater than January 1, 2000
ALTER TABLE metro.train_crew_assignment
DROP CONSTRAINT IF EXISTS chk_start_ts_after_2000;
ALTER TABLE metro.train_crew_assignment
ADD CONSTRAINT chk_start_ts_after_2000
CHECK (start_ts > TIMESTAMP '2000-01-01');


ALTER TABLE metro.train_crew_assignment
DROP CONSTRAINT IF EXISTS chk_end_ts_after_2000;
ALTER TABLE metro.train_crew_assignment
ADD CONSTRAINT chk_end_ts_after_2000
CHECK (end_ts IS NULL OR end_ts > TIMESTAMP '2000-01-01');


ALTER TABLE metro.schedule
DROP CONSTRAINT IF EXISTS chk_scheduled_start_after_2000;
ALTER TABLE metro.schedule
ADD CONSTRAINT chk_scheduled_start_after_2000
CHECK (scheduled_start > TIMESTAMP '2000-01-01');


ALTER TABLE metro.schedule
DROP CONSTRAINT IF EXISTS chk_scheduled_end_after_2000;
ALTER TABLE metro.schedule
ADD CONSTRAINT chk_scheduled_end_after_2000
CHECK (scheduled_end > TIMESTAMP '2000-01-01');


ALTER TABLE metro.schedule
DROP CONSTRAINT IF EXISTS chk_service_date;
ALTER TABLE metro.schedule
ADD CONSTRAINT chk_service_date
CHECK (service_date > DATE '2000-01-01');


ALTER TABLE metro.schedule_station
DROP CONSTRAINT IF EXISTS chk_arrival_ts_after_2000;
ALTER TABLE metro.schedule_station
ADD CONSTRAINT chk_arrival_ts_after_2000
CHECK (arrival_ts IS NULL OR arrival_ts > TIMESTAMP '2000-01-01');


ALTER TABLE metro.schedule_station
DROP CONSTRAINT IF EXISTS chk_departure_ts_after_2000;
ALTER TABLE metro.schedule_station
ADD CONSTRAINT chk_departure_ts_after_2000
CHECK (departure_ts IS NULL OR departure_ts > TIMESTAMP '2000-01-01');


ALTER TABLE metro.ticket
DROP CONSTRAINT IF EXISTS chk_purchase_ts_after_2000;
ALTER TABLE metro.ticket
ADD CONSTRAINT chk_purchase_ts_after_2000
CHECK (purchase_ts > TIMESTAMP '2000-01-01');




--inserted measured value that cannot be negative
ALTER TABLE metro.station_line 
DROP CONSTRAINT IF EXISTS chk_sequence_no_not_negative;
ALTER TABLE metro.station_line 
ADD CONSTRAINT chk_sequence_no_not_negative
CHECK (sequence_no >= 0);




--inserted value that can only be a specific value (as an example of gender)
-- Many constraints can be added to the table. Example: 
ALTER TABLE metro.ticket
DROP CONSTRAINT IF EXISTS chk_ticket_status_valid;
ALTER TABLE metro.ticket
ADD CONSTRAINT chk_ticket_status_valid
CHECK (status IN ('active', 'cancelled', 'used', 'expired'));


ALTER TABLE metro.schedule
DROP CONSTRAINT IF EXISTS chk_scheduled_end_after_start;
ALTER TABLE metro.schedule
ADD CONSTRAINT chk_scheduled_end_after_start
CHECK (scheduled_end > scheduled_start);


ALTER TABLE metro.crew
DROP CONSTRAINT IF EXISTS chk_crew_role;
ALTER TABLE metro.crew
ADD CONSTRAINT chk_crew_role
CHECK (role IN ('Driver', 'Conductor', 'Supervisor', 'Technician', 'Security'));


ALTER TABLE metro.station
DROP CONSTRAINT IF EXISTS chk_station_district;
ALTER TABLE metro.station
ADD CONSTRAINT chk_station_district
CHECK (district IN ('Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island')); -- 5 districts of New York as example. 




--unique. For example: 
ALTER TABLE metro.line
DROP CONSTRAINT IF EXISTS uq_line_name;
ALTER TABLE metro.line
ADD CONSTRAINT uq_line_name
UNIQUE (name);


ALTER TABLE metro.line 
DROP CONSTRAINT IF EXISTS uq_line_color_hex;
ALTER TABLE metro.line 
ADD CONSTRAINT uq_line_color_hex 
UNIQUE (color_hex);


ALTER TABLE metro.passenger 
DROP CONSTRAINT IF EXISTS uq_email;
ALTER TABLE metro.passenger 
ADD CONSTRAINT uq_email
UNIQUE (email);




--not null. For example:
ALTER TABLE metro.passenger
ALTER COLUMN full_name SET NOT NULL;

ALTER TABLE metro.train 
ALTER COLUMN capacity SET NOT NULL;


-- 7. After creating tables and adding all constraints, populate the tables with sample data generated, 
--ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
-- Use INSERT statements with ON CONFLICT DO NOTHING or WHERE NOT EXISTS to avoid duplicates. 
-- Avoid hardcoding values where possible

-- 1. line -- I  added more rows to be inserted. And only first two will be inserted. Other violate Unique constraint and not inserted.  
INSERT INTO metro.line (code, name, color_hex)
VALUES 
    ('L1','Blue line','#0000FF'),
    ('L2','Green line','#0000F0'),
    ('L1','Red line','#0001F0'),
    ('L3','Green line','#0000F0'),
    ('L4','White line','#0000F0')
ON CONFLICT DO NOTHING
RETURNING line_id, code, name, color_hex;

--2. station 
INSERT INTO metro.station(name, district)
SELECT v.name, v.district
FROM (
	VALUES  ('Central Station', 'Brooklyn'),
			('Riverside', 'Bronx')
) AS v(name, district)
WHERE NOT EXISTS (
	SELECT 1
	FROM metro.station s
	WHERE s.name=v.name
)
RETURNING station_id, name, district;


-- 3. train
INSERT INTO metro.train (fleet_number, capacity)
SELECT t.fleet_number, t.capacity
FROM (
	VALUES 	('FLEET-1001', 50),
			('FLEET-1002', 55), 
			('FLEET-1002', 60) -- not inserted because of UNIQUE (fleet_number) constraint
) AS t(fleet_number, capacity)
ON CONFLICT(fleet_number) DO NOTHING 
RETURNING train_id, fleet_number, capacity;

-- 4. crew. This code can produce duplicates, but this must be ok, as different people can have same names and jobs. 
-- So crew members will be uniquely identified using crew_id. 
-- ON CONFLICT DO NOTHING removed from the code as every time we insert a roq with different id and there is no conflict. 
INSERT INTO metro.crew(full_name, role)
SELECT c.full_name, c."role" 
FROM (
	VALUES 	('John Smith', 'Driver'),
			('Rio Ferdinand', 'Conductor')
) AS c(full_name, role)
RETURNING crew_id, full_name, role;

-- 5. passenger. People can have different names. Code creates dublicates only on full_name. It it is run more than once only and row with
-- NULL in email is inserted several times. Row with the same email violates the Unique constraint and cannot be inserted.  
INSERT INTO metro.passenger(full_name, email)
SELECT p.full_name, p.email
FROM (
	VALUES  ('Alex Morea', 'alex@gmail.com'),
			('Boris Priest', NULL),
			('Alex Priest', 'alex@gmail.com') -- not inserted because of conflict (UNIQUE constraint violation). 
) AS p(full_name, email)
ON CONFLICT(email) DO NOTHING 
RETURNING passenger_id, full_name, email;


-- 6. station_line. 
INSERT INTO metro.station_line (station_id, line_id, sequence_no)
SELECT s.station_id, l.line_id, v.sequence_no
FROM (
    VALUES
        ('Central Station', 'L1', 1),
        ('Riverside', 'L2', 1)
) AS v(station_name, line_code, sequence_no)
JOIN metro.station s ON s.name = v.station_name
JOIN metro.line l ON l.code = v.line_code
WHERE NOT EXISTS (
    SELECT 1
    FROM metro.station_line sl
    WHERE sl.station_id = s.station_id
      AND sl.line_id = l.line_id
)
RETURNING station_id, line_id, sequence_no;

-- 7. train_crew assignment
INSERT INTO metro.train_crew_assignment (train_id, crew_id, start_ts, end_ts)
SELECT t.train_id, c.crew_id, v.start_ts, v.end_ts
FROM (
    VALUES
        ('FLEET-1001', 'John Smith', '2025-11-15 06:00:00'::timestamp, '2025-11-15 14:00:00'::timestamp),
        ('FLEET-1002', 'Rio Ferdinand', '2025-11-15 08:00:00'::timestamp, '2025-11-15 16:00:00'::timestamp)
) AS v(fleet_number, crew_name, start_ts, end_ts)
JOIN metro.train t ON t.fleet_number = v.fleet_number
JOIN metro.crew c ON c.full_name = v.crew_name
WHERE NOT EXISTS (
    SELECT 1
    FROM metro.train_crew_assignment a
    WHERE a.train_id = t.train_id
      AND a.crew_id = c.crew_id
      AND a.start_ts = v.start_ts
      AND a.end_ts = v.end_ts
)
RETURNING assignment_id, train_id, crew_id, start_ts, end_ts;

-- 8. schedule
INSERT INTO metro.schedule (train_id, line_id, service_date, scheduled_start, scheduled_end)
SELECT t.train_id, l.line_id, v.service_date, v.scheduled_start, v.scheduled_end
FROM (
    VALUES
        ('FLEET-1001', 'L1', '2025-11-15'::date, '2025-11-15 06:00:00'::timestamp, '2025-11-15 08:00:00'::timestamp),
        ('FLEET-1002', 'L2', '2025-11-15'::date, '2025-11-15 09:00:00'::timestamp, '2025-11-15 11:00:00'::timestamp)
) AS v(fleet_number, line_code, service_date, scheduled_start, scheduled_end)
JOIN metro.train t ON t.fleet_number = v.fleet_number
JOIN metro.line  l ON l.code = v.line_code
WHERE NOT EXISTS (
    SELECT 1
    FROM metro.schedule s
    WHERE s.train_id        = t.train_id
      AND s.line_id         = l.line_id
      AND s.service_date    = v.service_date
      AND s.scheduled_start = v.scheduled_start
      AND s.scheduled_end   = v.scheduled_end
)
RETURNING schedule_id, train_id, line_id, service_date, scheduled_start, scheduled_end;




-- 9. schedule_station
INSERT INTO metro.schedule_station (schedule_id, station_id, arrival_ts, departure_ts)
SELECT *
FROM (
    VALUES
        (1, 1, '2025-11-15 06:05:00'::timestamp, '2025-11-15 06:10:00'::timestamp),
        (2, 2, '2025-11-15 09:05:00'::timestamp, '2025-11-15 09:10:00'::timestamp)
) AS v(schedule_id, station_id, arrival_ts, departure_ts)
WHERE NOT EXISTS (
    SELECT 1
    FROM metro.schedule_station ss
    WHERE ss.schedule_id = v.schedule_id
      AND ss.station_id = v.station_id
      AND ss.arrival_ts = v.arrival_ts
      AND ss.departure_ts = v.departure_ts
)
RETURNING schedule_id, station_id, arrival_ts, departure_ts;




-- 10. ticket
INSERT INTO metro.ticket (passenger_id, schedule_id, start_station_id, end_station_id, purchase_ts, status)
SELECT *
FROM (
    VALUES
        (1, 1, 1, 1, '2025-11-14 10:00:00'::timestamp, 'active'),
        (2, 2, 2, 2, '2025-11-14 11:00:00'::timestamp, 'active')
) AS v(passenger_id, schedule_id, start_station_id, end_station_id, purchase_ts, status)
WHERE NOT EXISTS (
    SELECT 1
    FROM metro.ticket t
    WHERE t.passenger_id = v.passenger_id
      AND t.schedule_id = v.schedule_id
      AND t.start_station_id = v.start_station_id
      AND t.end_station_id = v.end_station_id
      AND t.purchase_ts = v.purchase_ts
)
RETURNING ticket_id, passenger_id, schedule_id, start_station_id, end_station_id, purchase_ts, status;


--8. Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, 
--and check to make sure the value has been set for the existing rows.

--Add the column with default first – avoids errors for new inserts
ALTER TABLE metro.line
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.station
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.station_line
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.train
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.crew
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.train_crew_assignment
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.schedule
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.schedule_station
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.passenger
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE metro.ticket
ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

-- check to make sure the value has been set for the existing row
SELECT * FROM metro.line;
SELECT * FROM metro.station;
SELECT * FROM metro.station_line;
SELECT * FROM metro.train;
SELECT * FROM metro.crew;
SELECT * FROM metro.train_crew_assignment;
SELECT * FROM metro.schedule;
SELECT * FROM metro.schedule_station;
SELECT * FROM metro.passenger;
SELECT * FROM metro.ticket;