/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ==================================================
-- CHECK BEFORE INSERTING INTO THE gold.dim_customers
-- ==================================================

-- check duplicate info after joining the tables

SELECT cst_id,COUNT(*) FROM
	(SELECT 
		ci.cst_id ,
		ci.cst_key	,
		ci.cst_firstname ,
		ci.cst_lastname ,
		ci.cst_marital_status ,
		ci.cst_gndr ,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid)t 
GROUP BY cst_id HAVING COUNT(*)>1;

-- check the gender columns of the TABLE
SELECT DISTINCT 
	ci.cst_gndr ,
	ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid;

-- the master is the CRM table here, 
-- so if any mismatch occurs, then the final decision of the result would be taken from the CRM tables
SELECT DISTINCT 
	ci.cst_gndr ,
	ca.gen,
	CASE 
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		ELSE COALESCE(ca.gen,'n/a')
	END
	AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid;

-- after insertion, check the quality of the DATA
SELECT * FROM gold.dim_customers;

-- check the gender
SELECT DISTINCT gender FROM gold.dim_customers;

-- ==================================================
-- CHECK BEFORE INSERTING INTO THE gold.dim_product
-- ==================================================

-- EXTRACT THE ONGOING PRODUCT INFORMATION
SELECT
	pi.prd_id ,
	pi.cat_id ,
	pi.prd_key ,
	pi.prd_nm ,
	pi.prd_cost ,
	pi.prd_line ,
	pi.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pi
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pi.cat_id = pc.id
WHERE pi.prd_end_dt ISNULL;

-- check the distinctness of the extracted DATA
SELECT DISTINCT prd_key,COUNT(*) FROM (
	SELECT
	pi.prd_id ,
	pi.prd_key ,
	pi.prd_nm ,
	pi.cat_id ,
	pc.cat,
	pc.subcat,
	pi.prd_cost ,
	pi.prd_line ,
	pi.prd_start_dt,
	pc.maintenance
FROM silver.crm_prd_info pi
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pi.cat_id = pc.id
WHERE pi.prd_end_dt ISNULL
)T GROUP BY prd_key HAVING COUNT(*)>1;

-- check after creation
SELECT * FROM gold.dim_product;

-- ==================================================
-- CHECK BEFORE INSERTING INTO THE gold.fact_sales
-- ==================================================
SELECT 
	sd.sls_ord_num,
	ci.customer_key,
	pi.product_key,
	sd.sls_prd_key,
	sd.sls_cust_id	,
	sd.sls_order_dt ,
	sd.sls_ship_dt	,
	sd.sls_due_dt ,
	sd.sls_sales ,
	sd.sls_quantity ,
	sd.sls_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customers ci 
ON sd.sls_cust_id = ci.customer_id
LEFT JOIN gold.dim_product pi
ON sd.sls_prd_key = pi.product_number;

-- check after insertion
SELECT * FROM gold.fact_sales;

-- check foreign key integrity
SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_product p
ON p.product_key = f.product_key
WHERE p.product_key ISNULL;
