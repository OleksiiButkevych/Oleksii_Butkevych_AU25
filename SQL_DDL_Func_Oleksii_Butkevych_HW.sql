/*
Create a view, query language functions, and procedure language functions using a DVD rental database.
Note:
Please pay attention that your code must be reusable and rerunnable and executes without errors.
Don't hardcode IDs
Add RAISE EXCEPTION to identify errors
Don't forget to check for duplicates, ensure that the object has not already been created (use CREATE OR REPLACE where appropriate to handle replacements safely)
Check that the function is run correctly and returns the desired result. Don't forget about optional parameters
*/

/*
Task 1. Create a view
Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue 
for the current quarter and year. The view should only display categories with at least one sale in the current quarter. 
Note: make it dynamic - when the next quarter begins, it automatically considers that as the current quarter
*/
CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS
WITH current_period AS (
    SELECT
        EXTRACT(YEAR FROM now())::int AS yr,
        EXTRACT(QUARTER FROM now())::int AS qtr
),
sales AS (
    SELECT
        c.name AS category_name,
        SUM(p.amount) AS total_revenue
    FROM public.payment p
    JOIN public.rental r        ON p.rental_id = r.rental_id
    JOIN public.inventory i     ON r.inventory_id = i.inventory_id
    JOIN public.film f          ON i.film_id = f.film_id
    JOIN public.film_category fc ON f.film_id = fc.film_id
    JOIN public.category c       ON fc.category_id = c.category_id
    CROSS JOIN current_period cp
    WHERE EXTRACT(YEAR FROM p.payment_date) = cp.yr
      AND EXTRACT(QUARTER FROM p.payment_date) = cp.qtr
    GROUP BY c.name
)
SELECT *
FROM sales
WHERE total_revenue > 0;

SELECT * 
FROM public.sales_revenue_by_category_qtr;





/*
Task 2. Create a query language functions
Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing 
the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.
 */
CREATE OR REPLACE FUNCTION public.get_sales_revenue_by_category_qtr(
    p_year INT,
    p_quarter INT
)
RETURNS TABLE (
    category_name TEXT,
    total_revenue NUMERIC
) AS $$
    SELECT
        c.name AS category_name,
        SUM(p.amount) AS total_revenue
    FROM public.payment p
    JOIN public.rental r         ON p.rental_id = r.rental_id
    JOIN public.inventory i      ON r.inventory_id = i.inventory_id
    JOIN public.film f           ON i.film_id = f.film_id
    JOIN public.film_category fc ON f.film_id = fc.film_id
    JOIN public.category c       ON fc.category_id = c.category_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = p_year
      AND EXTRACT(QUARTER FROM p.payment_date) = p_quarter
    GROUP BY c.name
    HAVING SUM(p.amount) > 0;
$$ LANGUAGE sql;

SELECT *
FROM public.get_sales_revenue_by_category_qtr(2017, 2);




/*
Task 3. Create procedure language functions
Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
The function should format the result set as follows:
Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);
*/
CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(
    p_countries TEXT[]
)
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating TEXT,
    "language" TEXT,
    "length" INT,
    release_year INT
)
LANGUAGE SQL AS
$$
WITH customers AS (
    SELECT
        cu.customer_id,
        co.country
    FROM public.country co
    JOIN public.city ci       ON ci.country_id = co.country_id
    JOIN public.address a     ON a.city_id = ci.city_id
    JOIN public.customer cu   ON cu.address_id = a.address_id
    WHERE UPPER(co.country) = ANY (
    ARRAY(SELECT UPPER(c) FROM unnest(p_countries) AS c)
)
),
film_counts AS (
    SELECT
        cu.country,
        i.film_id,
        COUNT(*) AS rental_count
    FROM public.rental r
    JOIN customers cu       ON cu.customer_id = r.customer_id
    JOIN public.inventory i ON i.inventory_id = r.inventory_id
    GROUP BY cu.country, i.film_id
),
max_film_counts AS (
    SELECT
        fc.country,
        MAX(fc.rental_count) AS max_rentals
    FROM film_counts fc
    GROUP BY fc.country
),
top_film AS (
    SELECT
        fc.country,
        fc.film_id,
        fc.rental_count
    FROM film_counts fc
    JOIN max_film_counts mfc
      ON fc.country = mfc.country
     AND fc.rental_count = mfc.max_rentals
)
-- pick the film with the highest film_id in case of tie
SELECT
    t.country,
    f.title AS film,
    f.rating,
    l.name AS "language",
    f."length",
    f.release_year
FROM top_film t
JOIN public.film f       ON f.film_id = (
    SELECT MAX(film_id) FROM top_film t2 WHERE UPPER(t2.country) = UPPER(t.country)
)
JOIN public."language" l ON l.language_id = f.language_id
GROUP BY t.country, f.title, f.rating, l.name, f."length", f.release_year
ORDER BY t.country;
$$;



SELECT *
FROM public.most_popular_films_by_countries(ARRAY['Afghanistan','Brazil','United States']);

SELECT *
FROM public.most_popular_films_by_countries(ARRAY['Brazil']);




/*
 *Task 4. Create procedure language functions
Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies 
containing the word 'love' in their title). The titles of these movies are formatted as '%...%', and if a movie
 with the specified title is not in stock, return a message indicating that it was not found. The function should 
 produce the result set in the following format (note: the 'row_num' field is an automatically generated counter 
 field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
Query (example):select * from core.films_in_stock_by_title('%love%’);
*/
CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(
    p_title_pattern TEXT DEFAULT '%'
)
RETURNS TABLE (
    row_num INT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    counter INT := 0;
BEGIN
    -- Validate input
    IF p_title_pattern IS NULL OR p_title_pattern = '' THEN
        RAISE EXCEPTION 'Title pattern cannot be null or empty';
    END IF;

    -- Loop through matching films
    FOR rec IN
        SELECT
            f.title AS film_title,
            l.name AS language,
            CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
            r.rental_date
        FROM public.film f
        JOIN public.inventory i ON i.film_id = f.film_id
        LEFT JOIN public.rental r ON r.inventory_id = i.inventory_id
        LEFT JOIN public.customer c ON r.customer_id = c.customer_id
        JOIN public."language" l ON l.language_id = f.language_id
        WHERE UPPER(f.title) LIKE UPPER(p_title_pattern)
          AND (r.rental_id IS NULL OR r.return_date IS NOT NULL)
        ORDER BY f.title, i.inventory_id
    LOOP
        counter := counter + 1;
        row_num := counter;
        film_title := rec.film_title;
        language := rec.language;
        customer_name := rec.customer_name;
        rental_date := rec.rental_date;
        RETURN NEXT;
    END LOOP;

    -- If no records returned, raise notice
    IF counter = 0 THEN
        RAISE NOTICE 'No movies found matching the pattern %', p_title_pattern;
    END IF;
END;
$$;


SELECT *
FROM public.films_in_stock_by_title('%love%');



/*
Task 5. Create procedure language functions
Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie 
with the given title in the film table. The function should generate a new unique film ID, set the rental rate to 4.99, 
the rental duration to three days, the replacement cost to 19.99. The release year and language are optional and by 
default should be current year and Klingon respectively. The function should also verify that the language exists 
in the 'language' table. Then, ensure that no such function has been created before; if so, replace it.
*/
-- adding UNIQUE constraint to public.language
ALTER TABLE public."language"
ADD CONSTRAINT language_name_unique UNIQUE(name);

CREATE OR REPLACE PROCEDURE public.new_movie(
    p_title TEXT,
    p_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    p_language_name TEXT DEFAULT 'Klingon'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_language_id INT;
BEGIN
    -- Validate title
    IF p_title IS NULL OR trim(p_title) = '' THEN
        RAISE EXCEPTION 'Movie title cannot be null or empty';
    END IF;

    -- Insert language safely (no duplicates once UNIQUE(name) exists)
    INSERT INTO public."language"(name)
    VALUES (p_language_name)
    ON CONFLICT (name) DO NOTHING;

    -- Retrieve language_id
    SELECT language_id
    INTO v_language_id
    FROM public."language"
    WHERE UPPER(name) = UPPER(p_language_name);

    -- Insert new movie
    INSERT INTO public.film (
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        last_update
    )
    VALUES (
        p_title,
        p_release_year,
        v_language_id,
        3,
        4.99,
        19.99,
        now()
    );

    RAISE NOTICE 'Movie "%" added with language "%" (id %)',
                 p_title, p_language_name, v_language_id;
END;
$$;


CALL public.new_movie('Intergalactic Adventure');

SELECT * FROM public.film
WHERE title LIKE '%ntergalacti%';

CALL public.new_movie('Home_Alone', 1985, 'Portuguese'); 

SELECT * FROM public.film
WHERE title = 'Home_Alone';

SELECT *
FROM public."language";

