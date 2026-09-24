/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL bronze.load_bronze();
===============================================================================
*/
CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
	bronze_start_time TIMESTAMP;
    bronze_end_time TIMESTAMP;
    bronze_duration_sec NUMERIC;

    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_sec NUMERIC;
BEGIN
	bronze_start_time := clock_timestamp();
	RAISE NOTICE '=============================================';
	RAISE NOTICE 'LOADING BRONZE LAYER';
	RAISE NOTICE '=============================================';
	
	-- =============================================
	-- CRM
	-- =============================================
	
	RAISE NOTICE '=============================================';
	RAISE NOTICE 'LOADING CRM TABLES...';
	RAISE NOTICE '=============================================';	
	
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : bronze.crm_cust_info';
	TRUNCATE TABLE bronze.crm_cust_info;
	
	-- 2. copying data from the csv file
	RAISE NOTICE '>>Inserting data into : bronze.crm_cust_info';
	COPY bronze.crm_cust_info 
	FROM 'D:\postgres practice\postgre data warehouse project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv' 
	WITH (
	    FORMAT csv, 
	    HEADER true, 
	    DELIMITER ','
	);
	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
	
	-- ============================================
	
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : bronze.crm_prd_info';
	TRUNCATE TABLE bronze.crm_prd_info;
	
	-- 2. copying data from the csv file
	RAISE NOTICE '>>Inserting data into : bronze.crm_prd_info';
	COPY bronze.crm_prd_info 
	FROM 'D:\postgres practice\postgre data warehouse project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv' 
	WITH (
	    FORMAT csv, 
	    HEADER true, 
	    DELIMITER ','
	);
	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
	
	-- ============================================
	
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : bronze.crm_sales_details';
	TRUNCATE TABLE bronze.crm_sales_details;
	
	-- 2. copying data from the csv file
	RAISE NOTICE '>>Inserting data into : bronze.crm_sales_details';
	COPY bronze.crm_sales_details
	FROM 'D:\postgres practice\postgre data warehouse project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv' 
	WITH (
	    FORMAT csv, 
	    HEADER true, 
	    DELIMITER ','
	);
	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
	
	-- =============================================
	-- ERP
	-- =============================================

	RAISE NOTICE '=============================================';
	RAISE NOTICE 'LOADING ERP TABLES...';
	RAISE NOTICE '=============================================';
	
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : bronze.erp_cust_az12';
	TRUNCATE TABLE bronze.erp_cust_az12;
	
	-- 2. copying data from the csv file
	RAISE NOTICE '>>Inserting data into : bronze.erp_cust_az12';
	COPY bronze.erp_cust_az12
	FROM 'D:\postgres practice\postgre data warehouse project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv' 
	WITH (
	    FORMAT csv, 
	    HEADER true, 
	    DELIMITER ','
	);
	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
	
	-- ============================================
	
	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : bronze.erp_loc_a101';
	TRUNCATE TABLE bronze.erp_loc_a101;
	
	-- 2. copying data from the csv file
	RAISE NOTICE '>>Inserting data into : bronze.erp_loc_a101';
	COPY bronze.erp_loc_a101
	FROM 'D:\postgres practice\postgre data warehouse project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv' 
	WITH (
	    FORMAT csv, 
	    HEADER true, 
	    DELIMITER ','
	);
	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
	
	-- ============================================

	-- 1. Empty the existing table
	start_time := clock_timestamp();
	RAISE NOTICE '>>Truncating table : bronze.erp_px_cat_g1v2';
	TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	
	-- 2. copying data from the csv file
	RAISE NOTICE '>>Inserting data into : bronze.erp_px_cat_g1v2';
	COPY bronze.erp_px_cat_g1v2
	FROM 'D:\postgres practice\postgre data warehouse project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv' 
	WITH (
	    FORMAT csv, 
	    HEADER true, 
	    DELIMITER ','
	);
	end_time := clock_timestamp();
    duration_sec := ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
	RAISE NOTICE 'Time taken: % seconds', duration_sec;
	
	RAISE NOTICE '=============================================';
	RAISE NOTICE 'All data insertion has done successfully';
	RAISE NOTICE '=============================================';

	bronze_end_time := clock_timestamp();
    bronze_duration_sec := ROUND(EXTRACT(EPOCH FROM (bronze_end_time - bronze_start_time))::numeric, 2);
	RAISE NOTICE 'Time taken to load bronze layer: % seconds', bronze_duration_sec;

	EXCEPTION
    -- =============================================
    -- THE "CATCH" BLOCK
    -- This executes only if an error occurs above
    -- =============================================
    WHEN OTHERS THEN
        -- SQLSTATE contains the error code
        -- SQLERRM contains the detailed error message
        RAISE EXCEPTION 'Failed to load bronze layer. Error %: %', SQLSTATE, SQLERRM;
	
END;
$$;
