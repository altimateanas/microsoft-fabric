-- ============================================================
-- Stored Procedure: Silver to Gold - DimDate
-- Generates a date dimension from the order date range
-- Target: fabric_demo.gold.dim_date
-- ============================================================

CREATE OR ALTER PROCEDURE gold.usp_LoadGoldDimDate
AS
BEGIN
    DROP TABLE IF EXISTS gold.dim_date;

    CREATE TABLE gold.dim_date (
        date_key        INT         NOT NULL,
        full_date       DATE        NOT NULL,
        day_of_week     INT         NOT NULL,
        day_name        VARCHAR(20) NOT NULL,
        day_of_month    INT         NOT NULL,
        day_of_year     INT         NOT NULL,
        week_of_year    INT         NOT NULL,
        month_number    INT         NOT NULL,
        month_name      VARCHAR(20) NOT NULL,
        month_short     VARCHAR(3)  NOT NULL,
        quarter         INT         NOT NULL,
        quarter_name    VARCHAR(10) NOT NULL,
        year            INT         NOT NULL,
        year_month      VARCHAR(7)  NOT NULL,
        is_weekend      BIT         NOT NULL
    );

    -- Generate dates from 2024-01-01 to 2024-12-31 using cross join (Fabric compatible)
    ;WITH
    N0 AS (SELECT 1 AS n UNION ALL SELECT 1),
    N1 AS (SELECT 1 AS n FROM N0 a CROSS JOIN N0 b),
    N2 AS (SELECT 1 AS n FROM N1 a CROSS JOIN N1 b),
    N3 AS (SELECT 1 AS n FROM N2 a CROSS JOIN N2 b),
    N4 AS (SELECT 1 AS n FROM N3 a CROSS JOIN N0 b),
    Numbers AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS num FROM N4)
    INSERT INTO gold.dim_date
    SELECT
        CAST(FORMAT(dt, 'yyyyMMdd') AS INT)     AS date_key,
        dt                                       AS full_date,
        DATEPART(WEEKDAY, dt)                    AS day_of_week,
        DATENAME(WEEKDAY, dt)                    AS day_name,
        DAY(dt)                                  AS day_of_month,
        DATEPART(DAYOFYEAR, dt)                  AS day_of_year,
        DATEPART(WEEK, dt)                       AS week_of_year,
        MONTH(dt)                                AS month_number,
        DATENAME(MONTH, dt)                      AS month_name,
        LEFT(DATENAME(MONTH, dt), 3)             AS month_short,
        DATEPART(QUARTER, dt)                    AS quarter,
        'Q' + CAST(DATEPART(QUARTER, dt) AS VARCHAR) AS quarter_name,
        YEAR(dt)                                 AS year,
        FORMAT(dt, 'yyyy-MM')                    AS year_month,
        CASE WHEN DATEPART(WEEKDAY, dt) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
    FROM (
        SELECT DATEADD(DAY, num, '2024-01-01') AS dt
        FROM Numbers
        WHERE num <= DATEDIFF(DAY, '2024-01-01', '2024-12-31')
    ) dates;
END;
GO
