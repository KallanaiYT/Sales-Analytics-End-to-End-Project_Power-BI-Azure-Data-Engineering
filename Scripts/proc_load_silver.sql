/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    /* ============================
       CRM Customer Info
       ============================ */
    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname)  AS cst_lastname,
        CASE
            WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
            WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS cst_marital_status,
        CASE
            WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
            WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS cst_gndr,
        TRY_CONVERT(date, cst_create_date) AS cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS table_sort
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE table_sort = 1;


    /* ============================
       CRM Product Info
       ============================ */
    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id, 
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,      -- Extract category ID
        SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,              -- Extract product key
        prd_nm,
        ISNULL(prd_cost, 0) AS prd_cost,
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line, 
        TRY_CONVERT(date, prd_start_dt) AS prd_start_dt,
        DATEADD(
            DAY, -1,
            LEAD(TRY_CONVERT(date, prd_start_dt))
            OVER (PARTITION BY prd_key ORDER BY TRY_CONVERT(date, prd_start_dt))
        ) AS prd_end_dt
    FROM bronze.crm_prd_info;


    /* ============================
       CRM Sales Info
       ============================ */
    TRUNCATE TABLE silver.crm_sales_info;

    INSERT INTO silver.crm_sales_info (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        /* Dates expected as YYYYMMDD (int or string). TRY_CONVERT with style 112 handles both; invalid -> NULL */
        TRY_CONVERT(date, CAST(sls_order_dt AS CHAR(8)), 112) AS sls_order_dt,
        TRY_CONVERT(date, CAST(sls_ship_dt  AS CHAR(8)), 112) AS sls_ship_dt,
        TRY_CONVERT(date, CAST(sls_due_dt   AS CHAR(8)), 112) AS sls_due_dt,

        CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
                THEN NULLIF(sls_sales, 0) / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_info;


    /* ============================
       ERP Customer AZ12
       ============================ */
    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
            ELSE cid
        END AS cid,
        CASE
            WHEN TRY_CONVERT(date, bdate) IS NOT NULL
                 AND TRY_CONVERT(date, bdate) <= CAST(GETDATE() AS date)
            THEN TRY_CONVERT(date, bdate)
            ELSE NULL
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'n/a'
        END AS gen 
    FROM bronze.erp_cust_az12;


    /* ============================
       ERP Location A101
       ============================ */
    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry 
    FROM bronze.erp_loc_a101;


    /* ============================
       ERP PX Category G1V2
       ============================ */
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (
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
    FROM bronze.erp_px_cat_g1v2;

END;
GO