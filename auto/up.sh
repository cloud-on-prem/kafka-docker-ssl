#!/bin/bash
set -euf -o pipefail

cd "$(dirname "$0"..)" || exit

echo "🔊  Setting up some volumes for persistence."

docker volume create --name zk-data > /dev/null
docker volume create --name zk-txn-logs > /dev/null
docker volume create --name kafka-data > /dev/null

# Don't need kafka-tools to start up
docker-compose up --detach --scale kafka-tools=0

echo ""
echo "🐳  Kicked off the containers. Should be up in one minute (literally)."
echo ""
echo "😬  If you can't contain your curiousity, run ./auto/logs.sh"
echo ""
echo "🏗  Head over to http://localhost:9021 to verify that everything is up."

echo ""
echo "💥 kafka"
