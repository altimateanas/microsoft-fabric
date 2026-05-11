-- ============================================================
-- Stored Procedure: Load Orders from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/orders.csv)
-- Target: fabric_demo.bronze.orders
-- Method: CTAS from OPENROWSET on OneLake
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeOrders
AS
BEGIN
    DROP TABLE IF EXISTS bronze.orders;

    CREATE TABLE bronze.orders AS
    SELECT
        CAST([order_id] AS VARCHAR(50))                AS order_id,
        CAST([customer_id] AS VARCHAR(50))             AS customer_id,
        CAST([order_date] AS VARCHAR(50))              AS order_date,
        CAST([shipping_date] AS VARCHAR(50))           AS shipping_date,
        CAST([delivery_date] AS VARCHAR(50))           AS delivery_date,
        CAST([status] AS VARCHAR(50))                  AS status,
        CAST([shipping_method] AS VARCHAR(50))         AS shipping_method,
        CAST([payment_method] AS VARCHAR(100))         AS payment_method,
        CAST([shipping_address_city] AS VARCHAR(100))  AS shipping_address_city,
        CAST([shipping_address_state] AS VARCHAR(50))  AS shipping_address_state,
        CAST([discount_amount] AS VARCHAR(50))         AS discount_amount,
        CAST([tax_amount] AS VARCHAR(50))              AS tax_amount,
        CAST([shipping_cost] AS VARCHAR(50))           AS shipping_cost
    FROM OPENROWSET(
        BULK 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/orders.csv',
        FORMAT = 'CSV',
        HEADER_ROW = TRUE
    ) AS r;
END;
GO
