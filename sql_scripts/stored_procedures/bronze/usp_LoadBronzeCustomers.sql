-- ============================================================
-- Stored Procedure: Load Customers from Lakehouse to Bronze
-- Source: data_lake lakehouse (Files/customers.csv)
-- Target: fabric_demo.bronze.customers
-- Method: CTAS from OPENROWSET on OneLake
--   (Fabric Warehouse: COPY INTO is async and may not commit
--    when invoked via SQL connectors; CTAS+OPENROWSET is the
--    reliable synchronous load pattern.)
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronzeCustomers
AS
BEGIN
    DROP TABLE IF EXISTS bronze.customers;

    CREATE TABLE bronze.customers AS
    SELECT
        CAST([customer_id] AS VARCHAR(50))         AS customer_id,
        CAST([first_name] AS VARCHAR(100))         AS first_name,
        CAST([last_name] AS VARCHAR(100))          AS last_name,
        CAST([email] AS VARCHAR(200))              AS email,
        CAST([phone] AS VARCHAR(50))               AS phone,
        CAST([address] AS VARCHAR(500))            AS address,
        CAST([city] AS VARCHAR(100))               AS city,
        CAST([state] AS VARCHAR(50))               AS state,
        CAST([zip_code] AS VARCHAR(20))            AS zip_code,
        CAST([country] AS VARCHAR(50))             AS country,
        CAST([date_of_birth] AS VARCHAR(50))       AS date_of_birth,
        CAST([registration_date] AS VARCHAR(50))   AS registration_date,
        CAST([loyalty_tier] AS VARCHAR(50))        AS loyalty_tier
    FROM OPENROWSET(
        BULK 'https://onelake.dfs.fabric.microsoft.com/d2a5f51e-ff70-4456-b24a-0ba95dc5d8ba/417e58af-2e52-4fab-9573-63ac0aac47bc/Files/customers.csv',
        FORMAT = 'CSV',
        HEADER_ROW = TRUE
    ) AS r;
END;
GO
