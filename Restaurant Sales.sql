/* Restaurant Sales SQL Project */

/* Objective
To provide business insights based on the query results. */

-- What is the monthly revenue?
SELECT EXTRACT(Month FROM order_date) AS month,SUM(price) AS revenue FROM order_details o
JOIN menu_items m
ON item_id = menu_item_id
GROUP BY EXTRACT(Month FROM order_date)
ORDER BY month
;

-- What is revenue per food category?
SELECT 
	category,
	SUM(price) AS revenue 
FROM menu_items m
JOIN order_details o
ON o.item_id=m.menu_item_id
GROUP BY 1
ORDER BY revenue DESC
;

-- What is the monthly revenue per food category?
SELECT 
	EXTRACT (
		Month FROM order_date) AS month,
		category,
		SUM(price) AS revenue
FROM menu_items m
JOIN order_details o
ON 
	m.menu_item_id = o.item_id
GROUP BY EXTRACT 
		(Month FROM order_date),
		category
ORDER BY 
		month,
		revenue DESC
;

-- What is each food category's percentage of total revenue?
WITH cat_rev as (
		SELECT 
			category,
			SUM(price) AS category_revenue 
		FROM menu_items m
		JOIN order_details o
		ON o.item_id=m.menu_item_id
		GROUP BY 1),
total_rev AS (
		SELECT 
			category,
			category_revenue,
			SUM(category_revenue) OVER () AS total_revenue
		FROM cat_rev)
SELECT 
	category, 
	ROUND((category_revenue/total_revenue*100),2) AS percentage
FROM total_rev
ORDER BY percentage DESC
;

-- What is each item's percentage within each category by total revenue?
WITH ite_rev AS 
		(SELECT 
			category,
			item_name,
			SUM(price) AS item_revenue
		FROM order_details o
		JOIN menu_items m
			ON o.item_id = m.menu_item_id
		GROUP BY 1,2),
	cat_rev AS
		(SELECT 
			category,
			item_name,
			item_revenue,
			SUM(item_revenue) OVER(PARTITION BY category) AS category_revenue
		FROM ite_rev),
	total_rev AS 
		(SELECT 
			category,
			item_name,
			item_revenue, 
			category_revenue,
			SUM(item_revenue) OVER() AS total_revenue
		FROM cat_rev)
SELECT 
	category,
	item_name,
	ROUND((item_revenue/total_revenue*100),2) AS percentage 
FROM total_rev
ORDER BY category,percentage DESC
;

-- What day of the week with the highest and lowest total sales?
WITH total_dow_sales AS (
			SELECT 
				TO_CHAR(order_date, 'Day') AS day_of_the_week,
				SUM(price) AS total_sales
			FROM order_details o
			JOIN menu_items m
				ON o.item_id = m.menu_item_id
			GROUP BY TO_CHAR(order_date, 'Day')),
	rank_day_sales AS (
			SELECT 
				day_of_the_week,
				total_sales, 
				RANK() OVER(ORDER BY total_sales DESC) AS rnk
			FROM total_dow_sales)
SELECT 
	day_of_the_week,
	total_sales 
FROM rank_day_sales
WHERE rnk = 1
;

WITH total_dow_sales AS (
			SELECT 
				TO_CHAR(order_date, 'Day') AS day_of_the_week,
				SUM(price) AS total_sales
			FROM order_details o
			JOIN menu_items m
				ON o.item_id = m.menu_item_id
			GROUP BY TO_CHAR(order_date, 'Day')),
	rank_day_sales AS (
			SELECT 
				day_of_the_week,
				total_sales, 
				RANK() OVER(ORDER BY total_sales) AS rnk
			FROM total_dow_sales)
SELECT 
	day_of_the_week,
	total_sales 
FROM rank_day_sales
WHERE rnk = 1
;

-- Find the busiest and off-peak hours of the day.
SELECT 
	EXTRACT(HOUR FROM order_time) AS hour,
	COUNT(order_id) AS number_of_orders
FROM order_details
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY number_of_orders DESC
;

SELECT 
	EXTRACT(HOUR FROM order_time) AS hour,
	COUNT(order_id) AS number_of_orders
FROM order_details
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY number_of_orders
;

-- Which food category had the highest number of items sold each month?
SELECT month, 
	   category, 
	   item_counts 
FROM (
		SELECT 
			EXTRACT 
				(
				Month FROM order_date) AS month,
				category,COUNT(item_id) AS item_counts,
				ROW_NUMBER() OVER (ORDER BY COUNT(item_id) DESC) AS RANK
		FROM order_details o
		JOIN menu_items
		ON item_id=menu_item_id
			WHERE EXTRACT (
			Month FROM order_date) = 1
		GROUP BY 1,2	
	UNION
		SELECT 
			EXTRACT 
				(
				Month FROM order_date) AS month,
				category,
				COUNT(item_id) AS item_counts,
				ROW_NUMBER() OVER (ORDER BY COUNT(item_id)DESC) AS RANK
		FROM order_details o
		JOIN menu_items
		ON item_id=menu_item_id
		WHERE 
			EXTRACT (
			Month FROM order_date) = 2
		GROUP BY 1,2		
	UNION
		SELECT 
			EXTRACT 
				(
				Month FROM order_date) AS month,
				category,COUNT(item_id) AS item_counts,
				ROW_NUMBER() OVER (ORDER BY COUNT(item_id)DESC) AS RANK
		FROM order_details o
		JOIN menu_items
		ON item_id=menu_item_id
		WHERE 
			EXTRACT (
			Month FROM order_date) = 3
		GROUP BY 1,2
	) AS items_sold_monthly
WHERE rank=1

-- This was run through Claude. I asked it if there is alternative query. I never thought about this one.
SELECT month, category, item_counts
FROM (
    SELECT
        EXTRACT(MONTH FROM o.order_date) AS month,
        m.category,
        COUNT(o.item_id) AS item_counts,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(MONTH FROM o.order_date)
            ORDER BY COUNT(o.item_id) DESC
        ) AS rnk
    FROM order_details o
    JOIN menu_items m
        ON o.item_id = m.menu_item_id
    GROUP BY 1, 2
) AS items_sold_monthly
WHERE rnk = 1
ORDER BY month;

-- How many orders were there per month?
SELECT 
	EXTRACT (
		Month FROM order_date) AS month,
	COUNT (
		DISTINCT(order_id)) AS number_of_orders
FROM order_details
GROUP BY EXTRACT(Month FROM order_date)
;

-- Find the number of items ordered per category.

SELECT 
	category,
	COUNT(item_id) item_count
FROM order_details o
JOIN menu_items m
	ON o.item_id = m.menu_item_id
GROUP BY 1
ORDER BY item_count DESC
;

-- What is the average item price for each food category? Order them from highest average price to lowest.
SELECT 
	category, 
	ROUND(AVG(price),2) AS avg_price
FROM menu_items
GROUP BY category
ORDER BY avg_price DESC;

-- What are the most and least expensive items on the menu? Limit to 5.
SELECT 
	item_name,
	price 
FROM menu_items i
WHERE 
	EXISTS 
		(SELECT 
			price AS price 
		FROM menu_items m
		WHERE m.item_name = i.item_name
		) 
ORDER BY price DESC
LIMIT 5;

SELECT 
	item_name,
	price 
FROM menu_items i
WHERE 
	EXISTS 
		(SELECT 
			price AS price 
		FROM menu_items m
		WHERE m.item_name = i.item_name
		) 
ORDER BY price 
LIMIT 5
;

-- What are the item names of the most and least frequently ordered item? Limit to 5.
SELECT 
	item_name,
	COUNT (item_id) AS item_count 
FROM order_details o
LEFT JOIN menu_items m
	ON o.item_id = m.menu_item_id
GROUP BY item_name
ORDER BY item_count DESC
LIMIT 5
;

SELECT 
	item_name,
	COUNT (item_id) AS item_count 
FROM order_details o
RIGHT JOIN menu_items m
	ON o.item_id = m.menu_item_id
GROUP BY item_name,
ORDER BY item_count 
LIMIT 5
;





