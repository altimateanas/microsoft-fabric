-- ============================================================
-- Master Orchestration Stored Procedure
-- Executes the full medallion pipeline in correct order:
--   1. Bronze: Load raw data from lakehouse
--   2. Silver: Cleanse, validate, deduplicate
--   3. Gold:   Build star schema (dims first, then facts)
-- Warehouse: fabric_demo
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.usp_OrchestratePipeline
AS
BEGIN
    DECLARE @step VARCHAR(100);
    DECLARE @start_time DATETIME2;
    DECLARE @end_time DATETIME2;

    SET @start_time = GETDATE();
    PRINT '========================================';
    PRINT 'Pipeline Execution Started: ' + CAST(@start_time AS VARCHAR);
    PRINT '========================================';

    -- =====================
    -- STEP 1: BRONZE LAYER
    -- =====================
    PRINT '';
    PRINT '--- BRONZE LAYER ---';

    SET @step = 'Bronze: Customers';
    PRINT 'Loading ' + @step + '...';
    EXEC bronze.usp_LoadBronzeCustomers;
    PRINT @step + ' completed.';

    SET @step = 'Bronze: Products';
    PRINT 'Loading ' + @step + '...';
    EXEC bronze.usp_LoadBronzeProducts;
    PRINT @step + ' completed.';

    SET @step = 'Bronze: Orders';
    PRINT 'Loading ' + @step + '...';
    EXEC bronze.usp_LoadBronzeOrders;
    PRINT @step + ' completed.';

    SET @step = 'Bronze: Order Items';
    PRINT 'Loading ' + @step + '...';
    EXEC bronze.usp_LoadBronzeOrderItems;
    PRINT @step + ' completed.';

    -- =====================
    -- STEP 2: SILVER LAYER
    -- =====================
    PRINT '';
    PRINT '--- SILVER LAYER ---';

    -- Customers & Products first (no dependencies)
    SET @step = 'Silver: Customers';
    PRINT 'Loading ' + @step + '...';
    EXEC silver.usp_LoadSilverCustomers;
    PRINT @step + ' completed.';

    SET @step = 'Silver: Products';
    PRINT 'Loading ' + @step + '...';
    EXEC silver.usp_LoadSilverProducts;
    PRINT @step + ' completed.';

    -- Orders depends on Customers
    SET @step = 'Silver: Orders';
    PRINT 'Loading ' + @step + '...';
    EXEC silver.usp_LoadSilverOrders;
    PRINT @step + ' completed.';

    -- Order Items depends on Orders & Products
    SET @step = 'Silver: Order Items';
    PRINT 'Loading ' + @step + '...';
    EXEC silver.usp_LoadSilverOrderItems;
    PRINT @step + ' completed.';

    -- =====================
    -- STEP 3: GOLD LAYER
    -- =====================
    PRINT '';
    PRINT '--- GOLD LAYER ---';

    -- Dimensions first
    SET @step = 'Gold: DimDate';
    PRINT 'Loading ' + @step + '...';
    EXEC gold.usp_LoadGoldDimDate;
    PRINT @step + ' completed.';

    SET @step = 'Gold: DimCustomer';
    PRINT 'Loading ' + @step + '...';
    EXEC gold.usp_LoadGoldDimCustomer;
    PRINT @step + ' completed.';

    SET @step = 'Gold: DimProduct';
    PRINT 'Loading ' + @step + '...';
    EXEC gold.usp_LoadGoldDimProduct;
    PRINT @step + ' completed.';

    -- Fact table last (depends on all dimensions)
    SET @step = 'Gold: FactOrders';
    PRINT 'Loading ' + @step + '...';
    EXEC gold.usp_LoadGoldFactOrders;
    PRINT @step + ' completed.';

    -- =====================
    -- SUMMARY
    -- =====================
    SET @end_time = GETDATE();
    PRINT '';
    PRINT '========================================';
    PRINT 'Pipeline Execution Completed: ' + CAST(@end_time AS VARCHAR);
    PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
    PRINT '========================================';
END;
GO
