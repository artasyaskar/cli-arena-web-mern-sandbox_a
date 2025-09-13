#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'dockerize-for-production' task.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# --- Cleanup ---
cleanup() {
    echo "--- Cleaning up ---"
    docker rm -f client-prod-test server-prod-test || true
    docker rmi -f client:prod server:prod || true
}
trap cleanup EXIT

# --- Main execution ---

echo "--- Running the solution to create the Dockerfiles ---"
bash "tasks/dockerize-for-production/solution.sh"

echo "--- Building production images ---"
docker build -t client:prod -f "src/client/Dockerfile.prod" .
docker build -t server:prod -f "src/server/Dockerfile.prod" .

echo "--- Verifying image sizes ---"
# This is a simple check. A more robust check would compare against a baseline.
CLIENT_SIZE=$(docker images client:prod --format "{{.Size}}")
SERVER_SIZE=$(docker images server:prod --format "{{.Size}}")
echo "Client image size: $CLIENT_SIZE"
echo "Server image size: $SERVER_SIZE"
# A simple assertion that the images are not excessively large
if (( $(echo "$(echo $CLIENT_SIZE | sed 's/MB//') > 200" | bc -l) )); then
    echo "Client image size check failed: ${CLIENT_SIZE} is too large."
    exit 1
fi
if (( $(echo "$(echo $SERVER_SIZE | sed 's/MB//') > 300" | bc -l) )); then
    echo "Server image size check failed: ${SERVER_SIZE} is too large."
    exit 1
fi
echo "Image size checks passed."

echo "--- Running containers ---"
docker run -d --name client-prod-test -p 8082:80 client:prod
docker run -d --name server-prod-test -p 8083:8080 server:prod
sleep 10 # Give containers time to start

echo "--- Testing containers ---"
bash "tasks/dockerize-for-production/tests/test_docker_build.sh"

echo "✅ dockerize-for-production verified"
