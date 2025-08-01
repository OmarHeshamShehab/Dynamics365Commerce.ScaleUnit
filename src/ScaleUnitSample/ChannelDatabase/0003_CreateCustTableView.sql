-- ============================================================
-- Summary:
-- This script creates or recreates a SQL view named ext.CUSTTABLEVIEW
-- The view joins the base CUSTTABLE with its extension table CONTOSOCUSTTABLEEXTENSION
-- to expose extended fields REFNOEXT and an extended AccountNum alongside standard fields.
-- The view simplifies access to extended customer data for synchronization or reporting purposes.
--
-- Author      : [Omar Shehab]
-- ============================================================

-- Drop existing view if it exists to ensure the script can be rerun safely
IF OBJECT_ID('[ext].[CUSTTABLEVIEW]', 'V') IS NOT NULL
    DROP VIEW [ext].[CUSTTABLEVIEW];
GO

-- Create the view joining base CUSTTABLE with extension table on RECID
CREATE VIEW [ext].[CUSTTABLEVIEW] AS
SELECT
    ax.RECID               AS CUSTOMERRECID,      -- RECID from base table as unique identifier
    ax.ACCOUNTNUM          AS ACCOUNTNUM,         -- Standard account number from base table
    ISNULL(ext.REFNOEXT, '')     AS REFNOEXT,      -- Extended external reference number; empty string if NULL
    ISNULL(ext.AccountNum, '')   AS EXTACCOUNTNUM  -- Extended AccountNum field; empty string if NULL
FROM
    [ax].[CUSTTABLE] AS ax
LEFT JOIN
    [ext].[CONTOSOCUSTTABLEEXTENSION] AS ext
    ON ax.RECID = ext.RECID;                      -- Join on RECID to combine base and extended data
GO

-- Grant SELECT permission on the view to DataSyncUsersRole for read access during sync/data operations
GRANT SELECT
    ON OBJECT::[ext].[CUSTTABLEVIEW]
    TO [DataSyncUsersRole];
GO
