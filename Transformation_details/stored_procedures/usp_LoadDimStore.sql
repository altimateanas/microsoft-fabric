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
-- 4. Simple SELECT/INSERT IS supported in Fabric.
-- 5. @@ROWCOUNT is NOT supported in Fabric. Use ROW_COUNT() instead.
-- 6. CAST(... AS VARCHAR) - Fabric requires explicit length:
--    use CAST(... AS VARCHAR(50)) instead of CAST(... AS VARCHAR).
-- 7. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadDimStore
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

    PRINT 'DimStore loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
