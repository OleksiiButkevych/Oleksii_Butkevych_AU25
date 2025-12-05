--Task 2. Implement role-based authentication model for dvd_rental database
--Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect 
--to the database but no other permissions.

-- Create the user
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';

-- Allow the user to connect to the database
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

-- Revoke all other privileges (just to be sure)
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM rentaluser;


--Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a 
--SQL query to select all customers.
-- Grant SELECT privilege
GRANT SELECT ON TABLE customer TO rentaluser;

SELECT * FROM customer c;



--Create a new user group called "rental" and add "rentaluser" to the group. 
-- Create a new role (group)
CREATE ROLE rental;

-- Add rentaluser to the group
GRANT rental TO rentaluser;


--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row 
--in the "rental" table under that role. 
-- Grant INSERT and UPDATE
GRANT INSERT, UPDATE ON TABLE rental TO rental;

-- Insert a new row (adjust values based on your table structure)
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
SELECT CURRENT_TIMESTAMP, 1, 1, 1;

-- Update an existing row
UPDATE rental 
SET return_date = CURRENT_TIMESTAMP 
WHERE rental_id = 1001;


--Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make 
--sure this action is denied.
REVOKE INSERT ON TABLE rental FROM rental;

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
SELECT CURRENT_TIMESTAMP, 1, 1, 1;


--Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be 
--client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty. 
--Get customer_id 
SELECT customer_id FROM customer WHERE first_name='MARY' AND last_name='SMITH';

-- Create a role for her
CREATE ROLE client_MARY_SMITH;
-- Optionally grant her access to only her own data
-- Example: SELECT her own customer record
GRANT SELECT ON customer TO client_MARY_SMITH;

/*
 Task 3. Implement row-level security
Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
Write a query to make sure this user sees only their own data.
 */

-- Enable RLS on rental table
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;

-- Enable RLS on payment table
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- Rental table: allow access only to the customer's own rows
CREATE POLICY customer_rental_policy
ON rental
FOR ALL
USING (customer_id = current_setting('app.current_customer_id')::int);

-- Payment table: allow access only to the customer's own rows
CREATE POLICY customer_payment_policy
ON payment
FOR ALL
USING (customer_id = current_setting('app.current_customer_id')::int);

-- Set the current customer ID for Mary Smith
SET app.current_customer_id = 1;

-- As client_MARY_SMITH, select rentals
SELECT * FROM rental;

-- As client_MARY_SMITH, select payments
SELECT * FROM payment;

GRANT SELECT ON rental TO client_MARY_SMITH;
GRANT SELECT ON payment TO client_MARY_SMITH;

