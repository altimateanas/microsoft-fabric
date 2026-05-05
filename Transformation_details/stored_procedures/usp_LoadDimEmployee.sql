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
-- 7. INNER JOIN syntax IS supported in Fabric.
-- 8. @@ROWCOUNT is NOT supported in Fabric. Use ROW_COUNT() instead.
-- 9. CAST(... AS VARCHAR) - Fabric requires explicit length:
--    use CAST(... AS VARCHAR(50)) instead of CAST(... AS VARCHAR).
-- 10. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadDimEmployee
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.DimEmployee;

    INSERT INTO TRANSFORMED.DimEmployee (
        EmployeeID, FullName, Email, JobTitle, Department,
        StoreName, HireDate, YearsOfService, IsActive
    )
    SELECT
        e.EmployeeID,
        CONCAT(e.FirstName, ' ', e.LastName) AS FullName,
        e.Email,
        e.JobTitle,
        e.Department,
        s.StoreName,
        e.HireDate,
        DATEDIFF(YEAR, e.HireDate, GETDATE()) AS YearsOfService,
        e.IsActive
    FROM RAW.Employees e
    INNER JOIN RAW.Stores s ON e.StoreID = s.StoreID;

    PRINT 'DimEmployee loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
