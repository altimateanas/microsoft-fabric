CREATE   PROCEDURE TRANSFORMED.usp_LoadDimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.DimCustomer;

    INSERT INTO TRANSFORMED.DimCustomer (
        CustomerID, FullName, Email, Phone, DateOfBirth, Gender,
        City, State, Country, PostalCode, CustomerSegment,
        AgeGroup, RegistrationDate, IsActive
    )
    SELECT
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
        c.Email,
        c.Phone,
        c.DateOfBirth,
        c.Gender,
        c.City,
        c.State,
        c.Country,
        c.PostalCode,
        c.CustomerSegment,
        CASE
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 25 THEN '18-24'
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 35 THEN '25-34'
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 45 THEN '35-44'
            WHEN DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) < 55 THEN '45-54'
            ELSE '55+'
        END AS AgeGroup,
        c.RegistrationDate,
        c.IsActive
    FROM RAW.Customers c;

    PRINT 'DimCustomer loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
