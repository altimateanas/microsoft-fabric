-- =====================================================================
-- PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- CONVERTED FROM: Microsoft SQL Server (T-SQL)
--
-- FABRIC COMPATIBILITY NOTES:
-- - SET NOCOUNT ON: Supported in Fabric
-- - TRUNCATE TABLE: Supported in Fabric
-- - Simple SELECT/INSERT: Supported in Fabric
-- - @@ROWCOUNT: Supported in Fabric
-- - CAST(... AS VARCHAR(n)): Must specify explicit length in Fabric
-- =====================================================================

CREATE OR ALTER PROCEDURE TRANSFORMED.usp_LoadDimStore
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.DimStore;

    INSERT INTO TRANSFORMED.DimStore (
        StoreID, StoreName, StoreType, City, State, Country,
        PostalCode, ManagerName, OpenDate, IsActive
    )
    SELECT
        st.StoreID,
        st.StoreName,
        st.StoreType,
        st.City,
        st.State,
        st.Country,
        st.PostalCode,
        st.ManagerName,
        st.OpenDate,
        st.IsActive
    FROM RAW.Stores st;

    PRINT 'DimStore loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' rows';
END;
