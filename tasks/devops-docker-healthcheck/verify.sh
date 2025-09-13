#!/usr/bin/env bash
set -euo pipefail

# Get the root directory of the project
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# Function to clean up services on script exit
cleanup() {
    echo "--- Cleaning up services ---"
    docker compose -f docker-compose.yml down --volumes --remove-orphans
}
trap cleanup EXIT

echo "--- Starting services for devops-docker-healthcheck ---"
# Use the main docker-compose file for this task
docker compose -f docker-compose.yml up -d

echo "Waiting for services to become healthy..."

# Wait for Mongo to be healthy
echo "Waiting for mongo..."
for i in {1..15}; do
    if [ "$(docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q mongo)")" = "healthy" ]; then
        break
    fi
    sleep 4
done
if [ "$(docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q mongo)")" != "healthy" ]; then
    echo "FAIL: Mongo container did not become healthy in time."
    docker logs "$(docker compose ps -q mongo)"
    exit 1
fi

# Wait for Redis to be healthy, if it exists
if docker compose ps -q redis > /dev/null 2>&1; then
    echo "Waiting for redis..."
    for i in {1..15}; do
        if [ "$(docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q redis)")" = "healthy" ]; then
            break
        fi
        sleep 4
    done
    if [ "$(docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q redis)")" != "healthy" ]; then
        echo "FAIL: Redis container did not become healthy in time."
        docker logs "$(docker compose ps -q redis)"
        exit 1
    fi
fi


echo "--- Verifying container health ---"

# Check Mongo health
MONGO_HEALTH=$(docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q mongo)")
if [ "$MONGO_HEALTH" != "healthy" ]; then
    echo "FAIL: Mongo container is not healthy. Status: $MONGO_HEALTH"
    docker logs "$(docker compose ps -q mongo)"
    exit 1
fi
echo "PASS: Mongo container is healthy."

# Check Redis health (if it exists in the compose file)
if docker compose ps -q redis > /dev/null 2>&1; then
    REDIS_HEALTH=$(docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q redis)")
    if [ "$REDIS_HEALTH" != "healthy" ]; then
        echo "FAIL: Redis container is not healthy. Status: $REDIS_HEALTH"
        docker logs "$(docker compose ps -q redis)"
        exit 1
    fi
    echo "PASS: Redis container is healthy."
else
    echo "INFO: Redis container not found in docker-compose.yml, skipping health check."
fi


# Optional: Keep a minimal grep to check for the wait script, as allowed.
echo "--- Verifying API service configuration ---"
if ! grep -q "wait-for-services.sh" "docker-compose.yml"; then
    echo "FAIL: The api service command in docker-compose.yml does not use the wait-for-services.sh script."
    exit 1
fi
echo "PASS: API service uses the wait script."

echo "✅ devops-docker-healthcheck verified"
