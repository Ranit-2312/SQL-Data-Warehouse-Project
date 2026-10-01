CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
	silver_start_time TIMESTAMP;
    silver_end_time TIMESTAMP;
    silver_duration_sec NUMERIC;

    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_sec NUMERIC;
BEGIN
	silver_start_time := clock_timestamp();
	RAISE NOTICE '=============================================';
	RAISE NOTICE 'LOADING SILVER LAYER';
	RAISE NOTICE '=============================================';

	-- ===============================================
	-- CRM TABLES
	-- ===============================================

	RAISE NOTICE '=============================================';
	RAISE NOTICE 'LOADING CRM TABLES...';
	RAISE NOTICE '=============================================';

	-- ============================================
		
	-- writing the script for the silver.crm_cust_info
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;

	-- 2. copying data from the bronze layer
	RAISE NOTICE '>>Inserting data into : silver.crm_cust_info';
	INSERT INTO silver.crm_cust_info(
			cst_id ,
			cst_key	,
			cst_firstname ,
			cst_lastname ,
			cst_marital_status ,
			cst_gndr ,
			cst_create_date
		) 
		SELECT  
			cst_id ,
			cst_key	,
			TRIM(cst_firstname) AS cst_firstname ,
			TRIM(cst_lastname) AS cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END AS cst_marital_status ,
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				ELSE 'n/a'
			END AS cst_gndr,
			cst_create_date 
		FROM (
			SELECT *, 
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Last_load
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)t WHERE last_load=1;

	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;

	-- ============================================
	
	-- writing the script for the silver.crm_prd_info
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;

	-- 2. copying data from the bronze layer
	RAISE NOTICE '>>Inserting data into : silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info(
			prd_id ,
			cat_id ,
			prd_key ,
			prd_nm ,
			prd_cost ,
			prd_line ,
			prd_start_dt ,
			prd_end_dt
		)
		SELECT prd_id ,
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
			SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
			prd_nm ,
			COALESCE(prd_cost,0) AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a' 
			END AS prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(
				(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt ASC) - INTERVAL '1 day') 
			AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info;

	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;

	-- ============================================
	
	-- writing the script for the silver.crm_sales_details
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;

	-- 2. copying data from the bronze layer
	RAISE NOTICE '>>Inserting data into : silver.crm_sales_details';		
	INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id	,
			sls_order_dt ,
			sls_ship_dt	,
			sls_due_dt ,
			sls_sales ,
			sls_quantity ,
			sls_price
		)
		SELECT sls_ord_num,
			sls_prd_key,
			sls_cust_id	,
			CASE
				WHEN sls_order_dt <=0 OR LENGTH(CAST(sls_order_dt AS TEXT))!= 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
			END AS sls_order_dt,
			CASE
				WHEN sls_ship_dt <=0 OR LENGTH(CAST(sls_ship_dt AS TEXT))!= 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
			END AS sls_ship_dt,
			CASE
				WHEN sls_due_dt <=0 OR LENGTH(CAST(sls_due_dt AS TEXT))!= 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
			END AS sls_due_dt ,
			CASE
				WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN  sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales ,
			sls_quantity ,
			CASE
				WHEN sls_price IS NULL OR sls_price<=0 THEN sls_sales / NULLIF(sls_quantity,0)
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details;

	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
		
	-- ===============================================
	-- ERP TABLES
	-- ===============================================

	RAISE NOTICE '=============================================';
	RAISE NOTICE 'LOADING ERP TABLES...';
	RAISE NOTICE '=============================================';

	-- writing the script for the silver.erp_cust_az12
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	
	-- 2. copying data from the bronze layer
	RAISE NOTICE '>>Inserting data into : silver.erp_cust_az12';	
	INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT 
			CASE 
				WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid)) 
				ELSE cid
			END AS cid,
			CASE 
				WHEN bdate>CURRENT_DATE THEN NULL
				ELSE bdate END
			AS bdate,
			CASE 
				WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
				WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
				ELSE 'n/a'
			END AS gen
			FROM bronze.erp_cust_az12;

	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;

	-- ============================================
		
	-- writing the script for the silver.erp_loc_a101
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;

	-- 2. copying data from the bronze layer
	RAISE NOTICE '>>Inserting data into : silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101(cid,cntry)
		SELECT 
			REPLACE(cid,'-','') AS cid,
			CASE 
				WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
				WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
				WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'n/a'
				ELSE cntry
			END AS cntry
		FROM bronze.erp_loc_a101;

	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
		
	-- ============================================
		
	-- writing the script for the silver.erp_px_cat_g1v2
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : silver.erp_px_cat_g1v2';	
	TRUNCATE TABLE silver.erp_px_cat_g1v2;

	-- 2. copying data from the bronze layer
	RAISE NOTICE '>>Inserting data into : silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
		SELECT * FROM bronze.erp_px_cat_g1v2;

	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;

	-- ============================================
		
	RAISE NOTICE '=============================================';
	RAISE NOTICE 'All data insertion has done successfully';
	RAISE NOTICE '=============================================';

	silver_end_time := clock_timestamp();
    silver_duration_sec := ROUND(EXTRACT(EPOCH FROM (silver_end_time - silver_start_time))::numeric, 2);
	RAISE NOTICE 'Time taken to load bronze layer: % seconds', silver_duration_sec;

	EXCEPTION
    -- =============================================
    -- THE "CATCH" BLOCK
    -- This executes only if an error occurs above
    -- =============================================
    WHEN OTHERS THEN
        -- SQLSTATE contains the error code
        -- SQLERRM contains the detailed error message
        RAISE EXCEPTION 'Failed to load silver layer. Error %: %', SQLSTATE, SQLERRM;

END;
$$;
		
