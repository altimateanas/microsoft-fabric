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
