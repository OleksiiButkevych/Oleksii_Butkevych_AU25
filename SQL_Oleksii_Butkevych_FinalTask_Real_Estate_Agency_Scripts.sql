/*
3. Create a physical database with a separate database and schema and give it an appropriate domain-related name
Create relationships between tables using primary and foreign keys. 
Create tables in the correct DDL order: parent tables before child tables to avoid foreign key errors
Use appropriate data types for each column and apply DEFAULT, STORED AS and GENERATED ALWAYS AS columns as required.
*/


-- 1. Create the database
CREATE DATABASE real_estate_agency_db;

-- 2. Create schema and set search path
CREATE SCHEMA IF NOT EXISTS agency;
SET search_path = agency;


-- 3. Create tables

-- 3.1 agent table
CREATE TABLE IF NOT EXISTS agency.agent (
    agent_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    phone         VARCHAR(20),
    email         VARCHAR(100) UNIQUE NOT NULL
);

-- 3.2 client table
CREATE TABLE IF NOT EXISTS agency.client (
    client_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    phone         VARCHAR(20),
    email         VARCHAR(100)  -- optional, not unique
);

-- 3.3 property table
CREATE TABLE IF NOT EXISTS agency.property (
    property_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address        VARCHAR(255) NOT NULL,
    city           VARCHAR(100) NOT NULL,
    price          NUMERIC(12,2) NOT NULL,
    property_type  VARCHAR(50) NOT NULL,
    status         VARCHAR(20) NOT NULL
);

-- 3.4 agent_property table (Many-to-Many)
CREATE TABLE IF NOT EXISTS agency.agent_property (
    agent_id     INT NOT NULL,
    property_id  INT NOT NULL,
    PRIMARY KEY (agent_id, property_id),
    FOREIGN KEY (agent_id) REFERENCES agency.agent(agent_id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES agency.property(property_id) ON DELETE CASCADE
);

-- 3.5 listing table
CREATE TABLE IF NOT EXISTS agency.listing (
    listing_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    property_id    INT NOT NULL,
    agent_id       INT NOT NULL,
    listing_date   DATE NOT NULL,
    asking_price   NUMERIC(12,2) NOT NULL,
    FOREIGN KEY (property_id) REFERENCES agency.property(property_id),
    FOREIGN KEY (agent_id) REFERENCES agency.agent(agent_id)
);

-- 3.6 viewing table
CREATE TABLE IF NOT EXISTS agency.viewing (
    viewing_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    property_id   INT NOT NULL,
    client_id     INT NOT NULL,
    viewing_date  TIMESTAMP NOT NULL,
    FOREIGN KEY (property_id) REFERENCES agency.property(property_id),
    FOREIGN KEY (client_id) REFERENCES agency.client(client_id)
);


/*
Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example 
date to be inserted, which must be greater than January 1, 2024
inserted measured value that cannot be negative
inserted value that can only be a specific value
unique
not null
Give meaningful names to your CHECK constraints. 
 */

-- adding DEFAULT value to the listing table.
ALTER TABLE agency.listing
ALTER COLUMN listing_date SET DEFAULT CURRENT_DATE;

-- Adding constraint. Date to be inserted, which must be greater than January 1, 2024
ALTER TABLE agency.listing 
DROP CONSTRAINT IF EXISTS chk_listing_date;
ALTER TABLE agency.listing
ADD CONSTRAINT chk_listing_date
CHECK (listing_date >= '2024-01-01');

-- adding constraint to the table viewing. Date to be inserted, which must be greater than January 1, 2024.
ALTER TABLE agency.viewing 
DROP CONSTRAINT IF EXISTS chk_viewing_date;
ALTER TABLE agency.viewing 
ADD CONSTRAINT chk_viewing_date
CHECK (viewing_date >= '2024-01-01':: timestamp);

-- inserted measured value that cannot be negative
ALTER TABLE agency.listing 
DROP CONSTRAINT IF EXISTS chk_asking_price_more_than_0;
ALTER TABLE agency.listing 
ADD CONSTRAINT chk_asking_price_more_than_0
CHECK (asking_price >= 0);

ALTER TABLE agency.property 
DROP CONSTRAINT IF EXISTS chk_price_more_than_0;
ALTER TABLE agency.property 
ADD CONSTRAINT chk_price_more_than_0
CHECK (price >= 0);

-- inserted value that can only be a specific value
ALTER TABLE agency.property 
DROP CONSTRAINT IF EXISTS chk_property_type;
ALTER TABLE agency.property 
ADD CONSTRAINT chk_property_type
CHECK (property_type IN ('apartment', 'house', 'land', 'condo'));

ALTER TABLE agency.property 
DROP CONSTRAINT IF EXISTS chk_property_status;
ALTER TABLE agency.property 
ADD CONSTRAINT chk_property_status
CHECK (status IN ('active', 'pending', 'rented', 'sold', 'expired', 'off_market', 'under_contract'));

--unique
ALTER TABLE agency.agent 
DROP CONSTRAINT IF EXISTS uq_email;
ALTER TABLE agency.agent 
ADD CONSTRAINT uq_email
UNIQUE(email);

ALTER TABLE agency.client 
DROP CONSTRAINT IF EXISTS uq_phone;
ALTER TABLE agency.client
ADD CONSTRAINT uq_phone
UNIQUE(phone);

ALTER TABLE agency.property
DROP CONSTRAINT IF EXISTS uq_address;
ALTER TABLE agency.property
ADD CONSTRAINT uq_address
UNIQUE(address);

-- not null.
ALTER TABLE agency.client
ALTER COLUMN phone SET NOT NULL; 


/*
4. Populate the tables with the sample data generated, ensuring each table has at least 6+ rows (for a total of 36+ rows in all 
the tables) for the last 3 months.
Create DML scripts for insert your data. 
Ensure that the DML scripts do not include values for surrogate keys, as these keys should be generated by the database during runtime. 
Avoid hardcoding values where possible
Also, ensure that any DEFAULT values required are specified appropriately in the DML scripts
These DML scripts should be designed to successfully adhere to all previously defined constraints
 */

-- inserting into agent. The script will skip any row with an email that already exists. 
INSERT INTO agency.agent(first_name, last_name, phone, email)
SELECT v.first_name, v.last_name, v.phone, v.email
FROM (
	VALUES	('Alex', 'Front', '12345', 'alex@gmail.com'),
			('Bob', 'Brown', '12346', 'bob@gmail.com'),
			('Robert', 'Lewandowski', '13245', 'robert@gmail.com'),
			('Cristiano', 'Ronaldo', '14567', 'cris@gmail.com'),
			('Leo', 'Messi', '18734', 'leo@gmail.com'),
			('Leo', 'Messia', '12234', 'leom@gmail.com'),
			('Kevin', 'McAllister', '31122', 'kevin@gmail.com')
) AS v(first_name, last_name, phone, email)
WHERE NOT EXISTS
	(SELECT 1
	FROM agency.agent AS a
	WHERE a.email = v.email)
RETURNING first_name, last_name, phone, email;


-- inserting into client
INSERT INTO agency.client(first_name, last_name, phone, email)
SELECT v.first_name, v.last_name, v.phone, v.email
FROM (
	VALUES  ('Bob', 'Garrick', '25498', 'bobgarrick@gmail.com'),
			('Steve', 'Kafka', '25345', 'steve@gmail.com'),
			('Steven', 'Seagulf', '25145', 'steven@gmail.com'),
			('Bruce', 'Willis', '65984', 'bruce@gmail.com'),
			('Michael', 'Jordan', '23199', 'mj@gmail.com'),
			('Samson', 'Godwin', '68547', 'sam@gmail.com'),
			('Mike', 'Jobs', '23199', 'mikej@gmail.com') -- not inserted because of not unique phone
) AS v(first_name, last_name, phone, email)
ON CONFLICT(phone) DO NOTHING
RETURNING client_id, first_name, last_name, phone, email;


-- inserting into property
INSERT INTO agency.property(address, city, price, property_type, status)
SELECT v.address, v.city, v.price, v.property_type, v.status
FROM (
	VALUES  ('101 Main St', 'New York', 250000, 'apartment', 'active'),
   			('202 Oak Ave', 'Los Angeles', 450000, 'house', 'pending'),
   			('303 Pine Rd', 'Chicago', 150000, 'condo', 'sold'),
    		('404 Maple Ln', 'Houston', 80000, 'land', 'off_market'),
    		('505 Cedar Blvd', 'Miami', 320000, 'house', 'under_contract'),
    		('606 Birch Dr', 'Seattle', 220000, 'apartment', 'rented'), 
    		('606 Birch Dr', 'Pert', 225000, 'apartment', 'rented') -- not inserted because of uq_address constraint violation.
) AS v(address, city, price, property_type, status)
ON CONFLICT(address) DO NOTHING
RETURNING property_id, address, city, price, property_type, status;


-- inserting into agent_property
INSERT INTO agency.agent_property(agent_id, property_id)
SELECT a.agent_id, p.property_id
FROM agency.agent a
CROSS JOIN agency.property p
WHERE NOT EXISTS (
    SELECT 1
    FROM agency.agent_property ap
    WHERE ap.agent_id = a.agent_id
      AND ap.property_id = p.property_id
)
LIMIT 10
RETURNING agent_id, property_id;


-- inserting into listing
INSERT INTO agency.listing(property_id, agent_id, listing_date, asking_price)
SELECT v.property_id, v.agent_id, v.listing_date, v.asking_price
FROM (
    VALUES
        -- (property_id, agent_id, listing_date, asking_price)
        (1, 1, '2025-11-01'::date, 262500.00),  -- 250000 * 1.05
        (2, 2, '2025-11-08'::date, 472500.00),  -- 450000 * 1.05
        (3, 3, '2025-11-15'::date, 157500.00),  -- 150000 * 1.05
        (4, 4, '2025-11-22'::date, 84000.00),   -- 80000 * 1.05
        (5, 5, '2025-11-29'::date, 336000.00),  -- 320000 * 1.05
        (6, 6, '2025-12-06'::date, 231000.00)   -- 220000 * 1.05
) AS v(property_id, agent_id, listing_date, asking_price)
WHERE NOT EXISTS (
    SELECT 1 
    FROM agency.listing l
    WHERE l.property_id = v.property_id
      AND l.agent_id = v.agent_id
)
RETURNING listing_id, property_id, agent_id, listing_date, asking_price;


-- inserting into viewing
INSERT INTO agency.viewing(property_id, client_id, viewing_date)
SELECT v.property_id, v.client_id, v.viewing_date
FROM (
    VALUES
        -- (property_id, client_id, viewing_date)
        (1, 1, '2025-11-10 10:00:00'::timestamp),
        (2, 2, '2025-11-12 14:00:00'::timestamp),
        (3, 3, '2025-11-15 09:30:00'::timestamp),
        (4, 4, '2025-11-18 16:00:00'::timestamp),
        (5, 5, '2025-11-20 11:15:00'::timestamp),
        (6, 6, '2025-11-22 13:45:00'::timestamp),
        (1, 2, '2025-11-25 15:00:00'::timestamp),
        (2, 3, '2025-11-27 10:30:00'::timestamp),
        (3, 4, '2025-11-29 12:00:00'::timestamp),
        (4, 5, '2025-12-01 09:00:00'::timestamp),
        (5, 6, '2025-12-03 14:30:00'::timestamp),
        (6, 1, '2025-12-04 11:45:00'::timestamp)
) AS v(property_id, client_id, viewing_date)
WHERE NOT EXISTS (
    SELECT 1
    FROM agency.viewing vw
    WHERE vw.property_id = v.property_id
      AND vw.client_id = v.client_id
)
RETURNING viewing_id, property_id, client_id, viewing_date;


/*
5. Create the following functions.
5.1 Create a function that updates data in one of your tables. This function should take the following input arguments:
The primary key value of the row you want to update
The name of the column you want to update
The new value you want to set for the specified column

This function should be designed to modify the specified row in the table, updating the specified column with the new value.
*/

CREATE OR REPLACE FUNCTION agency.update_client_column(
    p_client_id INT,
    p_column_name TEXT,
    p_new_value TEXT
)
RETURNS TEXT AS
$$
BEGIN
    IF p_column_name NOT IN ('first_name', 'last_name', 'phone', 'email') THEN
        RAISE EXCEPTION 'Column "%" cannot be updated', p_column_name;
    END IF;

    EXECUTE format(
        'UPDATE agency.client SET %I = $1 WHERE client_id = $2',
        p_column_name
    )
    USING p_new_value, p_client_id;

    RETURN 'Update successful';
END;
$$
LANGUAGE plpgsql;

SELECT agency.update_client_column(1, 'first_name', 'Sherlock');
SELECT agency.update_client_column(1, 'last_name', 'Holmes');
SELECT agency.update_client_column(1, 'phone', '77777');
SELECT agency.update_client_column(1, 'email', 'sherlock@gmail.com');
SELECT * FROM client;


/*
5. 2 Create a function that adds a new transaction to your transaction table. 
You can define the input arguments and output format. 
Make sure all transaction attributes can be set with the function (via their natural keys). 
The function does not need to return a value but should confirm the successful insertion of the new transaction.
*/

-- Function will be created to add rows to the listing table. 
CREATE OR REPLACE FUNCTION agency.add_new_listing(
    p_property_address   VARCHAR,
    p_city               VARCHAR,
    p_price              NUMERIC,
    p_property_type      VARCHAR,
    p_property_status    VARCHAR,
    p_agent_firstname    VARCHAR,
    p_agent_lastname     VARCHAR,
    p_agent_email        VARCHAR,
    p_listing_date       DATE,
    p_asking_price       NUMERIC
)
RETURNS TEXT AS
$$
DECLARE
    v_property_id INT;
    v_agent_id    INT;
    v_message     TEXT;
BEGIN
    -- 1. Property check: unique by address + city + price
    SELECT property_id INTO v_property_id
    FROM agency.property
    WHERE address = p_property_address
      AND city = p_city
      AND price = p_price;

    IF v_property_id IS NULL THEN
        INSERT INTO agency.property (address, city, price, property_type, status)
        VALUES (p_property_address, p_city, p_price, p_property_type, p_property_status)
        RETURNING property_id INTO v_property_id;
    END IF;

    -- 2. Agent check: unique by email
    SELECT agent_id INTO v_agent_id
    FROM agency.agent
    WHERE email = p_agent_email;

    IF v_agent_id IS NULL THEN
        INSERT INTO agency.agent (first_name, last_name, email)
        VALUES (p_agent_firstname, p_agent_lastname, p_agent_email)
        RETURNING agent_id INTO v_agent_id;
    END IF;

    -- 3. Check for existing listing: property + agent + listing_date
    IF EXISTS (
        SELECT 1
        FROM agency.listing
        WHERE property_id = v_property_id
          AND agent_id = v_agent_id
          AND listing_date = p_listing_date
    ) THEN
        RETURN 'Listing already exists for this property, agent, and date.';
    END IF;

    -- 4. Insert listing
    INSERT INTO agency.listing (property_id, agent_id, listing_date, asking_price)
    VALUES (v_property_id, v_agent_id, p_listing_date, p_asking_price);

    -- 5. Confirmation message
    v_message := 'Listing successfully inserted for property "' 
                 || p_property_address || '" with agent "' 
                 || p_agent_email || '" on ' 
                 || p_listing_date || ' at price ' 
                 || p_asking_price;

    RETURN v_message;
END;
$$ LANGUAGE plpgsql;



SELECT agency.add_new_listing(
    '14 Main Street, Springfield',     -- property address
    'New York',                        -- city
    350000,                            -- base price
    'house',                           -- type
    'active',                          -- status
    'John',                            -- agent first name
    'Doehh',                           -- agent last name
    'john.doe@agency.com',             -- agent email
    '2025-04-20',                      -- listing date
    356000                             -- asking price
);


SELECT * FROM agency.listing;



/*
6. Create a view that presents analytics for the most recently added quarter in your database. 
Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries.
 */
CREATE OR REPLACE VIEW agency.v_latest_quarter_analytics AS
WITH latest_quarter AS (
    SELECT 
        EXTRACT(YEAR FROM listing_date) AS year,
        EXTRACT(QUARTER FROM listing_date) AS quarter
    FROM agency.listing
    ORDER BY listing_date DESC
    LIMIT 1
)
SELECT 
    p.address AS property_address,
    p.city,
    p.property_type,
    p.status AS property_status,
    a.first_name || ' ' || a.last_name AS agent_name,
    l.listing_date,
    l.asking_price
FROM agency.listing l
JOIN latest_quarter q
    ON EXTRACT(YEAR FROM l.listing_date) = q.year
   AND EXTRACT(QUARTER FROM l.listing_date) = q.quarter
JOIN agency.property p 
    ON l.property_id = p.property_id
JOIN agency.agent a 
    ON l.agent_id = a.agent_id
ORDER BY l.listing_date DESC;


SELECT *
FROM agency.v_latest_quarter_analytics;



/*
7. Create a read-only role for the manager. This role should have permission to perform SELECT queries on the database tables, 
and also be able to log in. Please ensure that you adhere to best practices for database security when defining this role.
*/
-- Create a secure read-only role for a manager. This role can log in and perform SELECT queries only.
-- Create a secure read-only manager role if it does not already exist. This makes the code rerunnable without errors
DO
$$
BEGIN
    -- Check if role already exists
    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'manager_ro'
    ) THEN
        -- Create role
        CREATE ROLE manager_ro
        LOGIN                                 -- allows role to log in
        PASSWORD 'Epam_final_task_DAE_2025'  -- password
        NOSUPERUSER                            -- no admin privileges
        NOCREATEDB                             -- cannot create new databases
        NOCREATEROLE                           -- cannot create other roles
        NOINHERIT;                             -- does not inherit privileges from other roles
    END IF;
END
$$;

-- Grant schema usage
-- This allows the role to access objects within the schema
GRANT USAGE ON SCHEMA agency TO manager_ro;

-- Grant SELECT privileges on all existing tables in the schema. Ensures the manager can query all current tables
GRANT SELECT ON ALL TABLES IN SCHEMA agency TO manager_ro;

-- Ensure future tables are automatically readable. Any new table created in the agency schema will allow SELECT
ALTER DEFAULT PRIVILEGES IN SCHEMA agency
GRANT SELECT ON TABLES TO manager_ro;