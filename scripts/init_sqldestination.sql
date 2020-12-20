CREATE DATABASE TestDB;
GO
USE TestDB;
GO
CREATE TABLE TESTTABLE
(
    [TestID] [INT] NOT NULL,
    [TestString] [VARCHAR](40)
);
GO

-- add a PK (we can't replicate without one)
ALTER TABLE TESTTABLE ADD PRIMARY KEY (TestID);

--KAFKA STUFF
EXEC sys.sp_cdc_enable_db
EXEC sys.sp_cdc_enable_table
@source_schema = N'dbo',
@source_name   = N'TESTTABLE',
@role_name     = NULL,
@supports_net_changes = 0

EXEC sys.sp_cdc_help_change_data_capture