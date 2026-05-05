-- =====================================================================
-- SOURCE SYNTAX: Microsoft SQL Server (MS SQL / T-SQL)
-- TARGET PLATFORM: Microsoft Fabric (Fabric Data Warehouse)
-- STATUS: REQUIRES CONVERSION to Fabric-compatible syntax
--
-- CONVERSION NOTES FOR MICROSOFT FABRIC:
-- 1. SET NOCOUNT ON is NOT supported in Fabric. Remove it.
-- 2. PRINT statements are NOT supported in Fabric. Remove or replace
--    with SELECT for debugging.
-- 3. WHILE loops ARE supported in Fabric stored procedures.
-- 4. DECLARE with inline initialization IS supported in Fabric.
-- 5. FORMAT() is NOT supported in Fabric. Replace with:
--    CONVERT(INT, CONVERT(VARCHAR(8), @Date, 112)) for yyyyMMdd integer.
-- 6. DATEPART(), DATENAME(), DAY(), MONTH(), YEAR() ARE supported.
-- 7. DATEADD() IS supported in Fabric.
-- 8. CAST(... AS CHAR) - Fabric requires explicit length:
--    use CAST(... AS CHAR(1)) or VARCHAR(10) instead.
-- 9. @@ROWCOUNT is NOT supported in Fabric. Use ROW_COUNT() instead.
-- 10. CREATE PROCEDURE syntax: Use CREATE PROCEDURE (not CREATE OR ALTER).
-- 11. TRUNCATE TABLE IS supported in Fabric.
-- =====================================================================

CREATE   PROCEDURE TRANSFORMED.usp_LoadDimDate
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
            CONVERT(INT, FORMAT(@Date, 'yyyyMMdd'))     AS DateKey,
            @Date                                        AS FullDate,
            DATEPART(WEEKDAY, @Date)                     AS DayOfWeek,
            DATENAME(WEEKDAY, @Date)                     AS DayName,
            DAY(@Date)                                   AS DayOfMonth,
            DATEPART(DAYOFYEAR, @Date)                   AS DayOfYear,
            DATEPART(WEEK, @Date)                        AS WeekOfYear,
            MONTH(@Date)                                 AS MonthNumber,
            DATENAME(MONTH, @Date)                       AS MonthName,
            DATEPART(QUARTER, @Date)                     AS Quarter,
            'Q' + CAST(DATEPART(QUARTER, @Date) AS CHAR) AS QuarterName,
            YEAR(@Date)                                  AS Year,
            CASE WHEN DATEPART(WEEKDAY, @Date) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
            CASE
                WHEN MONTH(@Date) >= 7 THEN MONTH(@Date) - 6
                ELSE MONTH(@Date) + 6
            END                                          AS FiscalMonth,
            CASE
                WHEN MONTH(@Date) >= 7 THEN (MONTH(@Date) - 7) / 3 + 1
                ELSE (MONTH(@Date) + 5) / 3
            END                                          AS FiscalQuarter,
            CASE
                WHEN MONTH(@Date) >= 7 THEN YEAR(@Date) + 1
                ELSE YEAR(@Date)
            END                                          AS FiscalYear;

        SET @Date = DATEADD(DAY, 1, @Date);
    END

    PRINT 'DimDate loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
