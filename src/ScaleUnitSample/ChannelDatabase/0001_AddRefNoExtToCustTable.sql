-- ============================================================
-- Script Name : 0001_AddRefNoExtToCustTable_ExtReplication.sql
-- Description : Creates or updates ext.CONTOSOCUSTTABLEEXTENSION
--               - Creates full table on first run
--               - On upgrades, safely adds DATAAREAID + replication cols
-- Author      : [Omar Shehab]
-- Created     : 2025?07?28
-- ============================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

------------------------------------------------------------
-- 1) First?time install: create full table with all columns
------------------------------------------------------------
IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NULL
BEGIN
    CREATE TABLE [ext].[CONTOSOCUSTTABLEEXTENSION](
        [RECID]                       BIGINT       NOT NULL,                     
        [REFNOEXT]                    NVARCHAR(255) NOT NULL DEFAULT(N''),     
        [ACCOUNTNUM]                  NVARCHAR(20)  NOT NULL DEFAULT(N''),     

        -- no need for a default here; proc will supply the right 4?char company
        [DATAAREAID]                  NVARCHAR(4)   NOT NULL,                  

        -- CDX pull fields
        [REPLICATIONCOUNTERFROMORIGIN] INT           IDENTITY(1,1) NOT NULL,
        [ROWVERSION]                  ROWVERSION    NOT NULL,

        CONSTRAINT [PK_CONTOSOCUSTTABLEEXTENSION]
            PRIMARY KEY CLUSTERED ([RECID])
    );
END
ELSE
BEGIN
    ----------------------------------------------------------------
    -- 2) Upgrade path: table exists and may already have data
    ----------------------------------------------------------------

    -- 2a) Add DATAAREAID as nullable
    IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'DATAAREAID') IS NULL
    BEGIN
        ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ADD [DATAAREAID] NVARCHAR(4) NULL;
        
        -- 2b) Back?fill from the base AX table
        UPDATE e
        SET e.DATAAREAID = c.DATAAREAID
        FROM [ext].[CONTOSOCUSTTABLEEXTENSION] AS e
        INNER JOIN [ax].[CUSTTABLE] AS c
            ON c.RECID = e.RECID;

        -- 2c) Make DATAAREAID NOT NULL
        ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ALTER COLUMN [DATAAREAID] NVARCHAR(4) NOT NULL;
    END

    -- 2d) Add REPLICATIONCOUNTERFROMORIGIN if missing
    IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'REPLICATIONCOUNTERFROMORIGIN') IS NULL
        ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ADD [REPLICATIONCOUNTERFROMORIGIN] INT IDENTITY(1,1) NOT NULL;

    -- 2e) Add ROWVERSION if missing
    IF COL_LENGTH('ext.CONTOSOCUSTTABLEEXTENSION', 'ROWVERSION') IS NULL
        ALTER TABLE [ext].[CONTOSOCUSTTABLEEXTENSION]
        ADD [ROWVERSION] ROWVERSION NOT NULL;
END
GO

------------------------------------------------------------
-- 3) Index the replication counter for efficient pulls
------------------------------------------------------------
IF EXISTS (
    SELECT 1 
      FROM sys.columns
     WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
       AND name = N'REPLICATIONCOUNTERFROMORIGIN'
)
AND NOT EXISTS (
    SELECT 1 
      FROM sys.indexes 
     WHERE object_id = OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]')
       AND name = N'IX_CONTOSOCUSTTABLEEXTENSION_ReplCnt'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_CONTOSOCUSTTABLEEXTENSION_ReplCnt
      ON [ext].[CONTOSOCUSTTABLEEXTENSION]([REPLICATIONCOUNTERFROMORIGIN]);
END
GO

------------------------------------------------------------
-- 4) Grant full DML & ALTER to the sync role
------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE, ALTER
  ON OBJECT::[ext].[CONTOSOCUSTTABLEEXTENSION]
  TO [DataSyncUsersRole];
GO
