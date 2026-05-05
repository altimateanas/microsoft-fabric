-- =====================================================================
-- SOURCE SYNTAX: Microsoft SQL Server (MS SQL / T-SQL)
-- TARGET PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- STATUS: REQUIRES CONVERSION to Fabric-compatible syntax
--
-- CONVERSION NOTES FOR MICROSOFT FABRIC:
-- 1. SET NOCOUNT ON is NOT supported in Fabric. Remove it.
-- 2. PRINT statements are NOT supported in Fabric. Remove or replace
--    with SELECT statements for debugging output.
-- 3. DECLARE with inline initialization (DECLARE @x TYPE = value) IS supported.
-- 4. CONVERT(VARCHAR, @val, style) works in Fabric but prefer CAST or FORMAT.
-- 5. EXEC <procedure> syntax IS supported in Fabric.
-- 6. GETDATE() IS supported in Fabric (returns DATETIME2).
-- 7. DATEDIFF() IS supported in Fabric.
-- 8. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
--    Fabric does NOT support "CREATE OR ALTER PROCEDURE".
-- 9. String concatenation with '+' IS supported in Fabric.
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadAllTransformed
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = GETDATE();
    PRINT '========================================';
    PRINT 'Starting TRANSFORMED layer load at ' + CONVERT(VARCHAR, @StartTime, 120);
    PRINT '========================================';

    PRINT '';
    PRINT '--- Loading Dimensions ---';
    EXEC TRANSFORMED.usp_LoadDimDate;
    EXEC TRANSFORMED.usp_LoadDimCustomer;
    EXEC TRANSFORMED.usp_LoadDimProduct;
    EXEC TRANSFORMED.usp_LoadDimStore;
    EXEC TRANSFORMED.usp_LoadDimEmployee;
    EXEC TRANSFORMED.usp_LoadDimPaymentMethod;

    PRINT '';
    PRINT '--- Loading Facts ---';
    EXEC TRANSFORMED.usp_LoadFactSales;
    EXEC TRANSFORMED.usp_LoadFactDailyInventory;

    DECLARE @EndTime DATETIME2 = GETDATE();
    PRINT '';
    PRINT '========================================';
    PRINT 'TRANSFORMED layer load completed at ' + CONVERT(VARCHAR, @EndTime, 120);
    PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS VARCHAR) + ' seconds';
    PRINT '========================================';
END;
