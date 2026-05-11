-- ============================================================
-- Stored Procedure: Load Products from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/products.csv)
-- Target: fabric_demo.bronze.products
-- Method: CTAS from OPENROWSET on OneLake
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeProducts
AS
BEGIN
    DROP TABLE IF EXISTS bronze.products;

    CREATE TABLE bronze.products AS
    SELECT
        CAST([product_id] AS VARCHAR(50))         AS product_id,
        CAST([product_name] AS VARCHAR(200))      AS product_name,
        CAST([category] AS VARCHAR(100))          AS category,
        CAST([sub_category] AS VARCHAR(100))      AS sub_category,
        CAST([brand] AS VARCHAR(100))             AS brand,
        CAST([unit_price] AS VARCHAR(50))         AS unit_price,
        CAST([cost_price] AS VARCHAR(50))         AS cost_price,
        CAST([weight_kg] AS VARCHAR(50))          AS weight_kg,
        CAST([is_active] AS VARCHAR(10))          AS is_active,
        CAST([supplier] AS VARCHAR(200))          AS supplier,
        CAST([date_added] AS VARCHAR(50))         AS date_added
    FROM OPENROWSET(
        BULK 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/products.csv',
        FORMAT = 'CSV',
        HEADER_ROW = TRUE
    ) AS r;
END;
GO
