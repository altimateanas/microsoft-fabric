-- =====================================================================
-- SOURCE SYNTAX: Microsoft SQL Server (MS SQL / T-SQL)
-- TARGET PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- STATUS: REQUIRES CONVERSION to Fabric-compatible syntax
--
-- CONVERSION NOTES FOR MICROSOFT FABRIC:
-- 1. SET NOCOUNT ON is NOT supported in Fabric. Remove it.
-- 2. PRINT statements are NOT supported in Fabric. Remove or replace
--    with SELECT for debugging.
-- 3. FORMAT() is NOT supported in Fabric. Replace with:
--    CONVERT(INT, CONVERT(VARCHAR(8), GETDATE(), 112)) for yyyyMMdd integer.
-- 4. DELETE with WHERE IS supported in Fabric.
-- 5. DECLARE with inline initialization IS supported in Fabric.
-- 6. CASE expressions ARE supported in Fabric.
-- 7. INNER JOIN syntax IS supported in Fabric.
-- 8. @@ROWCOUNT is NOT supported in Fabric. Use ROW_COUNT() instead.
-- 9. CAST(... AS VARCHAR) - Fabric requires explicit length:
--    use CAST(... AS VARCHAR(50)) instead of CAST(... AS VARCHAR).
-- 10. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadFactDailyInventory
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

    PRINT 'FactDailyInventory snapshot loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
