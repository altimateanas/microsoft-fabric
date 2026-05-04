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
