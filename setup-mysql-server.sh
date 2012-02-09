#!/bin/bash

set -ex

usage() {
cat <<EOF
Usage: $SCRIPT_NAME <MYSQL-ROOT-PASSWORD> 
Example: $SCRIPT_NAME  mysqlsecret
EOF
}

if [ $# -ne 1 ]; then
   usage
   exit 1
fi

#export DEBIAN_FRONTEND=noninteractive
PASSWORD=$1

#TODO -> make apt-get non-interactive and no ouptut
install_updates() {
sudo apt-get update && sudo apt-get upgrade -y
}

install_baseline() {
sudo apt-get install -y git-core build-essential curl
}

install_mysql() {
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
}

install_updates && install_baseline && install_mysql
out=$?
if [ $out -ne 0 ]; then
    die "$SCRIPT_NAME Couldnt complete Mysql Install" out
    usage
    exit out 
fi

sleep 3 #waiting for mysql to restart
mysqladmin -uroot password $PASSWORD
sudo service mysql restart


set +ex



