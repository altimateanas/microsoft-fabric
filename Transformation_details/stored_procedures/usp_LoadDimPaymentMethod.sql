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
-- 4. SELECT DISTINCT IS supported in Fabric.
-- 5. CASE expressions ARE supported in Fabric.
-- 6. IN (...) syntax IS supported in Fabric.
-- 7. @@ROWCOUNT is NOT supported in Fabric. Use ROW_COUNT() instead.
-- 8. CAST(... AS VARCHAR) - Fabric requires explicit length:
--    use CAST(... AS VARCHAR(50)) instead of CAST(... AS VARCHAR).
-- 9. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadDimPaymentMethod
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.DimPaymentMethod;

    INSERT INTO TRANSFORMED.DimPaymentMethod (PaymentMethod, PaymentCategory)
    SELECT DISTINCT
        p.PaymentMethod,
        CASE
            WHEN p.PaymentMethod IN ('CreditCard', 'DebitCard')  THEN 'Card'
            WHEN p.PaymentMethod = 'Cash'                        THEN 'Physical'
            WHEN p.PaymentMethod = 'DigitalWallet'               THEN 'Digital'
            WHEN p.PaymentMethod = 'BankTransfer'                THEN 'Transfer'
            ELSE 'Other'
        END AS PaymentCategory
    FROM RAW.Payments p
    WHERE p.PaymentMethod IS NOT NULL;

    PRINT 'DimPaymentMethod loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
