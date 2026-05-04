-- Exploratory data analysis: Tables Exploration

SELECT * FROM information_schema.tables


-- Exploratory data analysis: Columns Exploration

SELECT * FROM information_schema.columns
WHERE TABLE_NAME = 'dim_customers'

-- Dimension Exploration 

SELECT DISTINCT
	country
FROM gold.dim_customers

SELECT DISTINCT
	category,
	sub_category,
	product_name
FROM gold.dim_products
ORDER BY 1,2,3

-- Dates Exploration

SELECT
	MIN(order_date) first_order_date,
	MAX(order_date) last_order_date,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) order_range_months
FROM gold.fact_sales

-- Find the youngest and oldest customers

SELECT
	MIN(birthdate) as olrd_customers,
	MAX(birthdate) as young_customers,
	DATEDIFF(YEAR, MIN(birthdate), GETDATE()) Oldest_age
FROM gold.dim_customers

-- Measure Exploration
-- Find total sales
SELECT
	SUM(SALES_ANMOUNT) total_sales
FROM gold.fact_sales

-- Find how many items are sold
SELECT
	SUM(quantity) total_items_sold
FROM gold.fact_sales

-- Find the average of selling price
SELECT
	AVG(price) average_price
FROM gold.fact_sales

-- Find the total number of orders
SELECT
	COUNT(order_number) total_orders
FROM gold.fact_sales

SELECT
	COUNT(DISTINCT order_number) total_unique_orders
FROM gold.fact_sales

-- Find the total number of products
SELECT
	COUNT(product_key) total_products
FROM gold.dim_products

SELECT
	COUNT(DISTINCT product_key) total_unique_products
FROM gold.dim_products

-- Find the total number of customers
SELECT
	COUNT(customer_key) total_customers
FROM gold.dim_customers

SELECT
	COUNT(DISTINCT customer_key) total_unique_customers
FROM gold.dim_customers

-- Find the total number of customers that has placed an order

SELECT
	COUNT(DISTINCT customer_key) total_csutomers_ordered
FROM gold.fact_sales


-- Generate a report that shows all the key metrics of the business 

SELECT
	'Total Sales' AS Measure_name,
	SUM(sales_anmount) AS Measure_value
FROM gold.fact_sales
UNION ALL
SELECT
	'Total Quantity' AS Measure_name,
	SUM(quantity) AS Measure_value
FROM gold.fact_sales
UNION ALL
SELECT
	'Average Price' AS Measure_name,
	AVG(Price) AS Measure_value
FROM gold.fact_sales
UNION ALL
SELECT
	'Total Nr Orders' AS Measure_name,
	COUNT(order_number) AS Measure_value
FROM gold.fact_sales
UNION ALL
SELECT
	'Total Nr Products' AS Measure_name,
	COUNT(product_key) AS Measure_value
FROM gold.dim_products
UNION ALL
SELECT
	'Total Ne Customers' AS Measure_name,
	COUNT(customer_key) AS Measure_value
FROM gold.dim_customers







