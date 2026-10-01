-- Table : crm_cust_info(Bronze to Silver)
-- =========================================

-- =========================================
-- Before inserting values into silver layer
-- =========================================

-- check null values in the primary keys
select count(*) from bronze.crm_cust_info WHERE cst_id ISNULL;

-- check duplicate entries in the primary keys
select cst_id,count(*) from bronze.crm_cust_info
group by cst_id HAVING count(*)>1;

-- removing duplicate records
select * from(
	select *, 
	row_number() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) as Last_load
	from bronze.crm_cust_info
)t where last_load=1;

-- check for unwanted spaces
SELECT cst_firstname FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_gndr FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

SELECT cst_marital_status FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

-- data standardization and consistency
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;

SELECT 	CASE 
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		ELSE 'n/a'
	END AS cst_gndr FROM bronze.crm_cust_info;

select * from bronze.crm_cust_info where cst_id isnull;

-- =========================================
-- After inserting values into silver layer
-- =========================================

-- check null values in the primary keys
select * from silver.crm_cust_info WHERE cst_id ISNULL;

-- check duplicate entries in the primary keys
select cst_id,count(*) from silver.crm_cust_info
group by cst_id HAVING count(*)>1;

-- check for unwanted spaces
SELECT cst_firstname FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Table : crm_prd_info(Bronze to Silver)
-- =========================================

-- =========================================
-- Before inserting values into silver layer
-- =========================================

select * from bronze.crm_prd_info;
 -- defining category id as cat_id
SELECT prd_id ,
	SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
	prd_nm ,
	COALESCE(prd_cost,0) AS prd_cost,
	CASE UPPER(TRIM(prd_line))
		WHEN 'M' THEN 'Mountain'
		WHEN 'R' THEN 'Road'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		ELSE 'n/a' 
	END AS prd_line,
	prd_start_dt ,
	prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key,7,LENGTH(prd_key)) IN (
	SELECT sls_prd_key FROM bronze.crm_sales_details
);

-- CHECK UNWANTED SPACES IN prd_nm
select prd_nm from bronze.crm_prd_info where prd_nm != TRIM(prd_nm);

-- check for NULL or negative COLUMNS
SELECT prd_cost FROM bronze.crm_prd_info WHERE prd_cost<0 OR prd_cost ISNULL;

-- data standardization and consistency
SELECT DISTINCT(prd_line) FROM bronze.crm_prd_info;

-- CHECK FOR INVALID DATE ORDER
SELECT * FROM bronze.crm_prd_info WHERE prd_start_dt>prd_end_dt;

-- correction of dates 
SELECT prd_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    CAST(prd_start_dt AS DATE),
    prd_end_dt,
    CAST((LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt ASC) - INTERVAL '1 day') AS DATE) AS next_dt
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');

-- =========================================
-- After inserting values into silver layer
-- =========================================
-- check for NULL or negative COLUMNS
SELECT prd_cost FROM silver.crm_prd_info WHERE prd_cost<0 OR prd_cost ISNULL;

-- data standardization and consistency
SELECT DISTINCT(prd_line) FROM silver.crm_prd_info;

-- CHECK FOR INVALID DATE ORDER
SELECT * FROM silver.crm_prd_info WHERE prd_start_dt>prd_end_dt;

SELECT * FROM silver.crm_prd_info;

-- Table : crm_sales_details(Bronze to Silver)
-- ===========================================

-- ===========================================
-- Before inserting values into silver layer
-- ===========================================
-- checking missing values
SELECT sls_ord_num,
	sls_prd_key,
	sls_cust_id	,
	sls_order_dt ,
	sls_ship_dt	,
	sls_due_dt ,
	sls_sales ,
	sls_quantity ,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- check for invalid dates
SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt<=0 OR LENGTH(CAST(sls_order_dt AS TEXT))!=8;

-- date out of range checking
SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt<19500101 OR sls_order_dt>20500101;

-- null dates checking
SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt IS NULL;

-- check for invalid dates
SELECT sls_ship_dt FROM bronze.crm_sales_details
WHERE sls_ship_dt<=0 OR LENGTH(CAST(sls_ship_dt AS TEXT))!=8;

-- date out of range checking
SELECT sls_ship_dt FROM bronze.crm_sales_details
WHERE sls_ship_dt<19500101 OR sls_ship_dt>20500101;

-- null dates checking
SELECT sls_ship_dt FROM bronze.crm_sales_details
WHERE sls_ship_dt IS NULL;

-- check for invalid dates
SELECT sls_due_dt FROM bronze.crm_sales_details
WHERE sls_due_dt<=0 OR LENGTH(CAST(sls_due_dt AS TEXT))!=8;

-- date out of range checking
SELECT sls_due_dt FROM bronze.crm_sales_details
WHERE sls_due_dt<19500101 OR sls_due_dt>20500101;

-- null dates checking
SELECT sls_due_dt FROM bronze.crm_sales_details
WHERE sls_due_dt IS NULL;

-- check for invalid date orders between order date and shipping or due date
SELECT * FROM bronze.crm_sales_details WHERE 
sls_order_dt>sls_ship_dt or sls_order_dt>sls_due_dt;

-- check data consistency among the sales, quantity and price COLUMNS and fix alongside
-- formula of sales = quantity * price
-- null, negative and zeros are not allowed
SELECT DISTINCT sls_sales AS old_sales, sls_quantity, sls_price AS old_price,
CASE
	WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN  sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS new_sales,
CASE
	WHEN sls_price IS NULL OR sls_price<=0 THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END AS new_sls_price
	
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_sales<=0
OR sls_quantity IS NULL OR sls_quantity<=0
OR sls_price IS NULL OR sls_price<=0;

-- =========================================
-- After inserting values into silver layer
-- =========================================

select * from silver.crm_sales_details;

-- null dates checking
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL;

-- null dates checking
SELECT sls_ship_dt FROM silver.crm_sales_details
WHERE sls_ship_dt IS NULL;

-- null dates checking
SELECT sls_due_dt FROM silver.crm_sales_details
WHERE sls_due_dt IS NULL;

-- check for invalid date orders between order date and shipping or due date
SELECT * FROM silver.crm_sales_details WHERE 
sls_order_dt>sls_ship_dt or sls_order_dt>sls_due_dt;

-- check data consistency among the sales, quantity and price COLUMNS and fix alongside
-- formula of sales = quantity * price
-- null, negative and zeros are not allowed

SELECT DISTINCT sls_sales ,sls_quantity, sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_sales<=0
OR sls_quantity IS NULL OR sls_quantity<=0
OR sls_price IS NULL OR sls_price<=0;

-- Table : erp_cust_az12(Bronze to Silver)
-- ===========================================

-- ===========================================
-- Before inserting values into silver layer
-- ===========================================

-- CHECK FOR EXTRA CHARACTERS IN THE cid TO JOIN WITH THE crm_cust_info TABLE
SELECT cid,bdate, gen FROM bronze.erp_cust_az12;

SELECT * FROM silver.crm_cust_info;

SELECT COUNT(*) FROM bronze.erp_cust_az12;

-- CASE WHEN EXTRA CHARACTERS ARE THERE
SELECT SUM(
	CASE
		WHEN cid LIKE 'NAS%' THEN 1 ELSE 0 END
) AS CNT FROM bronze.erp_cust_az12;

-- CASE WHEN EXTRA CHARACTERS ARE NOT THERE
SELECT SUM(
	CASE
		WHEN cid NOT LIKE 'NAS%' THEN 1 ELSE 0 END
) AS CNT FROM bronze.erp_cust_az12;

SELECT cid FROM bronze.erp_cust_az12 WHERE cid NOT LIKE 'NAS%';

-- CHECK WHETHER ALL THE cid ARE PRESENT IN THE silver.crm_cust_info TABLE
SELECT 
	CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid)) 
		ELSE cid
	END AS cid,
	bdate,
	gen
	FROM bronze.erp_cust_az12
	WHERE CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid)) 
		ELSE cid
	END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- CHECK bdate COLUMN
SELECT DISTINCT bdate FROM bronze.erp_cust_az12
WHERE bdate < '1926-01-01' OR bdate > CURRENT_DATE
ORDER BY bdate;

SELECT 
	CASE 
		WHEN bdate>CURRENT_DATE THEN NULL
		ELSE bdate END
	AS bdate FROM bronze.erp_cust_az12;

-- DATA STANDARDIZATION AND CONSISTENCY IN GENDER COLUMN
SELECT DISTINCT gen FROM bronze.erp_cust_az12
WHERE gen != TRIM(gen);

SELECT DISTINCT gen,
	CASE 
		WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
		WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
		ELSE 'n/a'
	END AS gen FROM bronze.erp_cust_az12

-- ===========================================
-- After inserting values into silver layer
-- ===========================================

-- CASE WHEN EXTRA CHARACTERS ARE THERE
SELECT SUM(
	CASE
		WHEN cid LIKE 'NAS%' THEN 1 ELSE 0 END
) AS CNT FROM silver.erp_cust_az12;

-- CASE WHEN EXTRA CHARACTERS ARE NOT THERE
SELECT SUM(
	CASE
		WHEN cid NOT LIKE 'NAS%' THEN 1 ELSE 0 END
) AS CNT FROM silver.erp_cust_az12;

-- CHECK WHETHER ALL THE cid ARE PRESENT IN THE silver.crm_cust_info TABLE
SELECT cid,bdate,gen FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- CHECK bdate COLUMN
SELECT DISTINCT bdate FROM silver.erp_cust_az12
WHERE bdate > CURRENT_DATE
ORDER BY bdate;

-- GENDER COLUMN
SELECT DISTINCT gen FROM silver.erp_cust_az12
WHERE gen != TRIM(gen);

-- Table : erp_loc_a101(Bronze to Silver)
-- ===========================================

-- ===========================================
-- Before inserting values into silver layer
-- ===========================================

-- CHECK cid COLUMN
SELECT cid,cntry FROM bronze.erp_loc_a101;

SELECT REPLACE(cid,'-','') AS cid FROM bronze.erp_loc_a101;

-- CHECK IF THE DATA IN cid ARE ALSO PRESENT IN THE silver.crm_cust_info TABLE
SELECT REPLACE(cid,'-','') AS cid FROM bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') NOT IN (
	SELECT DISTINCT cst_key FROM silver.crm_cust_info
);

-- DATA STANDARDIZATION AND CONSISTENCY IN cntry COLUMN
SELECT DISTINCT cntry FROM bronze.erp_loc_a101;

SELECT DISTINCT cntry AS old_cntry,
	CASE 
		WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
		WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'n/a'
		ELSE cntry
	END AS cntry
FROM bronze.erp_loc_a101;

-- ===========================================
-- After inserting values into silver layer
-- ===========================================

-- CHECK IF THE DATA IN cid ARE ALSO PRESENT IN THE silver.crm_cust_info TABLE
SELECT cid FROM silver.erp_loc_a101
WHERE cid NOT IN (
	SELECT DISTINCT cst_key FROM silver.crm_cust_info
);

-- DATA STANDARDIZATION AND CONSISTENCY IN cntry COLUMN
SELECT DISTINCT cntry FROM silver.erp_loc_a101;

-- Table : erp_px_cat_g1v2(Bronze to Silver)
-- ===========================================

-- ===========================================
-- Before inserting values into silver layer
-- ===========================================
SELECT id,cat,subcat,maintenance FROM bronze.erp_px_cat_g1v2;

-- CHECK IF THE DATA IN id ARE ALSO PRESENT IN THE silver.crm_prd_info TABLE
SELECT id FROM bronze.erp_px_cat_g1v2
WHERE ID NOT IN (SELECT DISTINCT cat_id FROM silver.crm_prd_info);

-- CHECK FOR UNWANTED SPACES 
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2 WHERE cat != TRIM(cat); 

SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2 WHERE subcat != TRIM(subcat); 

SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2 WHERE maintenance != TRIM(maintenance); 

-- CHECK DATA STANDARDIZATION AND CONSISTENCY
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;

-- ===========================================
-- After inserting values into silver layer
-- ===========================================

SELECT * FROM silver.erp_px_cat_g1v2;


SELECT * FROM silver.crm_sales_details;
SELECT * FROM silver.crm_prd_info;

CALL silver.load_silver();
