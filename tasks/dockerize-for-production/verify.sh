#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'dockerize-for-production' task with enhanced checks.
# Note: The size comparison check has been removed as there is no dev Dockerfile for the server.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# --- Cleanup ---
cleanup() {
    echo "--- Cleaning up ---"
    sudo docker rm -f client-prod-test server-prod-test || true
    sudo docker rmi -f client:prod server:prod || true
}
trap cleanup EXIT

# --- Main execution ---

echo "--- Running the solution to create the Dockerfiles ---"
bash "tasks/dockerize-for-production/solution.sh"

echo "--- Building production images ---"
(cd src/client && sudo docker build -t client:prod -f Dockerfile.prod .)
(cd src/server && sudo docker build -t server:prod -f Dockerfile.prod .)

echo "--- Running containers ---"
sudo docker run -d --name client-prod-test -p 8082:80 client:prod
sudo docker run -d --name server-prod-test -p 8083:8080 server:prod
sleep 10 # Give containers time to start

echo "--- Verifying container runs as non-root user ---"
CLIENT_USER_ID=$(sudo docker exec client-prod-test id -u)
SERVER_USER_ID=$(sudo docker exec server-prod-test id -u)
if [ "$CLIENT_USER_ID" != "0" ]; then echo "Client user ID is non-root: $CLIENT_USER_ID. Check passed."; else echo "Client user ID is root. Check failed."; exit 1; fi
if [ "$SERVER_USER_ID" != "0" ]; then echo "Server user ID is non-root: $SERVER_USER_ID. Check passed."; else echo "Server user ID is root. Check failed."; exit 1; fi

echo "--- Verifying Nginx security headers ---"
HEADERS=$(curl -I http://localhost:8082)
if echo "$HEADERS" | grep -q "X-Frame-Options: SAMEORIGIN"; then echo "X-Frame-Options header found. Check passed."; else echo "X-Frame-Options header missing. Check failed."; exit 1; fi
if echo "$HEADERS" | grep -q "X-Content-Type-Options: nosniff"; then echo "X-Content-Type-Options header found. Check passed."; else echo "X-Content-Type-Options header missing. Check failed."; exit 1; fi

echo "--- Verifying no dev dependencies in production image ---"
if ! sudo docker exec server-prod-test npm ls nodemon; then echo "Dev dependency 'nodemon' not found. Check passed."; else echo "Dev dependency 'nodemon' found. Check failed."; exit 1; fi

echo "--- Verifying image security scanning (with Trivy) ---"
if ! command -v trivy &> /dev/null; then
    echo "Trivy could not be found, installing..."
    wget https://github.com/aquasecurity/trivy/releases/download/v0.29.2/trivy_0.29.2_Linux-64bit.tar.gz
    tar zxvf trivy_0.29.2_Linux-64bit.tar.gz
    sudo mv trivy /usr/local/bin/
fi
if sudo trivy image --severity HIGH,CRITICAL --exit-code 0 server:prod; then
    echo "Trivy scan passed for server image."
else
    echo "Trivy scan found HIGH or CRITICAL vulnerabilities in server image."
    exit 1
fi
if sudo trivy image --severity HIGH,CRITICAL --exit-code 0 client:prod; then
    echo "Trivy scan passed for client image."
else
    echo "Trivy scan found HIGH or CRITICAL vulnerabilities in client image."
    exit 1
fi

echo "--- Testing containers ---"
bash "tasks/dockerize-for-production/tests/test_docker_build.sh"

echo "✅ dockerize-for-production verified"
