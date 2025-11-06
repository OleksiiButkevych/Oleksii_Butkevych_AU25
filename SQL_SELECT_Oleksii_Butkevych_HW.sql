--adding foreign keys  to payment table (this was necessary for practice task)
ALTER TABLE payment
ADD CONSTRAINT fk_payment_customer
FOREIGN KEY (customer_id)
REFERENCES customer(customer_id);

ALTER TABLE payment
ADD CONSTRAINT fk_payment_staff
FOREIGN KEY (staff_id)
REFERENCES staff(staff_id);

ALTER TABLE payment
ADD CONSTRAINT fk_payment_rental
FOREIGN KEY (rental_id)
REFERENCES rental(rental_id);




--Part 1: Write SQL queries to retrieve the following data. 
--1.1 The marketing team needs a list of animation movies between 2017 and 2019 to promote family-friendly content in an upcoming season in stores. 
--Show all animation movies released during this period with rate more than 1, sorted alphabetically

-- 1.1. JOIN solution.
SELECT 	f.film_id, 
		f.title, 
		f.release_year, 
		f.rental_rate, 
		c."name" AS category_name
FROM public.film f 
INNER JOIN public.film_category fc ON fc.film_id = f.film_id
INNER JOIN public.category c ON c.category_id = fc.category_id 
WHERE 	f.release_year BETWEEN 2017 AND 2019 AND 
		f.rental_rate > 1 AND 
		UPPER(c."name")  = UPPER('Animation')
ORDER BY f.title ASC;

--1.1. CTE solution.
WITH animation_films AS (
	SELECT 	f.film_id, 
			f.title, 
			f.release_year, 
			f.rental_rate, 
			c."name" AS category_name
	FROM public.film f 
	INNER JOIN public.film_category fc ON fc.film_id = f.film_id
	INNER JOIN public.category c ON c.category_id = fc.category_id 
	WHERE 	UPPER(c."name")  = UPPER('Animation')
	)

SELECT 	film_id, 
		title, 
		release_year, 
		rental_rate, 
		category_name
FROM animation_films
WHERE 	release_year BETWEEN 2017 AND 2019 AND 
		rental_rate > 1
ORDER BY title ASC;

--1.1. Subquery solution
SELECT 	f.film_id, 
		f.title, 
		f.release_year, 
		f.rental_rate, 
		c."name" AS category_name
FROM public.film f 
INNER JOIN public.film_category fc ON fc.film_id = f.film_id
INNER JOIN public.category c ON c.category_id = fc.category_id 
WHERE 	f.release_year BETWEEN 2017 AND 2019 AND 
		f.rental_rate > 1 AND 
		c.category_id IN (
			SELECT category_id 
			FROM public.category
			WHERE UPPER("name") = UPPER('Animation')
			)
ORDER BY f.title ASC;


/*
--the advantages and disadvantages of each solution - JOIN, CTE and Subquery.
JOIN Solution:
Advantages:
1. Performance-efficient (typically best choice):
Joins are handled by the SQL optimizer at once — the database engine can use indexes on indexed columns, optimizing execution.
2. Direct and explicit relationships:
It is clearly defined how tables relate to each other (INNER JOIN, LEFT JOIN, etc.), making it easy for other developers to follow.
3. Good for filtering and aggregation across tables:
Most DBMS engines are optimized for joins and can combine data efficiently.
Disadvantages:
1. Can become verbose for complex queries:
With multiple joins, nested joins, and filters, readability suffers.
2. Limited modularity:
If the same intermediate dataset is reused elsewhere, you must repeat the join logic or use a CTE/view.


CTE solution:
Advantages:
1. Improves readability & modularity:
Lets you separate query logic into clear, reusable blocks (WITH animation_films AS (...)).
2. Good for step-by-step transformations:
Each CTE can represent a logical step, useful for debugging or documentation.
3. Useful for recursive queries:
CTEs can handle hierarchical data, which subqueries and plain joins cannot easily do.
Disadvantages:
1. Potentially higher resource use (depending on DB engine):
Some databases (like PostgreSQL before v12) materialize CTEs — temporarily store results before the outer query executes, 
which can degrade performance.
2. Not always optimized inline:
In some systems, the optimizer treats CTEs as isolated, blocking further optimization.
3. Slightly more complex syntax for simple one-step filters.

3. Subquery Solution
Advantages:
1. Compact for simple lookups or filters:
Ideal when you just need to check existence or match values (IN (SELECT ...)).
2. Readable for certain conditions:
When the subquery isolates a simple condition (like category name), it’s quite intuitive.
3. Can simplify filtering logic if the join would otherwise require multiple steps.
Disadvantages:
1. Performance cost (especially with IN or NOT IN):
Depending on the database and indexes, subqueries can lead to repeated scans or temporary tables.
(Though modern optimizers often rewrite them as joins.)
2. Nested queries harder to debug:
For large or complex logic, subqueries can get deeply nested and obscure intent.
3. Limited reusability:
Each subquery is isolated — can’t easily reuse or reference elsewhere.

In this specific example:
All three produce identical results, but:
JOIN version - is the best for production and performance.
CTE version is the best for clarity and maintainability, especially if more filters or categories are added later.
Subquery version is acceptable, but less efficient and less readable if scaled up.
*/


--1.2. The finance department requires a report on store performance to assess profitability and plan resource allocation for stores 
--after March 2017. Calculate the revenue earned by each rental store after March 2017 (since April) 
--(include columns: address and address2 – as one column, revenue)
-- 1.2. JOIN solution.
SELECT 	s.store_id, 
		CONCAT(a.address, ' ', a.address2) 	AS full_address, 
		SUM(p.amount) 						AS revenue
FROM public.store s 
INNER JOIN public.customer c ON c.store_id = s.store_id
INNER JOIN public.payment p ON p.customer_id = c.customer_id 
INNER JOIN public.address a ON a.address_id = s.address_id 
WHERE 	p.payment_date >= '2017-04-01'
GROUP BY s.store_id, full_address
ORDER BY revenue DESC;

-- 1.2. CTE solution.
WITH store_payments AS (
	SELECT 	s.store_id, 
			a.address, 
			a.address2,
			p.amount,
			p.payment_date 
	FROM public.store s 
	INNER JOIN public.customer c ON c.store_id = s.store_id
	INNER JOIN public.payment p ON p.customer_id = c.customer_id 
	INNER JOIN public.address a ON a.address_id = s.address_id 
	WHERE 	p.payment_date >= '2017-04-01'
	)

SELECT		store_id,
			CONCAT(address, ' ',address2) 	AS full_address,
			SUM(amount) AS revenue
FROM store_payments
GROUP BY store_id, full_address
ORDER BY revenue DESC;

-- 1.2. Subquery solution
SELECT	filtered_stores.store_id,
		CONCAT(filtered_stores.address, ' ',filtered_stores.address2) AS full_address,
		SUM(filtered_stores.amount) AS revenue
FROM (
	SELECT 	s.store_id, 
			a.address, 
			a.address2,
			p.amount,
			p.payment_date 
	FROM public.store s 
	INNER JOIN public.customer c ON c.store_id = s.store_id
	INNER JOIN public.payment p ON p.customer_id = c.customer_id 
	INNER JOIN public.address a ON a.address_id = s.address_id 
	WHERE 	p.payment_date >= '2017-04-01'
	) AS filtered_stores
GROUP BY store_id, full_address
ORDER BY revenue DESC;

/* In this task:
JOIN version - is the best performing and simplest for this type of aggregate report.
CTE version is the most readable and maintainable, especially if you’ll extend it (e.g., by month, by region).
Subquery version is functionally fine, but less clear and slightly more resource-heavy; mainly useful if you’re embedding this query inside another.
*/

-- 1.3. The marketing department in our stores aims to identify the most successful actors since 2015 to boost customer interest in their films. 
--Show top-5 actors by number of movies (released after 2015) they took part in 
--(columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
-- 1.3. JOIN solution.
SELECT 	a.actor_id,
		a.first_name, 
		a.last_name, 
		COUNT(f.film_id) AS number_of_movies
FROM public.actor a  
INNER JOIN public.film_actor fa ON fa.actor_id = a.actor_id 
INNER JOIN public.film f ON f.film_id = fa.film_id 
WHERE 	f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;
 
-- 1.3. CTE solution.
WITH actor_film_count AS (
	SELECT 	a.actor_id,
			a.first_name, 
			a.last_name, 
			COUNT(f.film_id) AS number_of_movies
	FROM public.actor a  
	INNER JOIN public.film_actor fa ON fa.actor_id = a.actor_id 
	INNER JOIN public.film f ON f.film_id = fa.film_id 
	WHERE 	f.release_year > 2015
	GROUP BY a.actor_id, a.first_name, a.last_name
		)
		
SELECT 	actor_id,
		first_name, 
		last_name, 
		number_of_movies
FROM actor_film_count
ORDER BY number_of_movies DESC
LIMIT 5;

-- 1.3. Subquery solution
SELECT 	actor_film.actor_id,
		actor_film.first_name,
		actor_film.last_name,
		actor_film.number_of_movies
FROM (
	SELECT 	a.actor_id,
			a.first_name, 
			a.last_name, 
			COUNT(f.film_id) AS number_of_movies
	FROM public.actor a  
	INNER JOIN public.film_actor fa ON fa.actor_id = a.actor_id 
	INNER JOIN public.film f ON f.film_id = fa.film_id 
	WHERE 	f.release_year > 2015
	GROUP BY a.actor_id, a.first_name, a.last_name
	) AS actor_film
ORDER BY actor_film.number_of_movies DESC
LIMIT 5;
	

/*
In this task:
JOIN version is the best choice — simplest and fastest for this direct aggregation.
CTE version - the best readability if you plan to extend it (e.g., add ranking, actor age, or revenue).
Subquery version - acceptable, but adds unnecessary nesting for such a small query.
*/

--  1.4. The marketing team needs to track the production trends of Drama, Travel, and Documentary films to inform genre-specific 
--marketing strategies. Show number of Drama, Travel, Documentary per year 
--(include columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), 
--sorted by release year in descending order. Dealing with NULL values is encouraged)
-- 1.4. JOIN solution
SELECT 	f.release_year, 
		COALESCE(SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END), 0) 			AS number_of_drama_movies,
		COALESCE(SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END), 0) 		AS number_of_travel_movies,
		COALESCE(SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END), 0) 	AS number_of_documentary_movies
FROM public.film f 
JOIN public.film_category fc ON fc.film_id = f.film_id 
JOIN public.category c ON c.category_id = fc.category_id 
WHERE UPPER(c."name") IN (UPPER('Drama'), UPPER('Travel'), UPPER('Documentary'))
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- 1.4. CTE solution
WITH filtered_films AS (
	SELECT 	f.release_year,
			c."name" AS category_name
	FROM public.film f 
	JOIN public.film_category fc ON fc.film_id = f.film_id 
	JOIN public.category c ON c.category_id = fc.category_id 
	WHERE	UPPER(c."name") IN (UPPER('Drama'), UPPER('Travel'), UPPER('Documentary'))
)

SELECT 
	release_year,
	COALESCE(SUM(CASE WHEN category_name = 'Drama' THEN 1 ELSE 0 END), 0) 		AS number_of_drama_movies,
	COALESCE(SUM(CASE WHEN category_name = 'Travel' THEN 1 ELSE 0 END), 0) 		AS number_of_travel_movies,
	COALESCE(SUM(CASE WHEN category_name = 'Documentary' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies
FROM filtered_films
GROUP BY release_year
ORDER BY release_year DESC;

-- 1.4. Subquery.
SELECT 
	filtered_films.release_year,
	COALESCE(SUM(CASE WHEN filtered_films.category_name = 'Drama' THEN 1 ELSE 0 END), 0) 		AS number_of_drama_movies,
	COALESCE(SUM(CASE WHEN filtered_films.category_name = 'Travel' THEN 1 ELSE 0 END), 0) 		AS number_of_travel_movies,
	COALESCE(SUM(CASE WHEN filtered_films.category_name = 'Documentary' THEN 1 ELSE 0 END), 0) 	AS number_of_documentary_movies
FROM (
	SELECT 
		f.release_year,
		c.name AS category_name
	FROM public.film f
	JOIN public.film_category fc ON f.film_id = fc.film_id
	JOIN public.category c ON c.category_id = fc.category_id
	WHERE UPPER(c."name") IN (UPPER('Drama'), UPPER('Travel'), UPPER('Documentary'))
) AS filtered_films
GROUP BY filtered_films.release_year
ORDER BY filtered_films.release_year DESC;

/*
In this task:
1. JOIN version - best for performance and simplicity — single-step pivot-like aggregation.
2. CTE version - best readability and modularity — great if you’ll reuse or expand logic (e.g., more categories, averages, totals).
3. Subquery version - technically fine, but adds nesting that offers little benefit for a one-layer analysis.
*/


--Part 2: Solve the following problems using SQL
--2.1. The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores revenue. 
--Show which three employees generated the most revenue in 2017? 

--Assumptions: 
--staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store; 
--take into account only payment_date
--2.1. JOIN solution
SELECT 	
		s.staff_id,
		s.first_name, 
		s.last_name, 
		st.store_id,
		sum(p.amount) AS total_revenue
FROM public.staff s
INNER JOIN public.payment p ON p.staff_id = s.staff_id 
INNER JOIN public.store st ON st.store_id = s.store_id 
WHERE 	p.payment_date >= '2017-01-01'AND 
		p.payment_date < '2018-01-01'
GROUP BY s.staff_id, s.first_name, s.last_name, st.store_id 
ORDER BY total_revenue DESC
LIMIT 3;

-- 2.1 CTE solution
WITH staff_revenue AS (
	SELECT 
			p.staff_id,
			s.first_name,
			s.last_name,
			s.store_id,
			SUM(p.amount) AS total_revenue
	FROM payment p
	JOIN staff s ON p.staff_id = s.staff_id
	JOIN store st ON s.store_id = st.store_id
	WHERE	p.payment_date >= '2017-01-01'AND 
			p.payment_date < '2018-01-01'
	GROUP BY p.staff_id, s.first_name, s.last_name, s.store_id
),

last_store AS (
	SELECT 
			p.staff_id,
			s.store_id,
			MAX(p.payment_date) AS last_payment_date
	FROM payment p
	JOIN staff s ON p.staff_id = s.staff_id
	WHERE 	p.payment_date >= '2017-01-01'AND 
		p.payment_date < '2018-01-01'
	GROUP BY p.staff_id, s.store_id
),

final_data AS (
	SELECT 
		sr.staff_id,
		sr.first_name,
		sr.last_name,
		ls.store_id,
		sr.total_revenue
	FROM staff_revenue AS sr
	JOIN last_store AS ls ON sr.staff_id = ls.staff_id
)

SELECT 
	staff_id,
	first_name,
	last_name,
	store_id,
	total_revenue
FROM final_data
ORDER BY total_revenue DESC
LIMIT 3;

-- 2.1. Subquery solution
SELECT 
	staff_income.staff_id,
	staff_income.first_name,
	staff_income.last_name,
	staff_income.store_id,
	staff_income.total_revenue
FROM (
	SELECT 
			p.staff_id,
			s.first_name,
			s.last_name,
			s.store_id,
			SUM(p.amount) AS total_revenue
	FROM payment p
	JOIN staff s ON p.staff_id = s.staff_id
	JOIN store st ON s.store_id = st.store_id
	WHERE 	p.payment_date >= '2017-01-01'AND 
			p.payment_date < '2018-01-01'
	GROUP BY p.staff_id, s.first_name, s.last_name, s.store_id
) AS staff_income
JOIN (
	SELECT 
			p.staff_id,
			s.store_id,
			MAX(p.payment_date) AS last_payment_date
	FROM payment p
	JOIN staff s ON p.staff_id = s.staff_id
	WHERE 	p.payment_date >= '2017-01-01'AND 
			p.payment_date < '2018-01-01'
	GROUP BY p.staff_id, s.store_id
) AS last_shop
	ON staff_income.staff_id = last_shop.staff_id
ORDER BY staff_income.total_revenue DESC
LIMIT 3;

/*
In this task: 
JOIN version - best performance and simplest for direct reporting — ideal if you only need revenue totals.
CTE version - best structure and clarity — perfect when building a multi-step analytical report or ETL transformation 
(like tracking both revenue and last sale info).
Subquery version - acceptable and equivalent performance, but less readable and harder to maintain compared to the multi-CTE format.
*/


--2. The management team wants to identify the most popular movies and their target audience age groups to optimize marketing efforts. 
--Show which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? 
--To determine expected age please use 'Motion Picture Association film rating system'
-- 2.2. JOIN solution
SELECT
	f.film_id,
	f.title,
	f.rating,
	CASE f.rating 
		WHEN 'G' THEN '0-6+'
		WHEN 'PG' THEN '8+'
		WHEN 'PG-13' THEN '13+'
		WHEN 'R' THEN '17+ (or 16+ with adult)'
		WHEN 'NC-17' THEN '18+'
		ELSE 'No_data'
	END AS age_of_group,
	COUNT(r.rental_id)			AS count_of_rentals
FROM public.film f
INNER JOIN public.inventory i ON i.film_id = f.film_id
INNER JOIN public.rental r ON r.inventory_id = i.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY count_of_rentals DESC, f.title       
LIMIT 5;

-- 2.2. CTE solution
WITH rental_counts AS (
	SELECT 	f.film_id,
			f.title,
			f.rating,
			COUNT(r.rental_id) AS count_of_rentals
	FROM film f
	JOIN inventory i ON i.film_id = f.film_id
	JOIN rental r ON r.inventory_id = i.inventory_id
	GROUP BY f.film_id, f.title, f.rating
)

SELECT 
	film_id,
	title,
	rating,
	CASE rating
		WHEN 'G' THEN '0-6+'
		WHEN 'PG' THEN '8+'
		WHEN 'PG-13' THEN '13+'
		WHEN 'R' THEN '17+ (or 16+ with adult)'
		WHEN 'NC-17' THEN '18+'
		ELSE 'No_data'
	END AS age_of_group,
	count_of_rentals
FROM rental_counts
ORDER BY count_of_rentals DESC, title
LIMIT 5;

-- 2.2. Subquery solution
SELECT 	count_of_rentals.film_id,
		count_of_rentals.title,
		count_of_rentals.rating,
		CASE rating
			WHEN 'G' THEN '0-6+'
			WHEN 'PG' THEN '8+'
			WHEN 'PG-13' THEN '13+'
			WHEN 'R' THEN '17+ (or 16+ with adult)'
			WHEN 'NC-17' THEN '18+'
			ELSE 'No_data'
		END AS age_of_group,
		count_of_rentals.number_of_rentals
FROM (
	SELECT 	f.film_id,
			f.title,
			f.rating,
			COUNT(r.rental_id) AS number_of_rentals
	FROM film f
	JOIN inventory i ON i.film_id = f.film_id
	JOIN rental r ON r.inventory_id = i.inventory_id
	GROUP BY f.film_id,f.title, f.rating
	) AS count_of_rentals
ORDER BY count_of_rentals.number_of_rentals DESC, title
LIMIT 5;

/*
In this task:
JOIN version - the best choice for performance and simplicity. Perfect for dashboards or daily summaries.
CTE version - the  most maintainable and clean; separates calculation (rental counts) from presentation (age group mapping). 
Excellent for more complex or reusable analytics.
Subquery version - functionally fine, similar performance, but less readable — suitable if embedding this logic in a larger query. 
 */

--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for 
--targeted promotional campaigns, highlighting their comebacks or consistent appearances to engage customers 
--with nostalgic or reliable film stars
--The task can be interpreted in various ways, and here are a few options (provide solutions for each one):
--V1: gap between the latest release_year and current year per each actor;
--V2: gaps between sequential films per each actor;

-- 3.1. JOIN solution. V1: gap between the latest release_year and current year per each actor;
SELECT	a.actor_id,
		a.first_name, 
		a.last_name,
		MAX(f.release_year) AS last_release_year,
		EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS inactivity_years
FROM actor a
JOIN film_actor fa ON fa.actor_id = a.actor_id
JOIN film f ON f.film_id = fa.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY inactivity_years DESC
LIMIT 1;

-- 3.1. CTE solution. V1: gap between the latest release_year and current year per each actor;
WITH actor_latest_release AS (
	SELECT	a.actor_id,
			a.first_name, 
			a.last_name,
			MAX(f.release_year) AS last_release_year
	FROM actor a
	JOIN film_actor fa ON fa.actor_id = a.actor_id
	JOIN film f ON f.film_id = fa.film_id
	GROUP BY a.actor_id, a.first_name, a.last_name
)

SELECT	actor_id,
		first_name,
		last_name,
		last_release_year,
		EXTRACT(YEAR FROM CURRENT_DATE) - last_release_year AS inactivity_years
FROM actor_latest_release
ORDER BY inactivity_years DESC
LIMIT 1;


-- 3.1. Sunquery solution. V1: gap between the latest release_year and current year per each actor;
SELECT	last_year.actor_id,
		last_year.first_name,
		last_year.last_name,
		last_year.last_release_year,
		EXTRACT(YEAR FROM CURRENT_DATE) - last_year.last_release_year AS inactivity_years
FROM	(
		SELECT	a.actor_id,
				a.first_name, 
				a.last_name,
				MAX(f.release_year) AS last_release_year
		FROM actor a
		JOIN film_actor fa ON fa.actor_id = a.actor_id
		JOIN film f ON f.film_id = fa.film_id
		GROUP BY a.actor_id, a.first_name, a.last_name
		) AS last_year
ORDER BY inactivity_years DESC
LIMIT 1;

/* In the task:
JOIN version - the best for fast reporting and simple aggregations. 
Example: dashboards, API endpoints, or quick audits.
CTE version - the best for analytics pipelines and reusable logic.
Example: multi-step transformations or layered reports (e.g., actor inactivity, followed by genre activity comparison).
Subquery version - the best for embedding this logic inside other queries or when CTEs aren’t available.
Example: as part of a larger “actor performance” analysis query.
 */

--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for 
--targeted promotional campaigns, highlighting their comebacks or consistent appearances to engage customers 
--with nostalgic or reliable film stars
--The task can be interpreted in various ways, and here are a few options (provide solutions for each one):
--V1: gap between the latest release_year and current year per each actor;
--V2: gaps between sequential films per each actor;

-- 3.1. JOIN solution. V2: gaps between sequential films per each actor;
SELECT
	a.actor_id,
	a.first_name, 
	a.last_name,
	f1.title AS film_title,
	f1.release_year AS current_film_year,
	f2.title AS next_film_title,
	f2.release_year AS next_film_year,
	f2.release_year - f1.release_year AS inactivity_years
FROM public.actor a
JOIN public.film_actor fa1 ON a.actor_id = fa1.actor_id
JOIN public.film f1 ON f1.film_id = fa1.film_id
JOIN public.film_actor fa2 ON a.actor_id = fa2.actor_id
JOIN public.film f2 ON f2.film_id = fa2.film_id
WHERE f2.release_year > f1.release_year
	AND NOT EXISTS (
		SELECT 1
        FROM public.film_actor fa3
		JOIN public.film f3 ON f3.film_id = fa3.film_id
		WHERE fa3.actor_id = a.actor_id
		AND f3.release_year > f1.release_year
		AND f3.release_year < f2.release_year
		)
ORDER BY inactivity_years DESC
LIMIT 1;



-- 3.1. CTE solution. V2: gaps between sequential films per each actor;
WITH actor_films AS (
	SELECT 
		a.actor_id,
		a.first_name, 
		a.last_name,
		f.film_id,
		f.title AS film_title,
		f.release_year
	FROM public.actor a
	JOIN public.film_actor fa ON a.actor_id = fa.actor_id
	JOIN public.film f ON f.film_id = fa.film_id
	)
SELECT 
	af1.actor_id,
	af1.first_name,
	af1.last_name,
	af1.film_title AS current_film,
	af1.release_year AS current_year,
	af2.film_title AS next_film,
	af2.release_year AS next_year,
	af2.release_year - af1.release_year AS inactivity_years
FROM actor_films af1
JOIN actor_films af2  ON af1.actor_id = af2.actor_id AND 
	af2.release_year > af1.release_year AND 
	NOT EXISTS (
		SELECT 1
		FROM actor_films af3
		WHERE 	af3.actor_id = af1.actor_id AND 
				af3.release_year > af1.release_year AND 
				af3.release_year < af2.release_year
				)
ORDER BY inactivity_years DESC
LIMIT 1;


-- 3.1. Subquery solution. V2: gaps between sequential films per each actor;
SELECT 
	af1.actor_id,
	af1.actor_name,
	af1.film_title AS current_film,
	af1.release_year AS current_year,
	af2.film_title AS next_film,
	af2.release_year AS next_year,
	af2.release_year - af1.release_year AS inactivity_years
FROM (
	SELECT 	a.actor_id,
			a.first_name || ' ' || a.last_name AS actor_name,
			f.film_id,
			f.title AS film_title,
			f.release_year
	FROM public.actor a
	JOIN public.film_actor fa ON a.actor_id = fa.actor_id
	JOIN public.film f ON f.film_id = fa.film_id
) AS af1
JOIN (
	SELECT 
		a.actor_id,
		a.first_name || ' ' || a.last_name AS actor_name,
		f.film_id,
		f.title AS film_title,
		f.release_year
	FROM public.actor a
	JOIN public.film_actor fa ON a.actor_id = fa.actor_id
	JOIN public.film f ON f.film_id = fa.film_id
) AS af2
ON af1.actor_id = af2.actor_id
AND af2.release_year > af1.release_year
AND NOT EXISTS (
	SELECT 1
	FROM (
		SELECT 
			a.actor_id,
			f.release_year
		FROM public.actor a
		JOIN public.film_actor fa ON a.actor_id = fa.actor_id
		JOIN public.film f ON f.film_id = fa.film_id
    ) AS af3
	WHERE af3.actor_id = af1.actor_id AND 
	af3.release_year > af1.release_year AND 
	af3.release_year < af2.release_year
	)
ORDER BY inactivity_years DESC
LIMIT 1;


/*
JOIN is concise but can be heavy on large datasets.
CTE improves readability and allows modular reuse of the actor_films set.
Subquery is functionally identical to JOIN but is verbose and harder to maintain; performance is usually similar.
*/






