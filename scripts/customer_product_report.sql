/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors.

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
===============================================================================
*/
IF OBJECT_ID ('gold.report_customer', 'V') IS NOT NULL
    DROP VIEW gold.report_customer
GO
CREATE VIEW gold.report_customer AS 
WITH base_query AS(
    SELECT
        CONCAT(c.first_name, ' ', c.last_name) customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) customer_age,
        MAX(order_date) last_order_date,
        COUNT(DISTINCT s.order_number) total_orders,
        SUM(s.sales_anmount) total_sales,
        SUM(s.quantity) total_quantity,
        DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) life_span
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c
    ON s.customer_key = c.customer_key
    WHERE s.order_date IS NOT NULL
    GROUP BY 
        CONCAT(c.first_name, ' ', c.last_name),
        DATEDIFF(YEAR, c.birthdate, GETDATE()))

SELECT
    *,
    CASE 
        WHEN life_span > 12 and total_sales > 5000 THEN 'VIP'
        WHEN life_span > 12 and total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END customer_segmentation,
    CASE   
        WHEN customer_age < 20 THEN 'Under 20'
        WHEN customer_age between 20 and 29 THEN '20-29'
        WHEN customer_age between 30 and 39 THEN '30-39'
        WHEN customer_age between 40 and 49 THEN '40-49'
        ELSE '50 and Above'
    END age_group,
     DATEDIFF(MONTH, last_order_date, GETDATE()) customer_recency,
    ROUND(CAST(total_sales AS FLOAT)/ NULLIF(total_orders, 0), 2) AOV,
    ROUND(CAST(total_sales AS FLOAT) / NULLIF(life_span, 0), 2) average_monthly_spend
FROM base_query


/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
===============================================================================
*/
IF OBJECT_ID ('gold.report_product', 'V') IS NOT NULL
    DROP VIEW gold.report_product
GO
CREATE VIEW gold.report_product AS
WITH base_query AS(
    SELECT
        p.product_key,
        p.product_name,
        p.category,
        p.sub_category,
        p.cost,
        MAX(s.order_date) last_order_date,
        COUNT(DISTINCT s.order_number) total_orders,
        SUM(s.sales_anmount) total_sales,
        SUM(s.quantity) total_quantity,
        COUNT(s.customer_key) total_customers,
        DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) life_span
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
    ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL
    GROUP BY
        p.product_key,
        p.product_name,
        p.category,
        p.sub_category,
        p.cost)

SELECT
    *,
    CASE
        WHEN total_sales > 50000 THEN 'High Performance'
        WHEN total_sales >=10000 THEN 'Mid Range'
        ELSE 'Low Performer'
    END product_segment,
    DATEDIFF(MONTH, last_order_date, GETDATE()) recency,
    ROUND(CAST(total_sales AS FLOAT) / NULLIF(total_orders, 0), 2) AOV,
    CAST(total_sales AS FLOAT) / NULLIF(life_span, 0) average_monthly_Revenue
FROM base_query
