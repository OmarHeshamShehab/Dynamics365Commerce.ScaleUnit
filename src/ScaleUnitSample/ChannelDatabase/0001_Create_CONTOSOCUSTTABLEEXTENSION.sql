-- ============================================================
-- Script      : 0001_Create_CONTOSOCUSTTABLEEXTENSION.sql
-- Summary     : Creates the ext.CONTOSOCUSTTABLEEXTENSION table
--               for storing custom customer extension fields.
-- 
-- Purpose     : Extension table for ax.CUSTTABLE to store
--               additional customer properties (REFNOEXT) that
--               are not part of the standard D365 schema.
--
-- Pattern     : D365 Commerce Channel Database Extension
-- Schema      : ext (extension schema per Microsoft guidelines)
--
-- Columns     : RECID      - FK to ax.CUSTTABLE (PK)
--               REFNOEXT   - External reference number
--               ROWVERSION - Change tracking for real-time sync
--
-- Note        : ACCOUNTNUM and DATAAREAID are added by Script 0002
--               to support both fresh install and upgrade scenarios.
--
-- Dependencies: ext schema must exist (created below if missing)
--
-- Permissions : Grants DML + ALTER to DataSyncUsersRole for
--               Commerce Data Exchange (CDX) sync operations.
--
-- Author      : Omar Shehab
-- Created     : 2025-07-28
-- Modified    : 2026-03-18 (Refactored for best practices)
-- ============================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;  -- Ensures atomic failure for DDL operations
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- STEP 1: Ensure ext schema exists
-- Microsoft Ref: Channel Database extensibility requires ext schema
-- ============================================================
IF SCHEMA_ID('ext') IS NULL
BEGIN
    EXEC('CREATE SCHEMA [ext] AUTHORIZATION [dbo]');
    PRINT 'Schema [ext] created.';
END
ELSE
BEGIN
    PRINT 'Schema [ext] already exists.';
END
GO

-- ============================================================
-- STEP 2: Create the extension table if it does not exist
-- Microsoft Ref: Use RECID as PK to maintain referential integrity
--                with base AX tables without creating FK constraints
-- ============================================================
IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NULL
BEGIN
    PRINT 'Creating table [ext].[CONTOSOCUSTTABLEEXTENSION]...';
    
    CREATE TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
    (
        -- Primary key: matches RECID from ax.CUSTTABLE
        -- Do NOT create FK constraint (AX tables may be truncated during sync)
        [RECID]      BIGINT         NOT NULL,
        
        -- Business field: External reference number
        [REFNOEXT]   NVARCHAR(255)  NOT NULL
                     CONSTRAINT [DF_CONTOSOCUST_REFNOEXT] DEFAULT(N''),
        
        -- Change tracking: Used by CDX for incremental sync (high-water mark pattern)
        -- Microsoft Ref: ROWVERSION enables real-time sync without batch jobs
        [ROWVERSION] ROWVERSION     NOT NULL,
        
        -- Primary key constraint
        CONSTRAINT [PK_CONTOSOCUSTTABLEEXTENSION]
            PRIMARY KEY CLUSTERED ([RECID] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF)
    );
    
    PRINT 'Table [ext].[CONTOSOCUSTTABLEEXTENSION] created successfully.';
END
ELSE
BEGIN
    PRINT 'Table [ext].[CONTOSOCUSTTABLEEXTENSION] already exists. Skipping CREATE.';
END
GO

-- ============================================================
-- STEP 3: Create index on ROWVERSION for real-time sync performance
-- Microsoft Ref: CDX pulls changes using ROWVERSION > @lastSyncVersion
-- ============================================================
IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1 
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
      AND name = N'IX_CONTOSOCUSTTABLEEXTENSION_RowVersion'
)
BEGIN
    PRINT 'Creating index [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion]...';
    
    CREATE NONCLUSTERED INDEX [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion]
        ON [ext].[CONTOSOCUSTTABLEEXTENSION]([ROWVERSION] ASC);
    
    PRINT 'Index created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion] already exists or table missing.';
END
GO

-- ============================================================
-- STEP 4: Grant permissions to DataSyncUsersRole
-- Microsoft Ref: CDX service account uses this role for sync operations
--                ALTER permission required for schema modifications during upgrades
-- ============================================================
IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NOT NULL
BEGIN
    PRINT 'Granting permissions to [DataSyncUsersRole]...';
    
    GRANT SELECT, INSERT, UPDATE, DELETE, ALTER
        ON OBJECT::[ext].[CONTOSOCUSTTABLEEXTENSION]
        TO [DataSyncUsersRole];
    
    PRINT 'Permissions granted successfully.';
END
GO

-- ============================================================
-- POST-EXECUTION VALIDATION (uncomment to verify)
-- ============================================================
/*
-- Verify table exists
SELECT 
    SCHEMA_NAME(schema_id) AS [Schema],
    name AS [Table],
    create_date,
    modify_date
FROM sys.tables
WHERE name = 'CONTOSOCUSTTABLEEXTENSION';

-- Verify columns
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ext' 
  AND TABLE_NAME = 'CONTOSOCUSTTABLEEXTENSION'
ORDER BY ORDINAL_POSITION;

-- Verify indexes
SELECT i.name, i.type_desc, c.name AS column_name
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('ext.CONTOSOCUSTTABLEEXTENSION');
*/

PRINT '============================================================';
PRINT 'Script 0001 completed successfully.';
PRINT 'Next: Run Script 0002 to add ACCOUNTNUM and DATAAREAID columns.';
PRINT '============================================================';
GO
