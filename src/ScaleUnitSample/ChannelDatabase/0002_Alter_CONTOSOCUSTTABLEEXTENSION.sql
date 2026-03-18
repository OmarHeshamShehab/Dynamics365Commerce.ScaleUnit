-- ============================================================
-- Script      : 0002_Alter_CONTOSOCUSTTABLEEXTENSION.sql
-- Summary     : Adds ACCOUNTNUM and DATAAREAID columns to the
--               ext.CONTOSOCUSTTABLEEXTENSION table with backfill.
--
-- Purpose     : Extends the table schema to include company context
--               (DATAAREAID) and customer account lookup (ACCOUNTNUM)
--               for multi-company D365 F&O environments.
--
-- Pattern     : D365 Commerce Channel Database Extension (Upgrade)
-- Schema      : ext (extension schema per Microsoft guidelines)
--
-- Operations  : 1. Create helper view for AX data access
--               2. Add ACCOUNTNUM column
--               3. Add DATAAREAID column (nullable initially)
--               4. Backfill DATAAREAID from ax.CUSTTABLE via helper view
--               5. Enforce NOT NULL on DATAAREAID
--               6. Add ROWVERSION if missing (idempotent)
--               7. Create performance indexes
--               8. Grant permissions
--
-- Dependencies: Script 0001 must be executed first
--               ax.CUSTTABLE must exist with RECID and DATAAREAID
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
-- PRE-EXECUTION VALIDATION
-- ============================================================
IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NULL
BEGIN
    RAISERROR('ERROR: Table [ext].[CONTOSOCUSTTABLEEXTENSION] does not exist. Run Script 0001 first.', 16, 1);
    RETURN;
END
GO

-- ============================================================
-- STEP 1: Create or update helper view for DATAAREAID lookup
-- Microsoft Ref: Encapsulate AX schema access in ext views
--                Avoids direct ax schema references in DML
-- ============================================================
PRINT 'Creating/updating helper view [ext].[Vw_CustTable_DataAreaID]...';
GO

CREATE OR ALTER VIEW [ext].[Vw_CustTable_DataAreaID] 
AS
    -- Encapsulated access to ax.CUSTTABLE for DATAAREAID lookup
    -- Used during backfill operations only
    SELECT 
        RECID,
        DATAAREAID
    FROM [ax].[CUSTTABLE];
GO

PRINT 'Helper view created/updated successfully.';
GO

-- ============================================================
-- STEP 2: Add ACCOUNTNUM column if missing
-- Microsoft Ref: Customer account number for business lookups
-- ============================================================
IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'ACCOUNTNUM') IS NULL
BEGIN
    PRINT 'Adding column [ACCOUNTNUM]...';
    
    ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ADD [ACCOUNTNUM] NVARCHAR(20) NOT NULL
            CONSTRAINT [DF_CONTOSOCUST_ACCOUNTNUM] DEFAULT(N'');
    
    PRINT 'Column [ACCOUNTNUM] added successfully.';
END
ELSE
BEGIN
    PRINT 'Column [ACCOUNTNUM] already exists. Skipping.';
END
GO

-- ============================================================
-- STEP 3: Add DATAAREAID column if missing (nullable for backfill)
-- Microsoft Ref: DATAAREAID is required for multi-company filtering
-- ============================================================
IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'DATAAREAID') IS NULL
BEGIN
    PRINT 'Adding column [DATAAREAID] (nullable for backfill)...';
    
    ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ADD [DATAAREAID] NVARCHAR(4) NULL;
    
    PRINT 'Column [DATAAREAID] added successfully.';
END
ELSE
BEGIN
    PRINT 'Column [DATAAREAID] already exists. Skipping ADD.';
END
GO

-- ============================================================
-- STEP 4: Backfill DATAAREAID from ax.CUSTTABLE via helper view
-- Microsoft Ref: Use ext view to access ax schema data
-- ============================================================
PRINT 'Checking for rows that need DATAAREAID backfill...';

DECLARE @RowsToUpdate INT;
DECLARE @RowsUpdated INT;

SELECT @RowsToUpdate = COUNT(*)
FROM [ext].[CONTOSOCUSTTABLEEXTENSION]
WHERE [DATAAREAID] IS NULL;

IF @RowsToUpdate > 0
BEGIN
    PRINT 'Backfilling DATAAREAID for ' + CAST(@RowsToUpdate AS NVARCHAR(10)) + ' row(s)...';
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE e
        SET e.[DATAAREAID] = v.[DATAAREAID]
        FROM [ext].[CONTOSOCUSTTABLEEXTENSION] AS e
        INNER JOIN [ext].[Vw_CustTable_DataAreaID] AS v
            ON v.[RECID] = e.[RECID]
        WHERE e.[DATAAREAID] IS NULL;
        
        SET @RowsUpdated = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT 'Backfill completed. Rows updated: ' + CAST(@RowsUpdated AS NVARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('ERROR during DATAAREAID backfill: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
        RETURN;
    END CATCH
END
ELSE
BEGIN
    PRINT 'No rows require DATAAREAID backfill.';
END
GO

-- ============================================================
-- STEP 5: Enforce NOT NULL constraint on DATAAREAID
-- Microsoft Ref: DATAAREAID must be NOT NULL for proper filtering
-- ============================================================
PRINT 'Checking DATAAREAID nullability...';

-- Check if any NULLs remain (orphan records)
DECLARE @NullCount INT;
SELECT @NullCount = COUNT(*) 
FROM [ext].[CONTOSOCUSTTABLEEXTENSION] 
WHERE [DATAAREAID] IS NULL;

IF @NullCount > 0
BEGIN
    PRINT 'WARNING: ' + CAST(@NullCount AS NVARCHAR(10)) + ' row(s) still have NULL DATAAREAID (orphan records).';
    PRINT 'Setting default value for orphan records...';
    
    UPDATE [ext].[CONTOSOCUSTTABLEEXTENSION]
    SET [DATAAREAID] = N''
    WHERE [DATAAREAID] IS NULL;
END

-- Check current nullability before altering
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'ext'
      AND TABLE_NAME = 'CONTOSOCUSTTABLEEXTENSION'
      AND COLUMN_NAME = 'DATAAREAID'
      AND IS_NULLABLE = 'YES'
)
BEGIN
    PRINT 'Altering [DATAAREAID] to NOT NULL...';
    
    ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ALTER COLUMN [DATAAREAID] NVARCHAR(4) NOT NULL;
    
    PRINT 'Column [DATAAREAID] is now NOT NULL.';
END
ELSE
BEGIN
    PRINT 'Column [DATAAREAID] is already NOT NULL. Skipping ALTER.';
END
GO

-- ============================================================
-- STEP 6: Ensure ROWVERSION column exists (idempotent)
-- Microsoft Ref: Required for CDX real-time sync high-water mark
-- ============================================================
IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'ROWVERSION') IS NULL
BEGIN
    PRINT 'Adding column [ROWVERSION]...';
    
    ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ADD [ROWVERSION] ROWVERSION NOT NULL;
    
    PRINT 'Column [ROWVERSION] added successfully.';
END
ELSE
BEGIN
    PRINT 'Column [ROWVERSION] already exists. Skipping.';
END
GO

-- ============================================================
-- STEP 7: Create index on ROWVERSION (if not exists)
-- Microsoft Ref: Required for efficient CDX incremental sync
-- ============================================================
IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
      AND name = N'IX_CONTOSOCUSTTABLEEXTENSION_RowVersion'
)
AND COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'ROWVERSION') IS NOT NULL
BEGIN
    PRINT 'Creating index [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion]...';
    
    CREATE NONCLUSTERED INDEX [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion]
        ON [ext].[CONTOSOCUSTTABLEEXTENSION]([ROWVERSION] ASC);
    
    PRINT 'Index created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion] already exists or column missing.';
END
GO

-- ============================================================
-- STEP 8: Create index on ACCOUNTNUM for lookup performance
-- Microsoft Ref: Supports efficient customer lookup by account number
-- ============================================================
IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
      AND name = N'IX_CONTOSOCUSTTABLEEXTENSION_AccountNum'
)
AND COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'ACCOUNTNUM') IS NOT NULL
BEGIN
    PRINT 'Creating index [IX_CONTOSOCUSTTABLEEXTENSION_AccountNum]...';
    
    CREATE NONCLUSTERED INDEX [IX_CONTOSOCUSTTABLEEXTENSION_AccountNum]
        ON [ext].[CONTOSOCUSTTABLEEXTENSION]([ACCOUNTNUM] ASC);
    
    PRINT 'Index created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_CONTOSOCUSTTABLEEXTENSION_AccountNum] already exists or column missing.';
END
GO

-- ============================================================
-- STEP 9: Grant permissions to DataSyncUsersRole
-- Microsoft Ref: Re-grant after schema changes to ensure access
-- ============================================================
PRINT 'Granting permissions to [DataSyncUsersRole]...';

GRANT SELECT, INSERT, UPDATE, DELETE, ALTER
    ON OBJECT::[ext].[CONTOSOCUSTTABLEEXTENSION]
    TO [DataSyncUsersRole];

GRANT SELECT
    ON OBJECT::[ext].[Vw_CustTable_DataAreaID]
    TO [DataSyncUsersRole];

PRINT 'Permissions granted successfully.';
GO

-- ============================================================
-- POST-EXECUTION VALIDATION (uncomment to verify)
-- ============================================================
/*
-- Verify all columns exist with correct types
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE, 
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ext' 
  AND TABLE_NAME = 'CONTOSOCUSTTABLEEXTENSION'
ORDER BY ORDINAL_POSITION;

-- Verify indexes
SELECT 
    i.name AS index_name, 
    i.type_desc,
    STRING_AGG(c.name, ', ') AS columns
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('ext.CONTOSOCUSTTABLEEXTENSION')
GROUP BY i.name, i.type_desc;

-- Verify no NULL DATAAREAID values
SELECT COUNT(*) AS NullDataAreaCount
FROM ext.CONTOSOCUSTTABLEEXTENSION
WHERE DATAAREAID IS NULL;
*/

PRINT '============================================================';
PRINT 'Script 0002 completed successfully.';
PRINT 'Next: Run Script 0003 to create the CUSTTABLEVIEW.';
PRINT '============================================================';
GO
