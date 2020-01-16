#!/bin/bash
set -euf -o pipefail

cd "$(dirname "$0"..)" || exit

echo "🌲  Here are some logs"
sleep 2

docker-compose logs --follow
