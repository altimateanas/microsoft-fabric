-- =====================================================================
-- PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- CONVERTED FROM: Microsoft SQL Server (T-SQL)
--
-- FABRIC COMPATIBILITY NOTES:
-- - SET NOCOUNT ON: Supported in Fabric
-- - TRUNCATE TABLE: Supported in Fabric
-- - WHILE loops: Supported in Fabric (but can be slow for large iterations)
-- - FORMAT(): Supported in Fabric
-- - DATEPART(), DATENAME(), DAY(), MONTH(), YEAR(): Supported in Fabric
-- - DATEADD(): Supported in Fabric
-- - CAST(... AS CHAR(n)): Must specify explicit length in Fabric
-- - @@ROWCOUNT: Supported in Fabric
--
-- PERFORMANCE NOTE: WHILE loops inserting row-by-row are slow in Fabric.
--   Consider a set-based approach using a numbers/tally table or
--   recursive CTE for better performance (recursive CTEs are NOT supported
--   in Fabric though). The WHILE loop approach works but may be slow
--   for large date ranges.
-- =====================================================================

CREATE OR ALTER PROCEDURE TRANSFORMED.usp_LoadDimDate
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE TRANSFORMED.DimDate;

    DECLARE @StartDate DATE = '2022-01-01';
    DECLARE @EndDate   DATE = '2026-12-31';
    DECLARE @Date      DATE = @StartDate;

    WHILE @Date <= @EndDate
    BEGIN
        INSERT INTO TRANSFORMED.DimDate (
            DateKey, FullDate, DayOfWeek, DayName, DayOfMonth, DayOfYear,
            WeekOfYear, MonthNumber, MonthName, Quarter, QuarterName,
            Year, IsWeekend, FiscalMonth, FiscalQuarter, FiscalYear
        )
        SELECT
            CONVERT(INT, FORMAT(@Date, 'yyyyMMdd'))      AS DateKey,
            @Date                                         AS FullDate,
            DATEPART(WEEKDAY, @Date)                      AS DayOfWeek,
            DATENAME(WEEKDAY, @Date)                      AS DayName,
            DAY(@Date)                                    AS DayOfMonth,
            DATEPART(DAYOFYEAR, @Date)                    AS DayOfYear,
            DATEPART(WEEK, @Date)                         AS WeekOfYear,
            MONTH(@Date)                                  AS MonthNumber,
            DATENAME(MONTH, @Date)                        AS MonthName,
            DATEPART(QUARTER, @Date)                      AS Quarter,
            'Q' + CAST(DATEPART(QUARTER, @Date) AS CHAR(1)) AS QuarterName,
            YEAR(@Date)                                   AS Year,
            CASE WHEN DATEPART(WEEKDAY, @Date) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
            CASE
                WHEN MONTH(@Date) >= 7 THEN MONTH(@Date) - 6
                ELSE MONTH(@Date) + 6
            END                                           AS FiscalMonth,
            CASE
                WHEN MONTH(@Date) >= 7 THEN (MONTH(@Date) - 7) / 3 + 1
                ELSE (MONTH(@Date) + 5) / 3
            END                                           AS FiscalQuarter,
            CASE
                WHEN MONTH(@Date) >= 7 THEN YEAR(@Date) + 1
                ELSE YEAR(@Date)
            END                                           AS FiscalYear;

        SET @Date = DATEADD(DAY, 1, @Date);
    END

    PRINT 'DimDate loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' rows';
END;
