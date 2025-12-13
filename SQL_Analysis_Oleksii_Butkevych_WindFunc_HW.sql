/*
Task 1
Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels. 
This report should list the top 5 customers for each channel. Additionally, calculate a key performance indicator (KPI) 
called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales within 
their respective channel.
Please format the columns as follows:
Display the total sales amount with two decimal places
Display the sales percentage with four decimal places and include the percent sign (%) at the end
Display the result for each channel in descending order of sales
Below is a sample report. Please do not use it as is for your solution.
*/

WITH top_customers AS (
SELECT  c.channel_desc                                      								AS channel_name,
		cu.cust_id 																			AS customer_id,
    	cu.cust_last_name                                      								AS customer_last_name,
    	cu.cust_first_name                                      							AS customer_first_name,
    	TO_CHAR(SUM(s.amount_sold), 'FM9999990.00')                          				AS total_sales,
    	TO_CHAR(SUM(s.amount_sold)*100 / 
      	SUM(SUM(s.amount_sold)) OVER(PARTITION BY c.channel_desc), 'FM99990.0000') || ' %'  AS sales_percentage,
    	RANK() OVER(PARTITION BY c.channel_desc ORDER BY SUM(s.amount_sold) DESC)           AS rank_within_channel
FROM sh.channels c 
JOIN sh.sales s ON s.channel_id = c.channel_id 
JOIN sh.customers cu ON cu.cust_id = s.cust_id
GROUP BY 	c.channel_desc,
			cu.cust_id,
    		cu.cust_last_name,
    		cu.cust_first_name
), 
	sales_report AS (
SELECT 	cust_id										AS cust_id,
		COUNT(amount_sold)							AS quantity_of_transactions,
		ROUND(AVG(amount_sold:: numeric), 2)		AS average_purchase,
		MAX(time_id)								AS last_purchase
FROM sh.sales s
GROUP BY cust_id
)

SELECT  tc.channel_name,
   		tc.customer_last_name,
    	tc.customer_first_name,
    	tc.total_sales,
    	tc.sales_percentage,
    	sr.quantity_of_transactions,
    	sr.average_purchase,
    	sr.last_purchase,
    	tc.rank_within_channel
FROM top_customers AS tc
JOIN sales_report AS sr ON sr.cust_id = tc.customer_id
WHERE tc.rank_within_channel <=5
ORDER BY tc.channel_name, tc.total_sales DESC;


/*
Task 2
Create a query to retrieve data for a report that displays the total sales for all products in the 
Photo category in the Asian region for the year 2000. Calculate the overall report total and name it 'YEAR_SUM'
Display the sales amount with two decimal places
Display the result in descending order of 'YEAR_SUM'
For this report, consider exploring the use of the crosstab function. Additional details and guidance can be found at this link

Below is a sample report. Please do not use it as is for your solution.

 */ 

-- solution without the crosstab function
SELECT	p.prod_name																					AS product_name,
		p.prod_category																				AS product_category,
		ROUND(SUM(CASE WHEN EXTRACT(QUARTER FROM s.time_id) = 1 THEN s.amount_sold ELSE 0 END), 2) 	AS sum_Q1_2000,
		ROUND(SUM(CASE WHEN EXTRACT(QUARTER FROM s.time_id) = 2 THEN s.amount_sold ELSE 0 END), 2) 	AS sum_Q2_2000,
		ROUND(SUM(CASE WHEN EXTRACT(QUARTER FROM s.time_id) = 3 THEN s.amount_sold ELSE 0 END), 2) 	AS sum_Q3_2000,
		ROUND(SUM(CASE WHEN EXTRACT(QUARTER FROM s.time_id) = 4 THEN s.amount_sold ELSE 0 END), 2) 	AS sum_Q4_2000,
		ROUND(SUM(s.amount_sold), 2) 																AS year_sum,
		ROUND(SUM(SUM(s.amount_sold)) OVER (), 2) 													AS total_year_sum
FROM sh.products p
JOIN sh.sales s ON s.prod_id = p.prod_id 
JOIN sh.customers c ON c.cust_id = s.cust_id 
JOIN sh.countries co ON co.country_id = c.country_id 
WHERE 	UPPER(p.prod_category_desc) = 'PHOTO' AND
		UPPER(co.country_region) = 'ASIA' AND
		EXTRACT(YEAR FROM time_id) = 2000
GROUP BY p.prod_id, p.prod_name
ORDER BY total_year_sum DESC;



--solution using the crosstab function
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
	p.prod_name 		AS product_name,
	p.prod_category   	AS product_category,
	ct.Q1_2000			AS sum_Q1_2000,
	ct.Q2_2000			AS sum_Q2_2000,
	ct.Q3_2000			AS sum_Q3_2000,
	ct.Q4_2000			AS sum_Q4_2000,
	ROUND(
		COALESCE(ct.Q1_2000, 0) +
        COALESCE(ct.Q2_2000, 0) +
        COALESCE(ct.Q3_2000, 0) +
        COALESCE(ct.Q4_2000, 0), 2
    ) AS year_sum,
    ROUND(SUM(
        COALESCE(ct.Q1_2000, 0) +
        COALESCE(ct.Q2_2000, 0) +
        COALESCE(ct.Q3_2000, 0) +
        COALESCE(ct.Q4_2000, 0)
    ) OVER (), 2) AS total_year_sum
FROM (
    SELECT *
    FROM crosstab(
        $$
        SELECT 
            p.prod_id::text 								AS product_id, 
            'Q' || EXTRACT(QUARTER FROM s.time_id)::text 	AS quarter,
            ROUND(SUM(s.amount_sold), 2)					AS quarter_sum
        FROM sh.products p
        JOIN sh.sales s ON s.prod_id = p.prod_id
        JOIN sh.customers c ON c.cust_id = s.cust_id
        JOIN sh.countries co ON co.country_id = c.country_id
        WHERE UPPER(p.prod_category_desc) = 'PHOTO'
          AND UPPER(co.country_region) = 'ASIA'
          AND EXTRACT(YEAR FROM s.time_id) = 2000
        GROUP BY p.prod_id, EXTRACT(QUARTER FROM s.time_id)
        ORDER BY p.prod_id, quarter
        $$,
        $$
        SELECT 'Q1' UNION ALL
        SELECT 'Q2' UNION ALL
        SELECT 'Q3' UNION ALL
        SELECT 'Q4'
        $$
    ) AS ct(
        product_id text,
        Q1_2000 numeric,
        Q2_2000 numeric,
        Q3_2000 numeric,
        Q4_2000 numeric
    )
) ct
JOIN sh.products p ON p.prod_id::text = ct.product_id
ORDER BY total_year_sum DESC;


/*
Task 3
Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 
1998, 1999, and 2001. The report should be categorized based on sales channels, and separate calculations should 
be performed for each channel.
Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
Categorize the customers based on their sales channels
Perform separate calculations for each sales channel
Include in the report only purchases made on the channel specified
Format the column so that total sales are displayed with two decimal places
Below is a sample report. Please do not use it as is for your solution.
 */


WITH ranked AS (
		SELECT 	t.calendar_year,
				s.channel_id,
				s.cust_id,
				SUM(s.amount_sold)																			AS total_sales,
				RANK() OVER(PARTITION BY t.calendar_year, s.channel_id ORDER BY SUM(s.amount_sold) DESC) 	AS customer_rank_within_year_and_channel 
		FROM sh.sales AS s
		JOIN sh.times AS t ON t.time_id = s.time_id 
		WHERE t.calendar_year IN (1998, 1999, 2001)
		GROUP BY 	t.calendar_year,
					s.channel_id,
					s.cust_id
		)

SELECT 	h.channel_desc						AS channel_description,
		q.cust_id							AS customer_id,
		c.cust_first_name					AS customer_first_name,
		c.cust_last_name					AS customer_last_name,
		ROUND(q.total_sales:: decimal, 2)	AS total_sales,
		q.calendar_year				

FROM (
		SELECT 	t.cust_id,
				t.channel_id,
				t.calendar_year,
				CAST(TO_CHAR(t.total_sales, 'FM999999999.00') AS TEXT) AS total_sales,
				t.customer_rank_within_year_and_channel,
				COUNT(t.calendar_year) OVER(PARTITION BY t.cust_id, t.channel_id) AS number_of_years
		FROM ranked AS t
		WHERE t.customer_rank_within_year_and_channel <=300
		ORDER BY 	t.cust_id,
					t.channel_id,
					t.calendar_year
) AS q 
JOIN sh.customers AS c ON c.cust_id = q.cust_id 
JOIN sh.channels AS h ON h.channel_id = q.channel_id 
WHERE q.number_of_years =3;



/*
Task 4
Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
Display the result by months and by product category in alphabetical order.
Below is a sample report. Please do not use it as is for your solution.
 */
	
WITH sales_report AS(
	SELECT 
			TO_CHAR(s.time_id, 'YYYY-MM') 											AS sales_month,
			p.prod_category_desc													AS product_category,
			SUM(CASE WHEN co.country_region  = 'Europe' THEN s.amount_sold END) 	AS europe_sales,
			SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold END) 	AS americas_sales
	FROM sh.sales s
	JOIN sh.customers cu ON cu.cust_id = s.cust_id 
	JOIN sh.countries co ON co.country_id = cu.country_id 
	JOIN sh.products p ON p.prod_id = s.prod_id 
	WHERE s.time_id >= DATE '2000-01-01'
	  AND s.time_id <  DATE '2000-04-01'
	  AND UPPER(co.country_region) IN ('EUROPE', 'AMERICAS')
	GROUP BY
	    TO_CHAR(s.time_id, 'YYYY-MM'),
	    p.prod_category_desc
	)

SELECT	sales_month,
		product_category,
		europe_sales,
		RANK() OVER(PARTITION BY sales_month ORDER BY europe_sales DESC) AS europe_ranking,
		americas_sales,
		RANK() OVER(PARTITION BY sales_month ORDER BY americas_sales DESC) AS americas_ranking,
		ROUND(SUM(europe_sales) OVER(PARTITION BY sales_month), 2) AS europe_total_sales_by_month,
		ROUND(SUM(americas_sales) OVER(PARTITION BY sales_month), 2) AS americas_total_sales_by_month		
FROM sales_report
ORDER BY sales_month, product_category;



