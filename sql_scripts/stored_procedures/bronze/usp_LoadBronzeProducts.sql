-- ============================================================
-- Stored Procedure: Load Products from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/products.csv)
-- Target: fabric_demo.bronze.products
-- Method: COPY INTO from OneLake
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeProducts
AS
BEGIN
    DROP TABLE IF EXISTS bronze.products;

    CREATE TABLE bronze.products (
        product_id      VARCHAR(50),
        product_name    VARCHAR(200),
        category        VARCHAR(100),
        sub_category    VARCHAR(100),
        brand           VARCHAR(100),
        unit_price      VARCHAR(50),
        cost_price      VARCHAR(50),
        weight_kg       VARCHAR(50),
        is_active       VARCHAR(10),
        supplier        VARCHAR(200),
        date_added      VARCHAR(50)
    );

    COPY INTO bronze.products
    FROM 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/products.csv'
    WITH (FILE_TYPE = 'CSV', FIRSTROW = 2);
END;
GO
