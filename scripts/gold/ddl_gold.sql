/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema).

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

PRINT'=====================================';
PRINT'Create Dimenstion: gold.dim_customers';
PRINT'=====================================';

IF OBJECT_ID ('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers
GO
CREATE VIEW [gold].[dim_customers] AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.[cst_id] AS customer_id,
	ci.[cst_key] AS customer_number,
	ci.[cst_firstname] AS first_name,
	ci.[cst_lastname] AS last_name,
	la.[cntry] AS country,
	ci.[cst_marital_status] AS marital_status,
	CASE
		WHEN ci.[cst_gndr] != 'n/a' THEN ci.[cst_gndr]
		ELSE ca.[gen]
		END gender,
	ca.[bdate] AS birthdate,
	ci.[cst_create_date] AS create_date
FROM [silver].[crm_cust_info] ci
LEFT JOIN [silver].[erp_cust_az12] ca
ON		  ci.cst_key = ca.cid
LEFT JOIN [silver].[erp_loc_a101] la
ON		  ci.cst_key = la.cid
GO


PRINT'=====================================';
PRINT'Create Dimenstion: gold.dim_products';
PRINT'=====================================';

IF OBJECT_ID ('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products
GO
CREATE VIEW [gold].[dim_products] AS
SELECT
	ROW_NUMBER() OVER (ORDER BY prd_start_dt, pn.prd_key) product_key,
	pn.[prd_id] product_id,
	pn.[prd_key] product_number,
	pn.[prd_nm] product_name,
	pn.[cat_id] category_id,
	pc.[cat] category,
	pc.[subcat] sub_category,
	pc.[maintenance],
	pn.[prd_cost] cost,
	pn.[prd_line] product_line,
	pn.[prd_start_dt] start_date 	
FROM [silver].[crm_prd_info] pn
LEFT JOIN [silver].[erp_px_cat_g1v2] PC
ON pn.cat_id = pc.id
WHERE [prd_end_dt] IS NULL
GO


PRINT'============================';
PRINT'Create Fact: gold.fact_sales';
PRINT'============================';

IF OBJECT_ID ('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales
GO
CREATE VIEW [gold].[fact_sales] AS
SELECT
	sa.[sls_ord_num] order_number,
	pr.product_key product_key,
	cu.customer_key customer_key,
	sa.[sls_order_dt] order_date,
	sa.[sls_ship_dt] shipping_date,
	sa.[sls_due_dt] due_date,
	sa.[sls_sales] sales_anmount,
	sa.[sls_quantity] quantity,
	sa.[sls_price] price
FROM [silver].[crm_sales_details] sa
LEFT JOIN gold.dim_customers cu
ON sa.sls_cust_id = cu.customer_id
LEFT JOIN gold.dim_products pr
ON sa.sls_prd_key = pr.product_number
GO


