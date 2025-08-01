-- ============================================================
-- Summary:
--   Script 2: ALTER ext.CONTOSOCUSTTABLEEXTENSION
--   - Uses an EXT?schema view to back?fill DATAAREAID (no direct AX joins)
--   - Adds ACCOUNTNUM, DATAAREAID, ROWVERSION as needed
--   - Indexes on ROWVERSION & ACCOUNTNUM for performance
--   - Re?grants DML+ALTER to DataSyncUsersRole
--   - Fully “EXT?only” per best practices
-- Author      : [Omar Shehab]
-- Created     : 2025-07-28 (approximate)
-- ============================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

----------------------------------------------------------------
-- 0) Create?or?alter helper view (its own batch)
----------------------------------------------------------------
CREATE OR ALTER VIEW [ext].[Vw_CustTable_DataAreaID] AS
SELECT RECID, DATAAREAID
  FROM [ax].[CUSTTABLE];   -- Encapsulated AX access inside EXT view
GO

----------------------------------------------------------------
-- 1) Add ACCOUNTNUM if missing
----------------------------------------------------------------
IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION','ACCOUNTNUM') IS NULL
BEGIN
    ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
      ADD [ACCOUNTNUM] NVARCHAR(20) NOT NULL
        CONSTRAINT DF_CONTOSOCUST_ACCOUNTNUM DEFAULT(N'');  -- Customer account number
END
GO

----------------------------------------------------------------
-- 2) Add DATAAREAID as NULLABLE (back?fill next)
----------------------------------------------------------------
IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION','DATAAREAID') IS NULL
BEGIN
    ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
      ADD [DATAAREAID] NVARCHAR(4) NULL;  -- Temporarily allow NULLs
END
GO

----------------------------------------------------------------
-- 3) Back?fill DATAAREAID via the EXT view
----------------------------------------------------------------
UPDATE e
  SET e.DATAAREAID = v.DATAAREAID
FROM [ext].[CONTOSOCUSTTABLEEXTENSION] AS e
JOIN [ext].[Vw_CustTable_DataAreaID]      AS v
  ON v.RECID = e.RECID;
GO

----------------------------------------------------------------
-- 4) Enforce DATAAREAID NOT NULL now that it’s populated
----------------------------------------------------------------
ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
  ALTER COLUMN [DATAAREAID] NVARCHAR(4) NOT NULL;
GO

----------------------------------------------------------------
-- 5) Add ROWVERSION if missing
----------------------------------------------------------------
IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION','ROWVERSION') IS NULL
BEGIN
    ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
      ADD [ROWVERSION] ROWVERSION NOT NULL;  -- Real?time HWM
END
GO

----------------------------------------------------------------
-- 6) Ensure index on ROWVERSION
----------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns
     WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
       AND name = N'ROWVERSION'
)
AND NOT EXISTS (
    SELECT 1 FROM sys.indexes
     WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
       AND name = N'IX_CONTOSOCUSTTABLEEXTENSION_RowVersion'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion]
      ON [ext].[CONTOSOCUSTTABLEEXTENSION]([ROWVERSION]);
END
GO

----------------------------------------------------------------
-- 7) Ensure index on ACCOUNTNUM
----------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns
     WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
       AND name = N'ACCOUNTNUM'
)
AND NOT EXISTS (
    SELECT 1 FROM sys.indexes
     WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
       AND name = N'IX_CONTOSOCUSTTABLEEXTENSION_AccountNum'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CONTOSOCUSTTABLEEXTENSION_AccountNum]
      ON [ext].[CONTOSOCUSTTABLEEXTENSION]([ACCOUNTNUM]);
END
GO

----------------------------------------------------------------
-- 8) Re?grant full DML + ALTER to DataSyncUsersRole
----------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE, ALTER
  ON OBJECT::[ext].[CONTOSOCUSTTABLEEXTENSION]
  TO [DataSyncUsersRole];
GO
