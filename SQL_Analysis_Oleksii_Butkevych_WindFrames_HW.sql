/*
Task 1
Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels and regions: 
'Americas,' 'Asia,' and 'Europe.' 
The resulting report should contain the following columns:
AMOUNT_SOLD: This column should show the total sales amount for each sales channel
% BY CHANNELS: In this column, we should display the percentage of total sales for each channel (e.g. 100% - total sales for Americas 
in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
% PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column but for the previous year
% DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating the change in 
sales percentage from the previous year.
The final result should be sorted in ascending order based on three criteria: first by 'country_region,' then by 'calendar_year,' 
and finally by 'channel_desc'
Below is a sample report. Please do not use it as is for your solution.
 */


WITH sales_agg AS (
	SELECT
		co.country_region,
		t.calendar_year,
		ch.channel_desc,
		SUM(s.amount_sold) AS amount_sold
	FROM sh.countries co
	JOIN sh.customers cu ON cu.country_id = co.country_id
	JOIN sh.sales s ON s.cust_id = cu.cust_id
	JOIN sh.channels ch ON ch.channel_id = s.channel_id
	JOIN sh.times t ON t.time_id = s.time_id
	WHERE t.calendar_year BETWEEN 1998 AND 2001   -- keep 1998 for analytics
		AND UPPER(co.country_region) IN ('AMERICAS', 'ASIA', 'EUROPE')
	GROUP BY
		co.country_region,
		t.calendar_year,
		ch.channel_desc
),
calc_pct AS (
	SELECT
		country_region,
		calendar_year,
		channel_desc,
		amount_sold,
		ROUND(
			amount_sold
			/ SUM(amount_sold) OVER (
				PARTITION BY country_region, calendar_year
				ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			) * 100,
			2
			) AS pct_by_channels
	FROM sales_agg
),
calc_prev AS (
	SELECT
		country_region,
		calendar_year,
		channel_desc,
		amount_sold,
		pct_by_channels,
        -- previous year using window frame 
		MAX(pct_by_channels) OVER (
			PARTITION BY country_region, channel_desc
			ORDER BY calendar_year
			ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING
			) AS prev_period,
        -- difference vs previous year
		ROUND(
				pct_by_channels
				- MAX(pct_by_channels) OVER (
				PARTITION BY country_region, channel_desc
				ORDER BY calendar_year
				ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING
				),
				2
			) AS pct_diff
	FROM calc_pct
)
SELECT
	country_region,
	calendar_year,
	channel_desc,
	TO_CHAR(amount_sold, 'FM999,999,999,999.00' || ' $')								AS "amount sold",
	TO_CHAR(pct_by_channels, 'FM990.00') || ' %'         								AS "% by channels",
	TO_CHAR(prev_period, 'FM990.00') || ' %'             								AS "% previous period",
	TO_CHAR(pct_diff, 'FM990.00') || ' %'                								AS "% diff",
	RANK() OVER(PARTITION BY country_region, calendar_year ORDER BY amount_sold DESC) 	AS "rank within year"
FROM calc_prev
WHERE calendar_year BETWEEN 1999 AND 2001   -- hide 1998 only here
ORDER BY
	country_region,
	calendar_year,
	channel_desc;


/*
Task 2
You need to create a query that meets the following requirements:
Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
Include a column named CUM_SUM to display the amounts accumulated during each week.
Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days using 
a centered moving average.
For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
For Friday, calculate the average sales on Thursday, Friday, and the weekend.
Ensure that your calculations are accurate for the beginning of week 49 and the end of week 51.
Below is a sample report. Please do not use it as is for your solution.
 */
WITH daily_sales AS (
	-- Aggregate sales per day
	SELECT
		s.time_id::date AS day_date,
		EXTRACT(YEAR FROM s.time_id) AS calendar_year,
		EXTRACT(WEEK FROM s.time_id) AS week_of_year,
		EXTRACT(DOW FROM s.time_id) AS day_of_week,  -- 0=Sunday, 1=Monday, ..., 6=Saturday
		TO_CHAR(s.time_id, 'FMDay') AS day_name,     -- Name of the day
		SUM(s.amount_sold) AS amount_sold
	FROM sh.sales s
	JOIN sh.customers c	ON s.cust_id = c.cust_id
	WHERE 	EXTRACT(YEAR FROM s.time_id) = 1999 AND 
			EXTRACT(WEEK FROM s.time_id) IN (49, 50, 51)
	GROUP BY s.time_id
)
, cum_and_avg AS (
	SELECT
		day_date,
		week_of_year,
		day_name,
		day_of_week,
        amount_sold,
        SUM(amount_sold) OVER (                  	-- cumulative sum **per week**
			PARTITION BY week_of_year
			ORDER BY day_date
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		) AS cum_sum,								 -- centered 3-day moving average with special Monday/Friday handling
		ROUND(
			CASE
				WHEN day_of_week = 1 THEN            -- Monday: use previous weekend (Sat/Sun), Mon, Tue
						AVG(amount_sold) OVER (
						ORDER BY day_date
						ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
						)
				WHEN day_of_week = 5 THEN            -- Friday: use Thu, Fri, Sat
						AVG(amount_sold) OVER (
						ORDER BY day_date
						ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
						)
				ELSE                                -- all other days: previous, current, next
						AVG(amount_sold) OVER (
						ORDER BY day_date
						ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
						)
				END
		, 2) AS centered_3_day_avg
	FROM daily_sales
)
SELECT
	day_date,
	day_name,
	week_of_year,
	amount_sold,
	cum_sum 			AS CUM_SUM,
	centered_3_day_avg 	AS CENTERED_3_DAY_AVG
FROM cum_and_avg
ORDER BY day_date;



/*
Task 3
Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. 
Additionally, explain the reason for choosing a specific frame type for each example. 
This can be presented as a single query or as three distinct queries.
*/
SELECT
	prod_id,
	cust_id,
	time_id,
	amount_sold,
	SUM(amount_sold) OVER (					--1. ROWS frame: running total by customer over time
		PARTITION BY cust_id
		ORDER BY time_id
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	) AS rolling_3_row_sales,
	SUM(amount_sold) OVER (                 --2. RANGE frame: cumulative sales within a date range
		PARTITION BY cust_id
		ORDER BY time_id
		RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
	) AS rolling_7_day_sales,
	SUM(amount_sold) OVER (                   --3. GROUPS frame: sales aggregated by same-date groups
		PARTITION BY cust_id
		ORDER BY time_id
		GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
	) AS grouped_day_sales
FROM sh.sales;


/*
 1. Rows clause. 
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
- Includes the current row and the previous 2 rows, regardless of their dates.
- Operates on physical row positions.
-- Useful when you want a fixed number of records, such as rolling averages, moving totals.

2. Range frame. 
RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
- Includes all rows within the last 7 days, including the current date.
- Rows with the same time_id are automatically grouped together.
- Best for time-based analysis, such as weekly rolling totals, financial trends over calendar periods.
- Handles uneven numbers of transactions per day correctly.

3. Groups frame.
GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
- Groups rows with the same ORDER BY value (time_id).
- Includes the current date group and the previous date group.
- Groups frame is chosen when multiple rows share the same ordering value (e.g., many sales on one day) or 
you want to aggregate by logical groups, not rows or ranges
*/


