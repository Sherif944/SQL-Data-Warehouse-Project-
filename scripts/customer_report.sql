-- CHANGE-OVER-TIME Analysis
-- Analyze the sales performance over the time 
SELECT
	YEAR(order_date) year_date,
	SUM(sales_anmount) total_sales,
	COUNT(DISTINCT customer_key) total_customers,
	SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date) 

-- Cumulative Analysis
-- Calculate the total sales for each month 
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) Running_total_sales,
	AVG(average_price) OVER (ORDER BY order_date) Moving_Average
FROM(
	SELECT
		DATETRUNC(year, order_date) order_date,
		SUM(sales_anmount) total_sales,
		AVG(price) average_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(year, order_date))t

-- Performance Analysis
-- Analyze the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year's sale
WITH yearly_products AS(
	SELECT
		YEAR(order_date) year_date,
		p.product_name,
		sum(s.sales_anmount) current_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY
		YEAR(order_date),
		p.product_name)

SELECT
	year_date,
	product_name,
	current_sales,
	AVG(current_sales) OVER (PARTITION BY product_name) average_salesو,
	current_sales - AVG(current_sales) OVER (PARTITION BY product_name) diff_avg,
	CASE
		WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
		ELSE 'Avg'
	END avg_change,
	LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) previous_sales,
	current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) diff_year,
	CASE
		WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) > 0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year_date) < 0 THEN 'Decrease'
		ELSE 'No Change'
	END py_change
FROM yearly_products
ORDER BY product_name, year_date

-- PART-TO-WHOLE Analysis
-- Which categories contribute the most to overall sales

WITH category_sales AS(
	SELECT
		p.category,
		SUM(s.sales_anmount) AS total_category_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	GROUP BY p.category)

SELECT
	category,
	total_category_sales,
	SUM(total_category_sales) OVER () total_sales,
	CONCAT(ROUND(
	CAST(total_category_sales AS FLOAT)/ SUM(total_category_sales) OVER () *100, 2), ' ', '%') AS categories_contribution
FROM category_sales
ORDER BY categories_contribution DESC

-- Data Segmentation
-- Segment products into cost ranges and count how many products fall into each segment
WITH product_cost_segmentation AS(
	SELECT
		product_key,
		product_name,
		cost,
		CASE
			WHEN cost < 100 THEN 'Below 100'
			WHEN cost BETWEEN 100 AND 500 THEN '100 - 500'
			WHEN cost BETWEEN 500 AND 1000 THEN '500 - 1000'
			ELSE 'Above 1000'
		END cost_range
	FROM gold.dim_products)

SELECT
	cost_range,
	COUNT(product_name) total_products
FROM product_cost_segmentation
GROUP BY cost_range

-- Group customers into three segments based on their spending behaviour
-- vip at least 12 months of history and spending more than 5000
-- Regular at least 12 months of history and spending 5000 or less
-- new lifespan less than 12 months 
WITH customer_lifespan AS(
	SELECT
		DATEDIFF(MONTH, MIN(s.order_date), MAX(order_date)) lifespan,
		c.customer_key,
		CONCAT(c.first_name, ' ', c.last_name) customer_name,
		SUM(s.sales_anmount) total_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
	WHERE order_date IS NOT NULL
	GROUP BY
		c.customer_key,
		CONCAT(c.first_name, ' ', c.last_name)),

customer_segmentation AS(
	SELECT 
		customer_key,
		customer_name,
		lifespan,
		total_sales,
		CASE 
			WHEN lifespan >= 12 and total_sales > 5000 THEN 'VIP'
			WHEN lifespan >= 12 and total_sales <= 5000 THEN 'Regular'
			WHEN lifespan < 12 THEN 'New'
			ELSE 'New'
		END customer_segmentation
	FROM customer_lifespan)

SELECT
	customer_segmentation,
	count(customer_name) total_customers
FROM customer_segmentation
GROUP BY customer_segmentation
 
