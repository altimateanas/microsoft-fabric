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
