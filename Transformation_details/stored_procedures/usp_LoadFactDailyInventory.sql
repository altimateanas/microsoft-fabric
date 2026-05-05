-- =====================================================================
-- PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- CONVERTED FROM: Microsoft SQL Server (T-SQL)
--
-- FABRIC COMPATIBILITY NOTES:
-- - SET NOCOUNT ON: Supported in Fabric
-- - FORMAT(): Supported in Fabric
-- - DELETE with WHERE: Supported in Fabric
-- - DECLARE with inline init: Supported in Fabric
-- - CASE expressions: Supported in Fabric
-- - INNER JOIN: Supported in Fabric
-- - @@ROWCOUNT: Supported in Fabric
-- - CAST(... AS VARCHAR(n)): Must specify explicit length in Fabric
-- =====================================================================

CREATE OR ALTER PROCEDURE TRANSFORMED.usp_LoadFactDailyInventory
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TodayKey INT = CONVERT(INT, FORMAT(GETDATE(), 'yyyyMMdd'));

    DELETE FROM TRANSFORMED.FactDailyInventory
    WHERE SnapshotDateKey = @TodayKey;

    INSERT INTO TRANSFORMED.FactDailyInventory (
        SnapshotDateKey, ProductKey, UnitsInStock, ReorderLevel,
        StockStatus, StockValue
    )
    SELECT
        @TodayKey                                       AS SnapshotDateKey,
        dp.ProductKey,
        p.UnitsInStock,
        p.ReorderLevel,
        CASE
            WHEN p.UnitsInStock = 0               THEN 'Out of Stock'
            WHEN p.UnitsInStock <= p.ReorderLevel  THEN 'Low Stock'
            ELSE 'In Stock'
        END                                             AS StockStatus,
        p.UnitsInStock * p.CostPrice                    AS StockValue
    FROM RAW.Products p
    INNER JOIN TRANSFORMED.DimProduct dp ON p.ProductID = dp.ProductID
    WHERE p.IsDiscontinued = 0;

    PRINT 'FactDailyInventory snapshot loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' rows';
END;
