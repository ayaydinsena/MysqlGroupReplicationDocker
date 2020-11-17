#!/bin/bash

docker-compose down
rm -rf ./master/data/*
rm -rf ./slave/data/*
rm -rf ./slave2/data/*
docker-compose build
docker-compose up -d



docker-ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}

docker exec mysql_master sh -c "echo '$(docker-ip mysql_master) master' >> /etc/hosts"
echo "Master server add a master domain in /etc/hosts"
docker exec mysql_master sh -c "echo '$(docker-ip mysql_slave) slave' >> /etc/hosts"
echo "Master server add a slave domain in /etc/hosts"
docker exec mysql_master sh -c "echo '$(docker-ip mysql_slave2) slave2' >> /etc/hosts"
 echo "Master server add a slave2 domain in /etc/hosts"
docker exec mysql_slave sh -c "echo '$(docker-ip mysql_master) master' >> /etc/hosts"
 echo "Slave server add a master domain in /etc/hosts"
docker exec mysql_slave sh -c "echo '$(docker-ip mysql_slave) slave' >> /etc/hosts"
echo "Slave server add a slave domain in /etc/hosts"
docker exec mysql_slave sh -c "echo '$(docker-ip mysql_slave2) slave2' >> /etc/hosts"
echo "Slave server add a slave2 domain in /etc/hosts"
docker exec mysql_slave2 sh -c "echo '$(docker-ip mysql_master) master' >> /etc/hosts"
echo "Slave2 server add a master domain in /etc/hosts"
docker exec mysql_slave2 sh -c "echo '$(docker-ip mysql_slave) slave' >> /etc/hosts"
 echo "Slave2 server add a slave domain in /etc/hosts"
 docker exec mysql_slave2 sh -c "echo '$(docker-ip mysql_slave2) slave2' >> /etc/hosts"
 echo "Slave2 server add a slave2 domain in /etc/hosts"


until docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done

priv_stmt="SET SQL_LOG_BIN=0; GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'; FLUSH PRIVILEGES; SET SQL_LOG_BIN=1; CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery'; INSTALL PLUGIN group_replication SONAME 'group_replication.so'; reset master; reset slave; SET GLOBAL group_replication_bootstrap_group=ON; START GROUP_REPLICATION; SET GLOBAL group_replication_bootstrap_group=OFF;"
start_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_cmd+="$priv_stmt"
start_cmd+='"'
docker exec mysql_master sh -c "$start_cmd"



until docker-compose exec mysql_slave sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave database connection..."
    sleep 4
done
priv_stsl="SET SQL_LOG_BIN=0; GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'; FLUSH PRIVILEGES; SET SQL_LOG_BIN=1; CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery'; INSTALL PLUGIN group_replication SONAME 'group_replication.so'; reset master; reset slave; START GROUP_REPLICATION;"
start_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_cmd+="$priv_stsl"
start_cmd+='"'
docker exec mysql_slave sh -c "$start_cmd"

until docker-compose exec mysql_slave2 sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave2 database connection..."
    sleep 4
done
priv_stsla="SET SQL_LOG_BIN=0; GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'; FLUSH PRIVILEGES; SET SQL_LOG_BIN=1; CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery'; INSTALL PLUGIN group_replication SONAME 'group_replication.so'; reset master; reset slave; START GROUP_REPLICATION;"
start_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_cmd+="$priv_stsla"
start_cmd+='"'
docker exec mysql_slave2 sh -c "$start_cmd"

docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e 'SELECT * FROM performance_schema.replication_group_members;'"
docker exec mysql_slave sh -c "export MYSQL_PWD=111; mysql -u root -e 'SELECT * FROM performance_schema.replication_group_members;'"
docker exec mysql_slave2 sh -c "export MYSQL_PWD=111; mysql -u root -e 'SELECT * FROM performance_schema.replication_group_members;'"