-- ============================================================
-- Script      : 0003_CreateCustTableView.sql
-- Summary     : Creates the ext.CUSTTABLEVIEW that joins base
--               ax.CUSTTABLE with ext.CONTOSOCUSTTABLEEXTENSION.
--
-- Purpose     : Provides a unified view of customer data combining
--               standard D365 fields with custom extension fields.
--               Used by CRT extensions and reporting queries.
--
-- Pattern     : D365 Commerce Channel Database Extension View
-- Schema      : ext (extension schema per Microsoft guidelines)
--
-- Columns     : CUSTOMERRECID  - Unique customer identifier (from ax)
--               ACCOUNTNUM     - Customer account number (from ax)
--               DATAAREAID     - Company identifier (from ax)
--               REFNOEXT       - External reference (from ext)
--               EXTACCOUNTNUM  - Extended account number (from ext)
--
-- Join Logic  : LEFT JOIN ensures all customers are returned even
--               if they don't have extension records yet.
--
-- Deployment  : This script runs BEFORE CDX sync populates ax tables.
--               The view is created and will function correctly once
--               ax.CUSTTABLE is populated by CDX.
--
-- Dependencies: ext.CONTOSOCUSTTABLEEXTENSION must exist (Script 0001/0002)
--               ax.CUSTTABLE will be populated by CDX sync after deployment
--
-- Author      : Omar Shehab
-- Created     : 2025-07-28
-- Modified    : 2026-03-18 (Refactored for best practices)
-- ============================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- PRE-EXECUTION INFO (non-blocking)
-- Note: ax.CUSTTABLE may not exist during initial deployment.
--       CDX sync will populate it after Scale Unit installation.
-- ============================================================
IF OBJECT_ID(N'[ax].[CUSTTABLE]', 'U') IS NULL
BEGIN
    PRINT 'INFO: Table [ax].[CUSTTABLE] does not exist yet. This is expected during initial deployment.';
    PRINT 'INFO: The view will function correctly after CDX sync populates the ax schema tables.';
END

IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NULL
BEGIN
    PRINT 'WARNING: Table [ext].[CONTOSOCUSTTABLEEXTENSION] does not exist. Run Scripts 0001 and 0002 first.';
END
GO

-- ============================================================
-- CREATE OR ALTER VIEW
-- Microsoft Ref: CREATE OR ALTER is preferred over DROP + CREATE
--                - Atomic operation
--                - Preserves existing permissions
--                - Preserves dependencies
-- ============================================================
PRINT 'Creating/updating view [ext].[CUSTTABLEVIEW]...';
GO

CREATE OR ALTER VIEW [ext].[CUSTTABLEVIEW]
AS
    -- --------------------------------------------------------
    -- Unified customer view combining base and extension data
    -- 
    -- Usage: 
    --   SELECT * FROM ext.CUSTTABLEVIEW WHERE DATAAREAID = 'USMF'
    --
    -- Note: LEFT JOIN ensures customers without extension records
    --       are still returned with NULL/empty extension fields
    -- --------------------------------------------------------
    SELECT
        -- Base table fields (from ax.CUSTTABLE)
        ax.[RECID]                          AS CUSTOMERRECID,
        ax.[ACCOUNTNUM]                     AS ACCOUNTNUM,
        ax.[DATAAREAID]                     AS DATAAREAID,
        
        -- Extension table fields (from ext.CONTOSOCUSTTABLEEXTENSION)
        -- ISNULL ensures empty string instead of NULL for missing records
        ISNULL(ext.[REFNOEXT], N'')         AS REFNOEXT,
        ISNULL(ext.[ACCOUNTNUM], N'')       AS EXTACCOUNTNUM
        
    FROM [ax].[CUSTTABLE] AS ax
    
    LEFT JOIN [ext].[CONTOSOCUSTTABLEEXTENSION] AS ext
        ON ax.[RECID] = ext.[RECID];
GO

PRINT 'View [ext].[CUSTTABLEVIEW] created/updated successfully.';
GO

-- ============================================================
-- GRANT PERMISSIONS
-- Microsoft Ref: DataSyncUsersRole needs SELECT for sync operations
-- ============================================================
PRINT 'Granting SELECT permission to [DataSyncUsersRole]...';

GRANT SELECT
    ON OBJECT::[ext].[CUSTTABLEVIEW]
    TO [DataSyncUsersRole];

PRINT 'Permission granted successfully.';
GO

-- ============================================================
-- POST-EXECUTION VALIDATION (uncomment to verify after CDX sync)
-- ============================================================
/*
-- Verify view exists
SELECT 
    SCHEMA_NAME(schema_id) AS [Schema],
    name AS [View],
    create_date,
    modify_date
FROM sys.views
WHERE name = 'CUSTTABLEVIEW';

-- Verify view columns
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ext' 
  AND TABLE_NAME = 'CUSTTABLEVIEW'
ORDER BY ORDINAL_POSITION;

-- Test query (run after CDX sync, limit to 10 rows)
SELECT TOP 10 * 
FROM ext.CUSTTABLEVIEW
WHERE DATAAREAID = 'USMF'
ORDER BY ACCOUNTNUM;

-- Verify row count matches base table (run after CDX sync)
SELECT 
    (SELECT COUNT(*) FROM ax.CUSTTABLE) AS BaseTableCount,
    (SELECT COUNT(*) FROM ext.CUSTTABLEVIEW) AS ViewCount;
*/

PRINT '============================================================';
PRINT 'Script 0003 completed successfully.';
PRINT 'Next: Run Script 0004 to create the stored procedure.';
PRINT '============================================================';
GO
