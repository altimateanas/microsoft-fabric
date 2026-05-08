-- ============================================================
-- Stored Procedure: Bronze to Silver - Products
-- Transformations: type casting, price validation (> 0),
--                  filter invalid prices, trim strings
-- Source: fabric_demo.bronze.products
-- Target: fabric_demo.silver.products
-- ============================================================

CREATE OR ALTER PROCEDURE silver.usp_LoadSilverProducts
AS
BEGIN
    DROP TABLE IF EXISTS silver.products;

    CREATE TABLE silver.products (
        product_id      VARCHAR(10)     NOT NULL,
        product_name    VARCHAR(200)    NOT NULL,
        category        VARCHAR(100)    NOT NULL,
        sub_category    VARCHAR(100)    NOT NULL,
        brand           VARCHAR(100)    NOT NULL,
        unit_price      DECIMAL(10,2)   NOT NULL,
        cost_price      DECIMAL(10,2)   NOT NULL,
        profit_margin   DECIMAL(10,2)   NOT NULL,
        weight_kg       DECIMAL(6,2)    NULL,
        is_active       BIT             NOT NULL,
        supplier        VARCHAR(200)    NOT NULL,
        date_added      DATE            NOT NULL
    );

    INSERT INTO silver.products
    SELECT
        TRIM(product_id)                        AS product_id,
        TRIM(product_name)                      AS product_name,
        TRIM(category)                          AS category,
        TRIM(sub_category)                      AS sub_category,
        TRIM(brand)                             AS brand,
        CAST(unit_price AS DECIMAL(10,2))       AS unit_price,
        CAST(cost_price AS DECIMAL(10,2))       AS cost_price,
        CAST(unit_price AS DECIMAL(10,2)) - CAST(cost_price AS DECIMAL(10,2)) AS profit_margin,
        TRY_CAST(weight_kg AS DECIMAL(6,2))     AS weight_kg,
        CAST(is_active AS BIT)                  AS is_active,
        TRIM(supplier)                          AS supplier,
        CAST(date_added AS DATE)                AS date_added
    FROM bronze.products
    WHERE product_id IS NOT NULL
      AND TRIM(product_id) <> ''
      AND TRY_CAST(unit_price AS DECIMAL(10,2)) > 0
      AND TRY_CAST(cost_price AS DECIMAL(10,2)) > 0;
END;
GO
