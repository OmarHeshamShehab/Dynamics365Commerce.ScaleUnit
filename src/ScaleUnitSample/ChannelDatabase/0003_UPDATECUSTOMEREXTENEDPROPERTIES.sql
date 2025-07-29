-- ============================================================
-- Script Name : 0010_UPDATECUSTOMEREXTENEDPROPERTIES.sql
-- Description : Create or replace ext.UPDATECUSTOMEREXTENEDPROPERTIES
-- Author      : [Omar Shehab]
-- Created     : 2025-07-28
-- ============================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- If it already exists, drop it (so CREATE will work)
IF OBJECT_ID(N'[ext].[UPDATECUSTOMEREXTENEDPROPERTIES]', 'P') IS NOT NULL
    DROP PROCEDURE [ext].[UPDATECUSTOMEREXTENEDPROPERTIES];
GO

CREATE PROCEDURE [ext].[UPDATECUSTOMEREXTENEDPROPERTIES]
    @AccountNum NVARCHAR(20),
    @REFNOEXT   NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RecId BIGINT;

    -- lookup the parent RECID in AX.CUSTTABLE
    SELECT @RecId = RECID
      FROM [ax].[CUSTTABLE]
     WHERE ACCOUNTNUM = @AccountNum;

    IF @RecId IS NULL
        RETURN;  -- nothing to do if no matching customer

    -- upsert into your EXT table
    MERGE INTO [ext].[CONTOSOCUSTTABLEEXTENSION] AS Target
    USING (VALUES(@RecId, @AccountNum, @REFNOEXT))
          AS Source(RECID, ACCOUNTNUM, REFNOEXT)
      ON Target.RECID = Source.RECID
    WHEN MATCHED THEN
      UPDATE SET REFNOEXT = Source.REFNOEXT
    WHEN NOT MATCHED THEN
      INSERT (RECID, ACCOUNTNUM, REFNOEXT)
      VALUES (Source.RECID, Source.ACCOUNTNUM, Source.REFNOEXT);
END;
GO

GRANT EXECUTE 
  ON OBJECT::[ext].[UPDATECUSTOMEREXTENEDPROPERTIES]
  TO [DataSyncUsersRole];
GO
