#!/bin/sh

exec 2>&1

echo "!!Kindly note, you should be in project root directory to execute this script!!"

echo "Compiling Project and creating jars"
mvn clean install -U
echo "Project Compilation should be Success!!"

echo "Creating docker images for Secure Auth Server & Mysql Server(used by Secure Auth Server)"
docker-compose -f ./scripts/deployment/dockerconf/secure-auth-server/docker-compose-dev.yaml up -d

echo "Sleeping for 10 seconds before checking if all dockers are up.."
sleep 10

echo "Creating default schema in mysql db.."
mysql -h 127.0.0.1 -P 5506 -u secure-auth -ppassword fps_acs < ./secure-auth-acs-dao/src/main/resources/sql/DDL.sql

echo "Inserting default values in newly created schema"
mysql -h 127.0.0.1 -P 5506 -u secure-auth -ppassword fps_acs < ./scripts/deployment/dev/dev-database-dml.sql

echo "Checking if Secure Auth Server is UP and running.."

TIMEOUT=20
ENDTIME=$(($(date +%s) + TIMEOUT))
SERVER_URL="http://127.0.0.1:8080/actuator/health"

while [ $(date +%s) -lt $ENDTIME ]; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" $SERVER_URL)
    if [ $STATUS -eq 200 ]; then
        echo "Server is up at http://127.0.0.1:8080 !!"
        break
    fi
    sleep 1
done