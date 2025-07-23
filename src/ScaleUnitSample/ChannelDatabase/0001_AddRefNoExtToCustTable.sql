-- ============================================================
-- Script Name : 0001_AddRefNoExtAndAccountNumToCustTable.sql
-- Description : Creates an extension table for the CUSTTABLE
--               to store new fields REFNOEXT (nvarchar(255))
--               and AccountNum (nvarchar(20))
-- Author      : [Omar Shehab]
-- ============================================================

-- Check if the extension table does not exist
IF OBJECT_ID('[ext].[CONTOSOCUSTTABLEEXTENSION]') IS NULL
BEGIN
    -- Create the extension table for CUSTTABLE
    CREATE TABLE [ext].[CONTOSOCUSTTABLEEXTENSION] (
        [RECID]       BIGINT       NOT NULL,                       -- Primary key, must match CUSTTABLE.RECID
        [REFNOEXT]    NVARCHAR(255) NOT NULL DEFAULT(N''),         -- New field for external reference number
        [ACCOUNTNUM]  NVARCHAR(20)  NOT NULL DEFAULT(N''),         -- New field for account number

        -- Define primary key constraint
        CONSTRAINT [PK_CONTOSOCUSTTABLEEXTENSION]
            PRIMARY KEY CLUSTERED ([RECID])
    );
END
GO

-- Grant necessary DML permissions to DataSyncUsersRole
GRANT SELECT, INSERT, UPDATE, DELETE
    ON OBJECT::[ext].[CONTOSOCUSTTABLEEXTENSION]
    TO [DataSyncUsersRole];
GO
