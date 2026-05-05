-- =====================================================================
-- PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- CONVERTED FROM: Microsoft SQL Server (T-SQL)
--
-- FABRIC COMPATIBILITY NOTES:
-- - SET NOCOUNT ON: Supported in Fabric
-- - GETDATE(), DATEDIFF(), CONVERT(): Supported in Fabric
-- - EXEC <procedure>: Supported in Fabric
-- - PRINT: Supported in Fabric (output may not be visible in all clients)
-- - DECLARE with inline init: Supported in Fabric
-- - String concatenation with '+': Supported in Fabric
-- - CAST(... AS VARCHAR): Use explicit length for best practice
-- =====================================================================

CREATE OR ALTER PROCEDURE TRANSFORMED.usp_LoadAllTransformed
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = GETDATE();
    PRINT '========================================';
    PRINT 'Starting TRANSFORMED layer load at ' + CONVERT(VARCHAR(30), @StartTime, 120);
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
    PRINT 'TRANSFORMED layer load completed at ' + CONVERT(VARCHAR(30), @EndTime, 120);
    PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS VARCHAR(10)) + ' seconds';
    PRINT '========================================';
END;
