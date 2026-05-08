-- ============================================================
-- Stored Procedure: Load Order Items from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/order_items.csv)
-- Target: fabric_demo.bronze.order_items
-- Method: COPY INTO from OneLake
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeOrderItems
AS
BEGIN
    DROP TABLE IF EXISTS bronze.order_items;

    CREATE TABLE bronze.order_items (
        order_item_id       VARCHAR(50),
        order_id            VARCHAR(50),
        product_id          VARCHAR(50),
        quantity            VARCHAR(50),
        unit_price          VARCHAR(50),
        discount_percent    VARCHAR(50),
        line_total          VARCHAR(50)
    );

    COPY INTO bronze.order_items
    FROM 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/order_items.csv'
    WITH (FILE_TYPE = 'CSV', FIRSTROW = 2);
END;
GO
