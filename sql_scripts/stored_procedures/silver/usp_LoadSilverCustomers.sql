-- ============================================================
-- Stored Procedure: Bronze to Silver - Customers
-- Transformations: deduplication, type casting, null handling,
--                  date validation, email standardization
-- Source: fabric_demo.bronze.customers
-- Target: fabric_demo.silver.customers
-- ============================================================

CREATE OR ALTER PROCEDURE silver.usp_LoadSilverCustomers
AS
BEGIN
    DROP TABLE IF EXISTS silver.customers;

    CREATE TABLE silver.customers (
        customer_id         INT             NOT NULL,
        first_name          VARCHAR(100)    NOT NULL,
        last_name           VARCHAR(100)    NOT NULL,
        email               VARCHAR(200)    NOT NULL,
        phone               VARCHAR(50)     NULL,
        address             VARCHAR(500)    NULL,
        city                VARCHAR(100)    NOT NULL,
        state               VARCHAR(50)     NOT NULL,
        zip_code            VARCHAR(20)     NOT NULL,
        country             VARCHAR(50)     NOT NULL,
        date_of_birth       DATE            NULL,
        registration_date   DATE            NOT NULL,
        loyalty_tier        VARCHAR(50)     NOT NULL
    );

    -- Deduplicate by customer_id (keep first occurrence),
    -- cast types, validate dates, standardize email to lowercase
    INSERT INTO silver.customers
    SELECT
        CAST(customer_id AS INT)                AS customer_id,
        TRIM(first_name)                        AS first_name,
        TRIM(last_name)                         AS last_name,
        LOWER(TRIM(email))                      AS email,
        CASE
            WHEN TRIM(phone) = '' THEN NULL
            ELSE TRIM(phone)
        END                                     AS phone,
        TRIM(address)                           AS address,
        TRIM(city)                              AS city,
        TRIM(state)                             AS state,
        TRIM(zip_code)                          AS zip_code,
        TRIM(country)                           AS country,
        TRY_CAST(date_of_birth AS DATE)         AS date_of_birth,
        CAST(registration_date AS DATE)         AS registration_date,
        TRIM(loyalty_tier)                      AS loyalty_tier
    FROM (
        SELECT
            customer_id, first_name, last_name, email, phone,
            address, city, state, zip_code, country,
            date_of_birth, registration_date, loyalty_tier,
            ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY customer_id
            ) AS rn
        FROM bronze.customers
        WHERE customer_id IS NOT NULL
          AND TRIM(customer_id) <> ''
          AND TRY_CAST(customer_id AS INT) IS NOT NULL
    ) deduped
    WHERE rn = 1;
END;
GO
