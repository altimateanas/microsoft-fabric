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
