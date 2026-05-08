-- ============================================================
-- Stored Procedure: Load Orders from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/orders.csv)
-- Target: fabric_demo.bronze.orders
-- Method: COPY INTO from OneLake
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeOrders
AS
BEGIN
    DROP TABLE IF EXISTS bronze.orders;

    CREATE TABLE bronze.orders (
        order_id                VARCHAR(50),
        customer_id             VARCHAR(50),
        order_date              VARCHAR(50),
        shipping_date           VARCHAR(50),
        delivery_date           VARCHAR(50),
        status                  VARCHAR(50),
        shipping_method         VARCHAR(50),
        payment_method          VARCHAR(100),
        shipping_address_city   VARCHAR(100),
        shipping_address_state  VARCHAR(50),
        discount_amount         VARCHAR(50),
        tax_amount              VARCHAR(50),
        shipping_cost           VARCHAR(50)
    );

    COPY INTO bronze.orders
    FROM 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/orders.csv'
    WITH (FILE_TYPE = 'CSV', FIRSTROW = 2);
END;
GO
