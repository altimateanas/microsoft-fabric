-- ============================================================
-- Create Schemas for Medallion Architecture
-- Warehouse: fabric_demo
-- Workspace: fabric-medallion
-- ============================================================

-- Bronze (Raw) Layer - landing zone for raw data from lakehouse
CREATE SCHEMA IF NOT EXISTS bronze;
GO

-- Silver (Cleansed) Layer - validated, deduplicated, typed data
CREATE SCHEMA IF NOT EXISTS silver;
GO

-- Gold (Curated) Layer - star schema for analytics & semantic model
CREATE SCHEMA IF NOT EXISTS gold;
GO
