-- ============================================================
-- Stored Procedure: Silver to Gold - DimProduct
-- Builds product dimension with price tier classification
-- Source: fabric_demo.silver.products
-- Target: fabric_demo.gold.dim_product
-- ============================================================

CREATE OR ALTER PROCEDURE gold.usp_LoadGoldDimProduct
AS
BEGIN
    DROP TABLE IF EXISTS gold.dim_product;

    CREATE TABLE gold.dim_product (
        product_key     INT             NOT NULL,
        product_id      VARCHAR(10)     NOT NULL,
        product_name    VARCHAR(200)    NOT NULL,
        category        VARCHAR(100)    NOT NULL,
        sub_category    VARCHAR(100)    NOT NULL,
        brand           VARCHAR(100)    NOT NULL,
        unit_price      DECIMAL(10,2)   NOT NULL,
        cost_price      DECIMAL(10,2)   NOT NULL,
        profit_margin   DECIMAL(10,2)   NOT NULL,
        margin_percent  DECIMAL(5,2)    NOT NULL,
        price_tier      VARCHAR(20)     NOT NULL,
        is_active       BIT             NOT NULL,
        supplier        VARCHAR(200)    NOT NULL,
        date_added      DATE            NOT NULL
    );

    INSERT INTO gold.dim_product
    SELECT
        ROW_NUMBER() OVER (ORDER BY product_id) AS product_key,
        product_id,
        product_name,
        category,
        sub_category,
        brand,
        unit_price,
        cost_price,
        profit_margin,
        ROUND((profit_margin / unit_price) * 100, 2) AS margin_percent,
        CASE
            WHEN unit_price < 30 THEN 'Budget'
            WHEN unit_price < 100 THEN 'Mid-Range'
            WHEN unit_price < 300 THEN 'Premium'
            ELSE 'Luxury'
        END                                     AS price_tier,
        is_active,
        supplier,
        date_added
    FROM silver.products;
END;
GO
