/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	Declare @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	BEGIN TRY
		
		SET @batch_start_time = GETDATE();

		PRINT '=====================';
		PRINT 'Loading Silver Layer';
		PRINT '=====================';

		PRINT '--------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------';

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting Data Into: Table silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date)
		SELECT
			cst_id,
			cst_key,
			trim(cst_firstname) cst_firstname,
			trim(cst_lastname) cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
				END cst_marital_status,
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				ELSE 'n/a'
				END cs_gndr,
			cst_create_date
		FROM
		(
		SELECT 
			*,
			ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
		FROM bronze.crm_cust_info
		)t
		WHERE flag_last = 1 AND cst_id IS NOT NULL
		SET @end_time = GETDATE();
		PRINT'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SECONDS';
		print '------------------'

		SET @start_time = GETDATE()
		PRINT'>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info
		PRINT '>> Inserting Data Into: Table silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') cat_id,
			SUBSTRING(prd_key, 7, len(prd_key)) prd_key,
			prd_nm,
			ISNULL(prd_cost, 0) prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sale'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
				END prd_line,
			prd_start_dt,
			DATEADD(DAY, -1 ,LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt))prd_end_dt
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SECONDS';
		print '------------------'
		
		SET @start_time = GETDATE();
		PRINT'>> Truncating Table:	silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details
		PRINT '>> Inserting Data Into: Table silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details
		(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales ,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE
				WHEN sls_order_dt = 0 THEN NULL
				WHEN LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(sls_order_dt AS DATE)
				END sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			CASE
				WHEN sls_sales <= 0 OR sls_sales IS NULL
				THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
				END sls_sales,
			sls_quantity,
			CASE
				WHEN sls_price <= 0 OR sls_price IS NULL
				THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price
				END sls_price
		FROM bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SECONDS';
		print '------------------'
		
		PRINT '--------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------';


		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12
		PRINT '>> Inserting Data Into: Table silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12
		(
			cid,
			bdate,
			gen
		)
		SELECT
			CASE
				WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
				ELSE CID
				END cid,
			CASE
				WHEN BDATE > GETDATE() THEN NULL
				ELSE BDATE
				END bdate,
			CASE
				WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
				END gen
		FROM bronze.erp_cust_az12
		SET @end_time = GETDATE();
		PRINT'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SECONDS';
		print '------------------'
		

		SET @start_time = GETDATE()
		PRINT'>> Truncating Table: silver.erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101
		PRINT '>> Inserting Data Into: Table silver.erp_loc_a101'
		INSERT INTO silver.erp_loc_a101
		(
			cid,
			cntry
		)
		SELECT
			REPLACE(CID, '-', '') cid,
			CASE 
			WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
			WHEN TRIM(CNTRY) in ('US', 'USA') THEN 'United States'
			WHEN TRIM(CNTRY) = ' ' OR TRIM(CNTRY) IS NULL THEN 'n/a'
			ELSE TRIM(CNTRY)
			END cntry
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' SECONDS';
		print '------------------'

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: silver.erp_prd_az12';
		TRUNCATE TABLE silver.erp_px_cat_g1v2
		PRINT '>> Inserting Data Into: Table silver.erp_prd_az12';
		INSERT INTO silver.erp_px_cat_g1v2
		(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2
		
		SET @batch_end_time = GETDATE();
		PRINT 'Loading Silver Layer Is Completed'
		PRINT '    - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR);
	END TRY
	BEGIN CATCH
	PRINT '=================================================';
			PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
			PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
			PRINT 'ERROR NUMBER' + CAST (ERROR_NUMBER() AS NVARCHAR);
			PRINT 'ERROR MESSAGE' + CAST (ERROR_STATE() AS NVARCHAR);
			PRINT '=================================================';
	END CATCH
END

EXEC SILVER.load_silver
