-- ============================================================
-- Stored Procedure: Load Customers from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/customers.csv)
-- Target: fabric_demo.bronze.customers
-- Method: COPY INTO from OneLake
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeCustomers
AS
BEGIN
    DROP TABLE IF EXISTS bronze.customers;

    CREATE TABLE bronze.customers (
        customer_id         VARCHAR(50),
        first_name          VARCHAR(100),
        last_name           VARCHAR(100),
        email               VARCHAR(200),
        phone               VARCHAR(50),
        address             VARCHAR(500),
        city                VARCHAR(100),
        state               VARCHAR(50),
        zip_code            VARCHAR(20),
        country             VARCHAR(50),
        date_of_birth       VARCHAR(50),
        registration_date   VARCHAR(50),
        loyalty_tier        VARCHAR(50)
    );

    COPY INTO bronze.customers
    FROM 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/customers.csv'
    WITH (FILE_TYPE = 'CSV', FIRSTROW = 2);
END;
GO
