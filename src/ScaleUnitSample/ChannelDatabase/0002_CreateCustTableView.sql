-- ============================================================
-- Script Name : 0004_CreateCustTableView.sql
-- Description : Creates a view joining CUSTTABLE with its
--               extension table to expose REFNOEXT and
--               extended AccountNum fields
-- Author      : [Omar Shehab]
-- ============================================================

-- Drop existing view if it exists
IF OBJECT_ID('[ext].[CUSTTABLEVIEW]', 'V') IS NOT NULL
    DROP VIEW [ext].[CUSTTABLEVIEW];
GO

-- Create the view that joins base CUSTTABLE with the extension
CREATE VIEW [ext].[CUSTTABLEVIEW] AS
SELECT
    ax.RECID               AS CUSTOMERRECID,      -- RECID from base table as unique identifier
    ax.ACCOUNTNUM          AS ACCOUNTNUM,         -- Standard field from CUSTTABLE
    ISNULL(ext.REFNOEXT, '')     AS REFNOEXT,      -- Extended external reference number
    ISNULL(ext.AccountNum, '')   AS EXTACCOUNTNUM  -- Extended AccountNum field
FROM
    [ax].[CUSTTABLE] AS ax
LEFT JOIN
    [ext].[CONTOSOCUSTTABLEEXTENSION] AS ext
    ON ax.RECID = ext.RECID;                      -- Join on RECID
GO

-- Grant SELECT permission to allow read access for sync/data layer
GRANT SELECT
    ON OBJECT::[ext].[CUSTTABLEVIEW]
    TO [DataSyncUsersRole];
GO
