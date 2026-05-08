-- ============================================================
-- Stored Procedure: Bronze to Silver - Order Items
-- Transformations: type casting, referential integrity
--                  (order must exist in silver.orders,
--                   product must exist in silver.products),
--                  recalculate line_total for consistency
-- Source: fabric_demo.bronze.order_items
-- Target: fabric_demo.silver.order_items
-- ============================================================

CREATE OR ALTER PROCEDURE silver.usp_LoadSilverOrderItems
AS
BEGIN
    DROP TABLE IF EXISTS silver.order_items;

    CREATE TABLE silver.order_items (
        order_item_id       INT             NOT NULL,
        order_id            VARCHAR(20)     NOT NULL,
        product_id          VARCHAR(10)     NOT NULL,
        quantity            INT             NOT NULL,
        unit_price          DECIMAL(10,2)   NOT NULL,
        discount_percent    DECIMAL(5,2)    NOT NULL,
        line_total          DECIMAL(10,2)   NOT NULL
    );

    INSERT INTO silver.order_items
    SELECT
        CAST(oi.order_item_id AS INT)               AS order_item_id,
        TRIM(oi.order_id)                           AS order_id,
        TRIM(oi.product_id)                         AS product_id,
        CAST(oi.quantity AS INT)                     AS quantity,
        CAST(oi.unit_price AS DECIMAL(10,2))         AS unit_price,
        CAST(oi.discount_percent AS DECIMAL(5,2))    AS discount_percent,
        -- Recalculate line_total for data consistency
        ROUND(
            CAST(oi.quantity AS INT)
            * CAST(oi.unit_price AS DECIMAL(10,2))
            * (1 - CAST(oi.discount_percent AS DECIMAL(5,2)) / 100.0),
            2
        )                                           AS line_total
    FROM bronze.order_items oi
    INNER JOIN silver.orders o
        ON TRIM(oi.order_id) = o.order_id
    INNER JOIN silver.products p
        ON TRIM(oi.product_id) = p.product_id
    WHERE oi.order_item_id IS NOT NULL
      AND TRY_CAST(oi.quantity AS INT) > 0
      AND TRY_CAST(oi.unit_price AS DECIMAL(10,2)) > 0;
END;
GO
