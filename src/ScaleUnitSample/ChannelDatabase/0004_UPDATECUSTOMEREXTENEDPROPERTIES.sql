-- ============================================================
-- Script      : 0004_UPDATECUSTOMEREXTENEDPROPERTIES.sql
-- Summary     : Creates the ext.UPDATECUSTOMEREXTENEDPROPERTIES
--               stored procedure for upserting customer extensions.
--
-- Purpose     : Provides an atomic upsert operation to add or update
--               the REFNOEXT (external reference) field for a customer
--               in the extension table.
--
-- Pattern     : D365 Commerce Channel Database Extension Procedure
-- Schema      : ext (extension schema per Microsoft guidelines)
--
-- Parameters  : @AccountNum  - Customer account number (lookup key)
--               @DataAreaId  - Company identifier (required for multi-company)
--               @REFNOEXT    - External reference value to set
--
-- Operation   : 1. Lookup RECID from ax.CUSTTABLE by AccountNum + DataAreaId
--               2. MERGE into extension table (update if exists, insert if not)
--
-- Deployment  : This script runs BEFORE CDX sync populates ax tables.
--               The procedure is created and will function correctly once
--               ax.CUSTTABLE is populated by CDX.
--
-- Note        : Procedure name contains typo "EXTENED" (missing D).
--               Kept for backward compatibility with existing callers.
--               Correct spelling would be "EXTENDEDPROPERTIES".
--
-- Dependencies: ext.CONTOSOCUSTTABLEEXTENSION must exist (Script 0001/0002)
--               ax.CUSTTABLE will be populated by CDX sync after deployment
--
-- Author      : Omar Shehab
-- Created     : 2025-07-28
-- Modified    : 2026-03-18 (Refactored for best practices, added DataAreaId)
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
    PRINT 'INFO: The procedure will function correctly after CDX sync populates the ax schema tables.';
END

IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NULL
BEGIN
    PRINT 'WARNING: Table [ext].[CONTOSOCUSTTABLEEXTENSION] does not exist. Run Scripts 0001 and 0002 first.';
END
GO

-- ============================================================
-- CREATE OR ALTER STORED PROCEDURE
-- Microsoft Ref: CREATE OR ALTER is preferred over DROP + CREATE
--                - Atomic operation
--                - Preserves existing permissions
-- ============================================================
PRINT 'Creating/updating stored procedure [ext].[UPDATECUSTOMEREXTENEDPROPERTIES]...';
GO

CREATE OR ALTER PROCEDURE [ext].[UPDATECUSTOMEREXTENEDPROPERTIES]
    -- --------------------------------------------------------
    -- Parameters
    -- --------------------------------------------------------
    @AccountNum  NVARCHAR(20),   -- Customer account number (e.g., 'US-001')
    @DataAreaId  NVARCHAR(4),    -- Company identifier (e.g., 'USMF')
    @REFNOEXT    NVARCHAR(255)   -- External reference number to set
AS
BEGIN
    -- --------------------------------------------------------
    -- Settings
    -- --------------------------------------------------------
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- Ensures atomic rollback on error
    
    -- --------------------------------------------------------
    -- Input validation
    -- --------------------------------------------------------
    IF @AccountNum IS NULL OR LTRIM(RTRIM(@AccountNum)) = N''
    BEGIN
        RAISERROR('ERROR: @AccountNum parameter is required and cannot be empty.', 16, 1);
        RETURN -1;
    END
    
    IF @DataAreaId IS NULL OR LTRIM(RTRIM(@DataAreaId)) = N''
    BEGIN
        RAISERROR('ERROR: @DataAreaId parameter is required and cannot be empty.', 16, 1);
        RETURN -1;
    END
    
    -- --------------------------------------------------------
    -- Variable declarations
    -- --------------------------------------------------------
    DECLARE @RecId BIGINT;
    
    -- --------------------------------------------------------
    -- Lookup customer RECID from base table
    -- Microsoft Ref: Always filter by DATAAREAID in multi-company environments
    -- --------------------------------------------------------
    SELECT @RecId = [RECID]
    FROM [ax].[CUSTTABLE]
    WHERE [ACCOUNTNUM] = @AccountNum
      AND [DATAAREAID] = @DataAreaId;
    
    -- Validate customer exists
    IF @RecId IS NULL
    BEGIN
        RAISERROR('ERROR: Customer with AccountNum ''%s'' not found in company ''%s''.', 16, 1, @AccountNum, @DataAreaId);
        RETURN -1;
    END
    
    -- --------------------------------------------------------
    -- Upsert into extension table using MERGE
    -- Microsoft Ref: MERGE provides atomic insert-or-update
    -- --------------------------------------------------------
    BEGIN TRY
        MERGE INTO [ext].[CONTOSOCUSTTABLEEXTENSION] AS Target
        USING (
            SELECT 
                @RecId      AS [RECID],
                @AccountNum AS [ACCOUNTNUM],
                @DataAreaId AS [DATAAREAID],
                @REFNOEXT   AS [REFNOEXT]
        ) AS Source
        ON Target.[RECID] = Source.[RECID]
        
        -- Update existing record
        WHEN MATCHED THEN
            UPDATE SET 
                [REFNOEXT]   = Source.[REFNOEXT],
                [ACCOUNTNUM] = Source.[ACCOUNTNUM]  -- Keep AccountNum in sync
        
        -- Insert new record
        WHEN NOT MATCHED THEN
            INSERT ([RECID], [ACCOUNTNUM], [DATAAREAID], [REFNOEXT])
            VALUES (Source.[RECID], Source.[ACCOUNTNUM], Source.[DATAAREAID], Source.[REFNOEXT]);
        
        RETURN 0;  -- Success
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('ERROR during MERGE operation: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
        RETURN -1;
    END CATCH
END
GO

PRINT 'Stored procedure created/updated successfully.';
GO

-- ============================================================
-- GRANT PERMISSIONS
-- Microsoft Ref: DataSyncUsersRole needs EXECUTE for CRT operations
-- ============================================================
PRINT 'Granting EXECUTE permission to [DataSyncUsersRole]...';

GRANT EXECUTE
    ON OBJECT::[ext].[UPDATECUSTOMEREXTENEDPROPERTIES]
    TO [DataSyncUsersRole];

PRINT 'Permission granted successfully.';
GO

-- ============================================================
-- POST-EXECUTION VALIDATION (uncomment to verify after CDX sync)
-- ============================================================
/*
-- Verify procedure exists
SELECT 
    SCHEMA_NAME(schema_id) AS [Schema],
    name AS [Procedure],
    create_date,
    modify_date
FROM sys.procedures
WHERE name = 'UPDATECUSTOMEREXTENEDPROPERTIES';

-- Verify parameters
SELECT 
    PARAMETER_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    PARAMETER_MODE
FROM INFORMATION_SCHEMA.PARAMETERS
WHERE SPECIFIC_SCHEMA = 'ext'
  AND SPECIFIC_NAME = 'UPDATECUSTOMEREXTENEDPROPERTIES'
ORDER BY ORDINAL_POSITION;

-- Test execution (use a valid AccountNum from your USMF data, run after CDX sync)
EXEC [ext].[UPDATECUSTOMEREXTENEDPROPERTIES]
    @AccountNum = 'US-001',
    @DataAreaId = 'USMF',
    @REFNOEXT   = 'TEST-REF-001';

-- Verify the record was created/updated
SELECT * 
FROM [ext].[CONTOSOCUSTTABLEEXTENSION]
WHERE ACCOUNTNUM = 'US-001';
*/

PRINT '============================================================';
PRINT 'Script 0004 completed successfully.';
PRINT 'All Channel Database extension scripts are now deployed.';
PRINT '============================================================';
GO

-- ============================================================
-- USAGE EXAMPLES (run after CDX sync has populated ax tables)
-- ============================================================
/*
-- Example 1: Add/update REFNOEXT for customer US-001 in USMF
EXEC [ext].[UPDATECUSTOMEREXTENEDPROPERTIES]
    @AccountNum = 'US-001',
    @DataAreaId = 'USMF',
    @REFNOEXT   = 'EXT-REF-12345';

-- Example 2: Query the combined view to verify
SELECT * 
FROM [ext].[CUSTTABLEVIEW]
WHERE ACCOUNTNUM = 'US-001' 
  AND DATAAREAID = 'USMF';

-- Example 3: Direct query to extension table
SELECT * 
FROM [ext].[CONTOSOCUSTTABLEEXTENSION]
WHERE DATAAREAID = 'USMF'
ORDER BY ACCOUNTNUM;
*/
