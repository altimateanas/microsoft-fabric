-- ============================================================
-- Stored Procedure: Load Order Items from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/order_items.csv)
-- Target: fabric_demo.bronze.order_items
-- Method: CTAS from OPENROWSET on OneLake
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeOrderItems
AS
BEGIN
    DROP TABLE IF EXISTS bronze.order_items;

    CREATE TABLE bronze.order_items AS
    SELECT
        CAST([order_item_id] AS VARCHAR(50))      AS order_item_id,
        CAST([order_id] AS VARCHAR(50))           AS order_id,
        CAST([product_id] AS VARCHAR(50))         AS product_id,
        CAST([quantity] AS VARCHAR(50))           AS quantity,
        CAST([unit_price] AS VARCHAR(50))         AS unit_price,
        CAST([discount_percent] AS VARCHAR(50))   AS discount_percent,
        CAST([line_total] AS VARCHAR(50))         AS line_total
    FROM OPENROWSET(
        BULK 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/order_items.csv',
        FORMAT = 'CSV',
        HEADER_ROW = TRUE
    ) AS r;
END;
GO
