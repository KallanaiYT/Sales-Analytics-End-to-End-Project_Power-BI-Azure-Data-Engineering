/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
*/

create or alter procedure bronze.load_bronze  as
begin
truncate table bronze.crm_cust_info

BULK INSERT bronze.crm_cust_info
FROM 'D:\Desktop files\Project_GitHub\source_crm\cust_info.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

truncate table bronze.crm_prd_info

BULK INSERT bronze.crm_prd_info
FROM 'D:\Desktop files\Project_GitHub\source_crm\prd_info.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

truncate table bronze.crm_sales_info

BULK INSERT bronze.crm_sales_info
FROM 'D:\Desktop files\Project_GitHub\source_crm\sales_details.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

truncate table bronze.erp_cust_az12

BULK INSERT bronze.erp_cust_az12
FROM 'D:\Desktop files\Project_GitHub\source_erp\CUST_AZ12.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

truncate table bronze.erp_loc_a101

BULK INSERT bronze.erp_loc_a101
FROM 'D:\Desktop files\Project_GitHub\source_erp\LOC_A101.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

truncate table bronze.erp_px_cat_g1v2

BULK INSERT bronze.erp_px_cat_g1v2
FROM 'D:\Desktop files\Project_GitHub\source_erp\PX_CAT_G1V2.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);