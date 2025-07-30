-- ============================================================
-- Summary:
-- This script creates or replaces the stored procedure ext.UPDATECUSTOMEREXTENEDPROPERTIES.
-- The procedure updates or inserts (upserts) the REFNOEXT extended property
-- for a customer identified by AccountNum in the extension table CONTOSOCUSTTABLEEXTENSION.
-- It first looks up the customer RECID from the base CUSTTABLE and then performs a MERGE
-- to either update the existing record or insert a new one in the extension table.
-- Execution permission is granted to the DataSyncUsersRole for synchronization purposes.
--
-- Author      : [Omar Shehab]
-- Created     : 2025-07-28
-- ============================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Drop existing procedure if it exists to allow recreation
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

    -- Lookup the RECID of the customer in base AX.CUSTTABLE using AccountNum
    SELECT @RecId = RECID
      FROM [ax].[CUSTTABLE]
     WHERE ACCOUNTNUM = @AccountNum;

    -- Exit early if no matching customer found
    IF @RecId IS NULL
        RETURN;  -- nothing to do if no matching customer

    -- Perform UPSERT into the extension table:
    -- If a record with the RECID exists, update REFNOEXT
    -- Otherwise, insert a new record with RECID, AccountNum, and REFNOEXT
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

-- Grant execute permission on the procedure to the DataSyncUsersRole for sync operations
GRANT EXECUTE 
  ON OBJECT::[ext].[UPDATECUSTOMEREXTENEDPROPERTIES]
  TO [DataSyncUsersRole];
GO
