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
-- 4. ROUND() IS supported in Fabric.
-- 5. CASE expressions ARE supported in Fabric.
-- 6. INNER JOIN syntax IS supported in Fabric.
-- 7. @@ROWCOUNT is NOT supported in Fabric. Use ROW_COUNT() instead.
-- 8. CAST(... AS VARCHAR) - Fabric requires explicit length:
--    use CAST(... AS VARCHAR(50)) instead of CAST(... AS VARCHAR).
-- 9. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadDimProduct
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.DimProduct;

    INSERT INTO TRANSFORMED.DimProduct (
        ProductID, ProductName, SKU, CategoryName, SupplierName,
        UnitPrice, CostPrice, ProfitMargin, IsDiscontinued
    )
    SELECT
        p.ProductID,
        p.ProductName,
        p.SKU,
        c.CategoryName,
        s.SupplierName,
        p.UnitPrice,
        p.CostPrice,
        CASE
            WHEN p.UnitPrice > 0
            THEN ROUND(((p.UnitPrice - p.CostPrice) / p.UnitPrice) * 100, 2)
            ELSE 0
        END AS ProfitMargin,
        p.IsDiscontinued
    FROM RAW.Products p
    INNER JOIN RAW.Categories c ON p.CategoryID = c.CategoryID
    INNER JOIN RAW.Suppliers s  ON p.SupplierID = s.SupplierID;

    PRINT 'DimProduct loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
