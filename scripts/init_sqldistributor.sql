-- step 1, tell this server it is a distributor
EXEC sp_adddistributor @distributor = 'sqldistributor', @password = 'Pa^^w0rd'

-- step 2, create the distribution db
EXEC sp_adddistributiondb @database = 'distribution';

-- step 3, tell the distributor who the publisher is
-- NOTE! (make the directory '/var/opt/mssql/ReplData',
-- it doesn't exist and this command will try and verify that it does)
-- docker exec -it distributor bin/bash
-- mkdir /var/opt/mssql/ReplData
-- CTRL+Z get back out
EXEC sp_adddistpublisher @publisher = 'sqlsource', @distribution_db = 'distribution'

update msdb.dbo.sysjobs set enabled = 1 where name = 'Replication monitoring refresher for distribution.'
