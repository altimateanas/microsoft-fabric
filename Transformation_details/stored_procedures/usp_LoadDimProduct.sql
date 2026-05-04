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
