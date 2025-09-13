#!/usr/bin/env bash
set -euo pipefail

# This script improves the robustness of the Docker Compose setup.

echo "--- Applying solution for task: devops-docker-healthcheck ---"

# 1. Create the wait script
mkdir -p scripts
cat > scripts/wait-for-services.sh << 'EOF'
#!/bin/sh
# wait-for-services.sh

set -e

# Usage: wait-for-services.sh host:port host:port ...
# Example: wait-for-services.sh mongo:27017 redis:6379

for service in "$@"
do
  host=$(echo $service | cut -d: -f1)
  port=$(echo $service | cut -d: -f2)

  echo "Waiting for $host:$port..."

  # Use netcat (nc) if available, otherwise fallback to a simple loop
  # The 'development' docker image (node:18-alpine) has netcat.
  while ! nc -z $host $port; do
    sleep 1
  done

  echo "$host:$port is up!"
done

# Execute the command passed after the services
exec "${@:1}"
EOF

# Make the script executable
chmod +x scripts/wait-for-services.sh


# 2. Overwrite docker-compose.yml with the new, robust version
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
    working_dir: /app/server
    ports:
      - "8080:8080"
      - "3000:3000"
    environment:
      - MONGO_URI=mongodb://mongo:27017/mern-sandbox?replicaSet=rs0
      - REDIS_URL=redis://redis:6379
      - PORT=8080
      - CHOKIDAR_USEPOLLING=true
    depends_on:
      mongo:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./src/server:/app/server
      - ./src/client:/app/client
      - ./scripts:/app/scripts
      - server_node_modules:/app/server/node_modules
      - client_node_modules:/app/client/node_modules
    # The command now uses the wait script before starting the server
    command: sh -c "/app/scripts/wait-for-services.sh mongo:27017 redis:6379 && npm run dev"

  mongo:
    image: mongo:latest
    command: ["--replSet", "rs0", "--bind_ip_all"]
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    healthcheck:
      test: |
        mongosh --eval 'try { rs.status().ok } catch (e) { rs.initiate({ _id: "rs0", members: [ { _id: 0, host: "localhost:27017" } ] ) }'
      interval: 5s
      timeout: 30s
      start_period: 5s
      retries: 5

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  mongo-express:
    image: mongo-express:latest
    ports:
      - "8081:8081"
    environment:
      - ME_CONFIG_MONGODB_SERVER=mongo
      - ME_CONFIG_MONGODB_PORT=27017
      - ME_CONFIG_MONGODB_ENABLE_ADMIN=false
      - ME_CONFIG_MONGODB_AUTH_DATABASE=admin
      - ME_CONFIG_MONGODB_REPLICA_SET_NAME=rs0
    depends_on:
      - mongo

volumes:
  mongo-data:
  server_node_modules:
  client_node_modules:
EOF

echo "--- Docker Compose setup improved successfully. ---"
