# SQL Server Replication to S3 via Kafka and Kafka Connect

## Prerequisites:
* Docker, with 8Gb allocated.
* Terraform installed
* AWS Commandline installed, API / secret
* Make installed

## Setting up AWS Environment

* Create .env file
```
#Generate globally unique strings...
#openssl rand -hex 6
export TF_VAR_REGION=""
export TF_VAR_BUCKET_NAME=""
export TF_VAR_BUCKET_KEY=""
export TF_VAR_WENDYS_BUCKET=""
export TF_VAR_WENDYS_STREAM=""
export KAFKA_TOPIC="sqldestination.dbo.TESTTABLE"
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

```
* Initialize AWS Infrastructure
```
make initinfra
```
* Destroy AWS Infrastructure
```
make cleaninfra
```
* Initialize Docker stuff
```
make initdocker
```
* Configure SQL Servers
```
make configuresql
```
* Insert record(s)
```
docker exec -u 0 -it sqlsource /opt/mssql-tools/bin/sqlcmd -S . -U sa -P Pa^^w0rd -i /var/scripts/insert.sql
```
* View record(s)
```
docker exec -u 0 -it sqlsource /opt/mssql-tools/bin/sqlcmd -S . -U sa -P Pa^^w0rd -i /var/scripts/selectrecords.sql
docker exec -u 0 -it sqldestination /opt/mssql-tools/bin/sqlcmd -S . -U sa -P Pa^^w0rd -i /var/scripts/selectrecords.sql
```
* Log into AWS Console, navigate to S3 and view record. NOTE: It should show up a minute or two after SQLDestination gets record.

* NOTE: You may have to restart the connector container.