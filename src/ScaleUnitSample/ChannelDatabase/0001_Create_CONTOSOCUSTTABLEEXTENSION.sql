-- ============================================================
-- Summary:
--   Script 1: Initial CREATE of ext.CONTOSOCUSTTABLEEXTENSION
--   - No direct CRT/AX access
--   - Columns: RECID, REFNOEXT, DATAAREAID, ROWVERSION
--   - Nonclustered index on ROWVERSION for real-time HWM
--   - Grants DML+ALTER to DataSyncUsersRole
--   - Designed for real-time services sync (no batch jobs)
-- Author      : [Omar Shehab]
-- Created     : 2025-07-28 (approximate)
-- ============================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1) Create the table if it doesn’t already exist
IF OBJECT_ID(N'[ext].[CONTOSOCUSTTABLEEXTENSION]', 'U') IS NULL
BEGIN
    CREATE TABLE [ext].[CONTOSOCUSTTABLEEXTENSION](
        [RECID]      BIGINT      NOT NULL,              -- PK from HQ
        [REFNOEXT]   NVARCHAR(255) NOT NULL 
                     CONSTRAINT DF_CONTOSOCUST_RENOEXT DEFAULT(N''),  -- External ref
        -- ACCOUNTNUM deferred to ALTER script
        [DATAAREAID] NVARCHAR(4)   NOT NULL,             -- 4-char company identifier
        [ROWVERSION] ROWVERSION    NOT NULL              -- Change-tracking HWM

      , CONSTRAINT [PK_CONTOSOCUSTTABLEEXTENSION]
          PRIMARY KEY CLUSTERED ([RECID])
    );

    -- 2) Support real-time change pulls with an index on ROWVERSION
    CREATE NONCLUSTERED INDEX [IX_CONTOSOCUSTTABLEEXTENSION_RowVersion]
      ON [ext].[CONTOSOCUSTTABLEEXTENSION]([ROWVERSION]);
END
GO

-- 3) Grant sync role full DML + ALTER permissions
GRANT SELECT, INSERT, UPDATE, DELETE, ALTER
  ON OBJECT::[ext].[CONTOSOCUSTTABLEEXTENSION]
  TO [DataSyncUsersRole];
GO
