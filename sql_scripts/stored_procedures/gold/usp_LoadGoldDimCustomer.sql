-- ============================================================
-- Stored Procedure: Silver to Gold - DimCustomer
-- Builds customer dimension with derived attributes
-- Source: fabric_demo.silver.customers
-- Target: fabric_demo.gold.dim_customer
-- ============================================================

CREATE OR ALTER PROCEDURE gold.usp_LoadGoldDimCustomer
AS
BEGIN
    DROP TABLE IF EXISTS gold.dim_customer;

    CREATE TABLE gold.dim_customer (
        customer_key        INT             NOT NULL,
        customer_id         INT             NOT NULL,
        full_name           VARCHAR(200)    NOT NULL,
        first_name          VARCHAR(100)    NOT NULL,
        last_name           VARCHAR(100)    NOT NULL,
        email               VARCHAR(200)    NOT NULL,
        phone               VARCHAR(50)     NULL,
        city                VARCHAR(100)    NOT NULL,
        state               VARCHAR(50)     NOT NULL,
        zip_code            VARCHAR(20)     NOT NULL,
        country             VARCHAR(50)     NOT NULL,
        age_group           VARCHAR(20)     NULL,
        loyalty_tier        VARCHAR(50)     NOT NULL,
        customer_tenure_months INT          NOT NULL,
        registration_date   DATE            NOT NULL
    );

    INSERT INTO gold.dim_customer
    SELECT
        ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
        customer_id,
        first_name + ' ' + last_name            AS full_name,
        first_name,
        last_name,
        email,
        phone,
        city,
        state,
        zip_code,
        country,
        CASE
            WHEN date_of_birth IS NULL THEN 'Unknown'
            WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) < 25 THEN '18-24'
            WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) < 35 THEN '25-34'
            WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) < 45 THEN '35-44'
            WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) < 55 THEN '45-54'
            ELSE '55+'
        END                                     AS age_group,
        loyalty_tier,
        DATEDIFF(MONTH, registration_date, GETDATE()) AS customer_tenure_months,
        registration_date
    FROM silver.customers;
END;
GO
