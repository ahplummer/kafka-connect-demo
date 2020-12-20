.DEFAULT_GOAL := help

help:
	@echo You have several options:
	@echo Use "make initinfra" to build AWS infra, based on .env file in this directory.
	@echo Use "make cleaninfra" to destroy AWS infra.
	@echo Use "make initdocker" to build up docker.
	@echo Use "make configuresql" to configure SQL Servers.
	@echo Use "make cleandocker" to destroy all the Docker images and volumes.
	@echo Use "make startdocker" to start up all the containers.
	@echo Use "make stopdocker" to stop all the containers.

initinfra:
	source .env && pushd ./awsinfra && terraform init && terraform apply -auto-approve && popd

cleaninfra:
	source .env && pushd ./awsinfra && terraform destroy -auto-approve && rm -rf .terraform && popd

cleandocker: stopdocker
	rm -rf sqldistributor
	rm -rf sqldestination
	rm -rf sqlsource

startdocker:
	docker-compose up -d
	docker exec -u 0 -it connector /var/scripts/wait.sh -t 0 connector:8083 -- echo 'kafka connect is serving'
	docker exec -u 0 -it connector sleep 10s
	docker exec -u 0 -it connector curl -X POST -H "Content-Type: application/json" -d @/var/scripts/SQLConnector.json http://connector:8083/connectors

stopdocker:
	docker-compose down

initdocker:
	docker-compose up -d
	docker exec -u 0 -it sqldistributor mkdir /var/opt/mssql/ReplData
	docker exec -u 0 -it sqldistributor /var/scripts/wait.sh -t 0 localhost:1433 -- echo 'sqldistributor is hot'
	docker exec -u 0 -it sqldestination /opt/mssql/bin/mssql-conf set sqlagent.enabled true
	docker exec -u 0 -it sqlsource /opt/mssql/bin/mssql-conf set sqlagent.enabled true
	docker exec -u 0 -it sqldistributor /opt/mssql/bin/mssql-conf set sqlagent.enabled true
	docker-compose down
	docker-compose up -d
	docker exec -u 0 -it sqldistributor /var/scripts/wait.sh -t 0 localhost:1433 -- echo 'sqldistributor is hot'
	docker exec -u 0 -it connector /var/scripts/wait.sh -t 0 connector:8083 -- echo 'kafka connect is serving'
	docker exec -u 0 -it connector sleep 10s
	docker exec -u 0 -it connector curl -X POST -H "Content-Type: application/json" -d @/var/scripts/SQLConnector.json http://connector:8083/connectors

configuresql:
	docker exec -u 0 -it sqldistributor /var/scripts/configure.sh
	docker exec -u 0 -it sqldestination /var/scripts/configure.sh
	docker exec -u 0 -it sqlsource /var/scripts/configure.sh
	docker-compose down
	docker-compose up -d
	docker exec -u 0 -it connector /var/scripts/wait.sh -t 0 connector:8083 -- echo 'kafka connect is serving'
	docker exec -u 0 -it connector sleep 10s
	docker exec -u 0 -it connector curl -X POST -H "Content-Type: application/json" -d @/var/scripts/SQLConnector.json http://connector:8083/connectors
