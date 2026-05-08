-- ============================================================
-- Stored Procedure: Bronze to Silver - Orders
-- Transformations: type casting, referential integrity check
--                  (customer must exist in silver.customers),
--                  date validation, numeric casting
-- Source: fabric_demo.bronze.orders
-- Target: fabric_demo.silver.orders
-- ============================================================

CREATE OR ALTER PROCEDURE silver.usp_LoadSilverOrders
AS
BEGIN
    DROP TABLE IF EXISTS silver.orders;

    CREATE TABLE silver.orders (
        order_id                VARCHAR(20)     NOT NULL,
        customer_id             INT             NOT NULL,
        order_date              DATE            NOT NULL,
        shipping_date           DATE            NULL,
        delivery_date           DATE            NULL,
        status                  VARCHAR(50)     NOT NULL,
        shipping_method         VARCHAR(50)     NOT NULL,
        payment_method          VARCHAR(100)    NOT NULL,
        shipping_address_city   VARCHAR(100)    NULL,
        shipping_address_state  VARCHAR(50)     NULL,
        discount_amount         DECIMAL(10,2)   NOT NULL,
        tax_amount              DECIMAL(10,2)   NOT NULL,
        shipping_cost           DECIMAL(10,2)   NOT NULL
    );

    INSERT INTO silver.orders
    SELECT
        TRIM(o.order_id)                            AS order_id,
        CAST(o.customer_id AS INT)                  AS customer_id,
        CAST(o.order_date AS DATE)                  AS order_date,
        TRY_CAST(o.shipping_date AS DATE)           AS shipping_date,
        TRY_CAST(o.delivery_date AS DATE)           AS delivery_date,
        TRIM(o.status)                              AS status,
        TRIM(o.shipping_method)                     AS shipping_method,
        TRIM(o.payment_method)                      AS payment_method,
        TRIM(o.shipping_address_city)               AS shipping_address_city,
        TRIM(o.shipping_address_state)              AS shipping_address_state,
        CAST(o.discount_amount AS DECIMAL(10,2))    AS discount_amount,
        CAST(o.tax_amount AS DECIMAL(10,2))         AS tax_amount,
        CAST(o.shipping_cost AS DECIMAL(10,2))      AS shipping_cost
    FROM bronze.orders o
    -- Only include orders for customers that exist in silver
    INNER JOIN silver.customers c
        ON TRY_CAST(o.customer_id AS INT) = c.customer_id
    WHERE o.order_id IS NOT NULL
      AND TRIM(o.order_id) <> ''
      AND TRY_CAST(o.order_date AS DATE) IS NOT NULL;
END;
GO
