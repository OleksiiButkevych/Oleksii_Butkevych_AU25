--Choose your real top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - 
--will not be taken into account and grade will be reduced by 20%). 
-- Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.

BEGIN;

INSERT INTO public.film (
    title,
    description,
    release_year,
    language_id,
    original_language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    last_update,
    special_features,
    fulltext
)
SELECT
    v.title,
    v.description,
    v.release_year,     
    1 AS language_id,                -- 1 is English. Can be done using subquery.   
    NULL AS original_language_id,    -- English is original language
    v.rental_duration,
    v.rental_rate,
    v.length,
    v.replacement_cost,
    v.rating::mpaa_rating,           -- cast to mpaa_rating
    current_date AS last_update,     -- set last_update to current_date
    v.special_features,
    to_tsvector(v.title || ' ' || coalesce(v.description, '')) AS fulltext
FROM (
    VALUES
        (
            'HOME ALONE',
            'A young boy defends his home from burglars during Christmas.',
            1990,
            1,
            4.99,
            103,
            19.99,
            'PG',
            ARRAY['Trailers', 'Deleted Scenes']
        ),
        (
            'THE SHAWSHANK REDEMPTION',
            'Two imprisoned men bond over years, finding solace and eventual redemption.',
            1994,
            2,
            9.99,
            142,
            24.99,
            'R',
            ARRAY['Trailers']
        ),
        (
            'FORREST GUMP',
            'The life story of Forrest Gump, a kind-hearted man who witnesses and influences several historical events.',
            1994,
            3,
            19.99,
            142,
            21.99,
            'PG-13',
            ARRAY['Trailers', 'Commentaries']
        )
) AS v(title, description, release_year, rental_duration, rental_rate, length, replacement_cost, rating, special_features)
WHERE NOT EXISTS (
    SELECT 1 FROM public.film f WHERE f.title = v.title
)
RETURNING film_id, title, rating, last_update;    -- RETURNING clause helps verify which rows were actually inserted

COMMIT;






--Add the real actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total). 
--Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced by 20%.

BEGIN;

-- Step 1: Insert actors if they don't exist
INSERT INTO public.actor (first_name, last_name, last_update)
SELECT v.first_name, v.last_name, CURRENT_TIMESTAMP
FROM (VALUES
    ('MACAULAY', 'CULKIN'),    -- HOME ALONE
    ('JOE', 'PESCI'),          -- HOME ALONE
    ('TIM', 'ROBBINS'),        -- SHAWSHANK REDEMPTION
    ('MORGAN', 'FREEMAN'),     -- SHAWSHANK REDEMPTION
    ('TOM', 'HANKS'),          -- FORREST GUMP
    ('ROBIN', 'WRIGHT')        -- FORREST GUMP
) AS v(first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 FROM public.actor a
    WHERE a.first_name = v.first_name AND a.last_name = v.last_name
)
RETURNING actor_id, first_name, last_name;

-- Step 2: Link actors to films in film_actor table (film titles in ALL CAPS)
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id::int2,  -- cast to smallint (int2)
    f.film_id::int2,   -- cast to smallint (int2)
    CURRENT_TIMESTAMP
FROM public.actor a
JOIN public.film f ON f.title = CASE
    WHEN (a.first_name, a.last_name) = ('MACAULAY', 'CULKIN') THEN 'HOME ALONE'
    WHEN (a.first_name, a.last_name) = ('JOE', 'PESCI') THEN 'HOME ALONE'
    WHEN (a.first_name, a.last_name) = ('TIM', 'ROBBINS') THEN 'THE SHAWSHANK REDEMPTION'
    WHEN (a.first_name, a.last_name) = ('MORGAN', 'FREEMAN') THEN 'THE SHAWSHANK REDEMPTION'
    WHEN (a.first_name, a.last_name) = ('TOM', 'HANKS') THEN 'FORREST GUMP'
    WHEN (a.first_name, a.last_name) = ('ROBIN', 'WRIGHT') THEN 'FORREST GUMP'
END
WHERE NOT EXISTS (
    SELECT 1 FROM public.film_actor fa
    WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
RETURNING actor_id, film_id;

COMMIT;





--Add your favorite movies to any store's inventory.

-- Insert movies into inventory
-- We use SELECT from the film table to get the corresponding film_id for each movie
-- This ensures we are linking to existing films rather than hardcoding IDs

BEGIN;

INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id,
       CASE 
           WHEN f.title IN ('HOME ALONE', 'FORREST GUMP') THEN 1 
           ELSE 2 
       END AS store_id,  -- assign store 1 or 2
       CURRENT_TIMESTAMP AS last_update
FROM public.film f
WHERE f.title IN ('HOME ALONE', 'THE SHAWSHANK REDEMPTION', 'FORREST GUMP')
RETURNING inventory_id, film_id, store_id, last_update;

COMMIT;





--Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours 
--(first name, last name, address, etc.). You can use any existing address from the "address" table. 
--Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.

-- Selecting customers with more than 43 rental and 43 payment records.
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS Quantity_of_rentals, COUNT(p.payment_id) AS Quantity_of_payments
FROM public.customer c
JOIN public.rental r ON r.customer_id = c.customer_id 
JOIN public.payment p ON p.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING 	COUNT(r.rental_id) >= 43 AND
		COUNT(p.payment_id) >=43;

-- There are 599 customers meeting requrements. I will update the following customer:
-- customer_id = 111;
-- first_name = CARMEN;
-- last_name = OWENS;

-- Update customer information based on their current first and last name
-- This avoids hardcoding customer_id
BEGIN;

UPDATE public.customer
SET
    first_name  = 'OLEKSII',                 -- new first name
    last_name   = 'BUTKEVYCH',               -- new last name
    store_id    = 1,                         -- assign to store 1
    email       = 'ae.butkevich@gmail.com',  -- update email
    address_id  = 111,                       -- new address reference
    create_date = CURRENT_DATE,              -- set create date to today
    last_update = CURRENT_TIMESTAMP,         -- update timestamp to now
    active      = 1,                         -- mark as active
    activebool  = TRUE                       -- also update boolean active flag if applicable
WHERE first_name = UPPER('CARMEN') AND last_name = UPPER('OWENS')  -- identify customer by existing name
RETURNING customer_id, first_name, last_name, store_id, email, address_id, create_date, last_update, active, activebool;

COMMIT;





--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
-- Step 1: Identify the customer_id of OLEKSII BUTKEVYCH. This avoids hardcoding customer_id
BEGIN;

WITH target_customer AS (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = UPPER('OLEKSII') AND last_name = UPPER('BUTKEVYCH')
)

-- Step 2: Delete related records from other tables
--  deleting from rental table
DELETE FROM public.rental
WHERE customer_id IN (SELECT customer_id FROM target_customer);

COMMIT;




-- deleting from payment table. 
BEGIN;

WITH target_customer AS (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = UPPER('OLEKSII') AND last_name = UPPER('BUTKEVYCH')
)

DELETE FROM public.payment
WHERE customer_id IN (SELECT customer_id FROM target_customer);

COMMIT;




--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to 
-- represent this  activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install 
--the training database ) or add records for the first half of 2017)

-- Step 1: Identify customer_id
BEGIN;

WITH oleksii_butkevych AS (
    SELECT customer_id, store_id
    FROM public.customer
    WHERE first_name = UPPER('OLEKSII') AND last_name = UPPER('BUTKEVYCH')
),

-- Step 2: Select some inventory from the store(s) customer is in
-- Limit to 3 movies for this example
selected_inventory AS (
    SELECT i.inventory_id, i.store_id
    FROM public.inventory i
    JOIN oleksii_butkevych o ON i.store_id = o.store_id
    LIMIT 3
)

-- Step 3: Insert rentals
INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT 
    -- Rental date randomly in first half of 2017
    '2017-01-01'::timestamptz + (random() * (('2017-06-30'::date - '2017-01-01'::date)::int)) * interval '1 day',
    s.inventory_id,
    customer_id,
    -- Return date 3-10 days after rental
    '2017-01-01'::timestamptz + (random() * (('2017-06-30'::date - '2017-01-01'::date)::int)) * interval '1 day' + (3 + (random() * 7)) * interval '1 day',
    -- staff_id (from 1 to 5)
    3,        
    CURRENT_TIMESTAMP
FROM selected_inventory s
JOIN oleksii_butkevych o ON s.store_id = o.store_id
RETURNING rental_id, inventory_id, customer_id, rental_date, return_date;

COMMIT;


-- Step 4: Insert corresponding payments for the rentals
-- Payment amount: random between 3.99 and 5.99 for demonstration


BEGIN;

WITH oleksii_butkevych AS (
    SELECT customer_id, store_id
    FROM public.customer
    WHERE first_name = UPPER('OLEKSII') AND last_name = UPPER('BUTKEVYCH')
)

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    r.customer_id,
    r.staff_id,
    r.rental_id,
    3.99 + random() * 2,  -- amount between 3.99 and 5.99
    r.rental_date + (random() * 5) * interval '1 day'  -- payment within 5 days after rental
FROM public.rental r
JOIN oleksii_butkevych o ON r.customer_id = o.customer_id
RETURNING payment_id, customer_id, rental_id, amount, payment_date;

COMMIT;


