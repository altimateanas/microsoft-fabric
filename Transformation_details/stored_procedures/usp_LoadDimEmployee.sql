-- =====================================================================
-- PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- CONVERTED FROM: Microsoft SQL Server (T-SQL)
--
-- FABRIC COMPATIBILITY NOTES:
-- - SET NOCOUNT ON: Supported in Fabric
-- - TRUNCATE TABLE: Supported in Fabric
-- - CONCAT(): Supported in Fabric
-- - DATEDIFF(), GETDATE(): Supported in Fabric
-- - INNER JOIN: Supported in Fabric
-- - @@ROWCOUNT: Supported in Fabric
-- - CAST(... AS VARCHAR(n)): Must specify explicit length in Fabric
-- =====================================================================

CREATE OR ALTER PROCEDURE TRANSFORMED.usp_LoadDimEmployee
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

    PRINT 'DimEmployee loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' rows';
END;
