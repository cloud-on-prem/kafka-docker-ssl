#!/bin/bash
set -euf -o pipefail

cd "$(dirname "$0"..)" || exit

echo "🧹  Stopping containers and cleaning up."
echo ""

docker-compose down

echo ""
echo "✨  All done."
