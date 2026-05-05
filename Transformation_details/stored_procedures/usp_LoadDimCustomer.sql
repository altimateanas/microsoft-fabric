-- =====================================================================
-- SOURCE SYNTAX: Microsoft SQL Server (MS SQL / T-SQL)
-- TARGET PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- STATUS: REQUIRES CONVERSION to Fabric-compatible syntax
--
-- CONVERSION NOTES FOR MICROSOFT FABRIC:
-- 1. SET NOCOUNT ON is NOT supported in Fabric. Remove it.
-- 2. PRINT statements are NOT supported in Fabric. Remove or replace
--    with SELECT for debugging.
-- 3. TRUNCATE TABLE IS supported in Fabric.
-- 4. CONCAT() IS supported in Fabric.
-- 5. DATEDIFF() IS supported in Fabric.
-- 6. GETDATE() IS supported in Fabric.
-- 7. CASE expressions ARE supported in Fabric.
-- 8. @@ROWCOUNT is NOT supported in Fabric. Use ROW_COUNT() instead.
-- 9. CAST(... AS VARCHAR) - Fabric requires explicit length:
--    use CAST(... AS VARCHAR(50)) instead of CAST(... AS VARCHAR).
-- 10. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadDimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.DimCustomer;

    INSERT INTO TRANSFORMED.DimCustomer (
        CustomerID, FullName, Email, Phone, DateOfBirth, Gender,
        City, State, Country, PostalCode, CustomerSegment,
        AgeGroup, RegistrationDate, IsActive
    )
    SELECT
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
        c.Email,
        c.Phone,
        c.DateOfBirth,
        c.Gender,
        c.City,
        c.State,
        c.Country,
        c.PostalCode,
        c.CustomerSegment,
        CASE
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 25 THEN '18-24'
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 35 THEN '25-34'
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 45 THEN '35-44'
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 55 THEN '45-54'
            ELSE '55+'
        END AS AgeGroup,
        c.RegistrationDate,
        c.IsActive
    FROM RAW.Customers c;

    PRINT 'DimCustomer loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
