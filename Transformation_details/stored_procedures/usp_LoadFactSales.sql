CREATE   PROCEDURE TRANSFORMED.usp_LoadFactSales
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.FactSales;

    INSERT INTO TRANSFORMED.FactSales (
        OrderID, OrderItemID, OrderDateKey, CustomerKey, ProductKey,
        StoreKey, EmployeeKey, PaymentMethodKey, OrderChannel, OrderStatus,
        Quantity, UnitPrice, CostPrice, DiscountPercent,
        LineTotal, LineCost, LineProfit, ShippingCost, PaymentAmount
    )
    SELECT
        o.OrderID,
        oi.OrderItemID,
        CONVERT(INT, FORMAT(o.OrderDate, 'yyyyMMdd'))   AS OrderDateKey,
        dc.CustomerKey,
        dp.ProductKey,
        ds.StoreKey,
        de.EmployeeKey,
        dpm.PaymentMethodKey,
        o.OrderChannel,
        o.OrderStatus,
        oi.Quantity,
        oi.UnitPrice,
        p.CostPrice,
        oi.Discount                                      AS DiscountPercent,
        oi.LineTotal,
        oi.Quantity * p.CostPrice                        AS LineCost,
        oi.LineTotal - (oi.Quantity * p.CostPrice)       AS LineProfit,
        CASE
            WHEN order_totals.OrderLineTotal > 0
            THEN ROUND(ISNULL(sh.ShippingCost, 0) * (oi.LineTotal / order_totals.OrderLineTotal), 2)
            ELSE 0
        END                                              AS ShippingCost,
        CASE
            WHEN order_totals.OrderLineTotal > 0
            THEN ROUND(ISNULL(pay.Amount, 0) * (oi.LineTotal / order_totals.OrderLineTotal), 2)
            ELSE 0
        END                                              AS PaymentAmount
    FROM RAW.Orders o
    INNER JOIN RAW.OrderItems oi           ON o.OrderID = oi.OrderID
    INNER JOIN RAW.Products p              ON oi.ProductID = p.ProductID
    INNER JOIN TRANSFORMED.DimCustomer dc  ON o.CustomerID = dc.CustomerID
    INNER JOIN TRANSFORMED.DimProduct dp   ON oi.ProductID = dp.ProductID
    INNER JOIN TRANSFORMED.DimStore ds     ON o.StoreID = ds.StoreID
    INNER JOIN TRANSFORMED.DimEmployee de  ON o.EmployeeID = de.EmployeeID
    LEFT JOIN (
        SELECT OrderID, PaymentMethod, Amount,
               ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY PaymentDate) AS rn
        FROM RAW.Payments
    ) pay ON o.OrderID = pay.OrderID AND pay.rn = 1
    LEFT JOIN TRANSFORMED.DimPaymentMethod dpm ON pay.PaymentMethod = dpm.PaymentMethod
    LEFT JOIN (
        SELECT OrderID, ShippingCost,
               ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY ShipDate) AS rn
        FROM RAW.Shipments
    ) sh ON o.OrderID = sh.OrderID AND sh.rn = 1
    CROSS APPLY (
        SELECT SUM(oi2.LineTotal) AS OrderLineTotal
        FROM RAW.OrderItems oi2
        WHERE oi2.OrderID = o.OrderID
    ) order_totals;

    PRINT 'FactSales loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
