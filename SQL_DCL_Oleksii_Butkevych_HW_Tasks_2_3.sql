--Task 2. Implement role-based authentication model for dvd_rental database
--Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect 
--to the database but no other permissions.

-- Create the user
DO $$
BEGIN
    -- Drop the role only if it exists and safely revoke all privileges
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rentaluser') THEN
        
        -- Revoke privileges so DROP ROLE does not fail
        EXECUTE 'REVOKE ALL PRIVILEGES ON DATABASE dvdrental FROM rentaluser';
        EXECUTE 'REVOKE CONNECT ON DATABASE dvdrental FROM rentaluser';
        EXECUTE 'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM rentaluser';
        EXECUTE 'REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM rentaluser';
        EXECUTE 'REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM rentaluser';

        -- Remove from group roles
        EXECUTE 'REVOKE rental FROM rentaluser';

        -- Drop the role
        EXECUTE 'DROP ROLE rentaluser';
    END IF;

    -- Create role if missing
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rentaluser') THEN
        EXECUTE 'CREATE ROLE rentaluser LOGIN PASSWORD ''rentalpassword''';
    END IF;

END$$;



-- Allow the user to connect to the database
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

-- Revoke all other privileges (just to be sure)
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM rentaluser;


--Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a 
--SQL query to select all customers.
-- Grant SELECT privilege
GRANT SELECT ON TABLE public.customer TO rentaluser;

SELECT * FROM public.customer c;



--Create a new user group called "rental" and add "rentaluser" to the group. 
-- Create group role "rental"
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rental') THEN
        CREATE ROLE rental NOLOGIN;
    END IF;
END$$;

-- Add rentaluser to the group
GRANT rental TO rentaluser;


--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row 
--in the "rental" table under that role. 
-- Grant INSERT and UPDATE
GRANT INSERT, UPDATE ON TABLE public.rental TO rental;

-- Insert a new row (adjust values based on your table structure)
INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT CURRENT_TIMESTAMP, 1, 1, 1
WHERE NOT EXISTS (
    SELECT 1 FROM public.rental
    WHERE inventory_id = 1 AND customer_id = 1 AND staff_id = 1
);


-- Update an existing row
UPDATE public.rental 
SET return_date = CURRENT_TIMESTAMP 
WHERE rental_id = 1001;


--Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make 
--sure this action is denied.
REVOKE INSERT ON TABLE public.rental FROM rental;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT CURRENT_TIMESTAMP, 1, 1, 1
WHERE NOT EXISTS (
    SELECT 1 FROM public.rental
    WHERE inventory_id = 1 AND customer_id = 1 AND staff_id = 1
);


--Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be 
--client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty. 
--Get customer_id 
SELECT customer_id FROM public.customer WHERE first_name='MARY' AND last_name='SMITH';

-- Create a role for her
DO $$
BEGIN
    -- Check using lowercase (or quote the name)
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_roles 
        WHERE rolname = 'client_mary_smith'
    ) THEN
        EXECUTE 'CREATE ROLE "client_MARY_SMITH" NOLOGIN';
    END IF;
END$$;


-- Optionally grant her access to only her own data
-- Example: SELECT her own customer record
GRANT SELECT ON public.customer TO client_MARY_SMITH;

/*
 Task 3. Implement row-level security
Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
Write a query to make sure this user sees only their own data.
 */

-- Enable RLS on rental table
ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;

-- Enable RLS on payment table
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;

-- Rental table: allow access only to the customer's own rows
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'rental'
          AND policyname = 'customer_rental_policy'
    ) THEN
        EXECUTE '
            CREATE POLICY customer_rental_policy
            ON public.rental
            FOR ALL
            USING (customer_id = current_setting(''app.current_customer_id'')::int)
        ';
    END IF;
END$$;


-- Payment table: allow access only to the customer's own rows
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'payment'
          AND policyname = 'customer_payment_policy'
    ) THEN
        EXECUTE '
            CREATE POLICY customer_payment_policy
            ON public.payment
            FOR ALL
            USING (customer_id = current_setting(''app.current_customer_id'')::int)
        ';
    END IF;
END$$;


-- Set the current customer ID for Mary Smith
SET app.current_customer_id = 1;

-- As client_MARY_SMITH, select rentals
SELECT * FROM public.rental;

-- As client_MARY_SMITH, select payments
SELECT * FROM public.payment;

GRANT SELECT ON public.rental TO client_MARY_SMITH;
GRANT SELECT ON public.payment TO client_MARY_SMITH;