-- ============================================================
-- Stored Procedure: Silver to Gold - FactOrders
-- Builds the central fact table joining orders + order_items
-- with surrogate keys to dimensions
-- Source: fabric_demo.silver.orders, silver.order_items
-- Target: fabric_demo.gold.fact_orders
-- ============================================================

CREATE OR ALTER PROCEDURE gold.usp_LoadGoldFactOrders
AS
BEGIN
    DROP TABLE IF EXISTS gold.fact_orders;

    CREATE TABLE gold.fact_orders (
        fact_order_key      BIGINT          IDENTITY NOT NULL,
        order_id            VARCHAR(20)     NOT NULL,
        order_item_id       INT             NOT NULL,
        customer_key        INT             NOT NULL,
        product_key         INT             NOT NULL,
        order_date_key      INT             NOT NULL,
        shipping_date_key   INT             NULL,
        delivery_date_key   INT             NULL,
        order_status        VARCHAR(50)     NOT NULL,
        shipping_method     VARCHAR(50)     NOT NULL,
        payment_method      VARCHAR(100)    NOT NULL,
        quantity            INT             NOT NULL,
        unit_price          DECIMAL(10,2)   NOT NULL,
        cost_price          DECIMAL(10,2)   NOT NULL,
        discount_percent    DECIMAL(5,2)    NOT NULL,
        line_total          DECIMAL(10,2)   NOT NULL,
        line_cost           DECIMAL(10,2)   NOT NULL,
        line_profit         DECIMAL(10,2)   NOT NULL,
        discount_amount     DECIMAL(10,2)   NOT NULL,
        tax_amount          DECIMAL(10,2)   NOT NULL,
        shipping_cost       DECIMAL(10,2)   NOT NULL
    );

    INSERT INTO gold.fact_orders (
        order_id, order_item_id, customer_key, product_key,
        order_date_key, shipping_date_key, delivery_date_key,
        order_status, shipping_method, payment_method,
        quantity, unit_price, cost_price, discount_percent,
        line_total, line_cost, line_profit,
        discount_amount, tax_amount, shipping_cost
    )
    SELECT
        o.order_id,
        oi.order_item_id,
        dc.customer_key,
        dp.product_key,
        CAST(FORMAT(o.order_date, 'yyyyMMdd') AS INT)       AS order_date_key,
        CASE
            WHEN o.shipping_date IS NOT NULL
            THEN CAST(FORMAT(o.shipping_date, 'yyyyMMdd') AS INT)
        END                                                  AS shipping_date_key,
        CASE
            WHEN o.delivery_date IS NOT NULL
            THEN CAST(FORMAT(o.delivery_date, 'yyyyMMdd') AS INT)
        END                                                  AS delivery_date_key,
        o.status                                             AS order_status,
        o.shipping_method,
        o.payment_method,
        oi.quantity,
        oi.unit_price,
        sp.cost_price,
        oi.discount_percent,
        oi.line_total,
        oi.quantity * sp.cost_price                          AS line_cost,
        oi.line_total - (oi.quantity * sp.cost_price)        AS line_profit,
        o.discount_amount,
        o.tax_amount,
        o.shipping_cost
    FROM silver.orders o
    INNER JOIN silver.order_items oi
        ON o.order_id = oi.order_id
    INNER JOIN gold.dim_customer dc
        ON o.customer_id = dc.customer_id
    INNER JOIN gold.dim_product dp
        ON oi.product_id = dp.product_id
    INNER JOIN silver.products sp
        ON oi.product_id = sp.product_id;
END;
GO
