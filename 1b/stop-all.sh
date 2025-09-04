#!/bin/bash
echo "🛑 Stopping Blockscout services..."
cd blockscout/docker-compose
docker compose -f geth.yml down

echo "🛑 Stopping main services..."
cd ../..
docker compose down

echo "✅ All services stopped!"
