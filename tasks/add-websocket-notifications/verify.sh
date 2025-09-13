#!/usr/bin/env bash
set -euo pipefail

# Get the root directory of the project
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# Function to clean up services on script exit
cleanup() {
    echo "--- Cleaning up services ---"
    docker compose -f docker-compose.test.yml down --volumes --remove-orphans
}
trap cleanup EXIT

echo "--- Starting services for add-websocket-notifications ---"
docker compose -f docker-compose.test.yml up -d --wait || docker compose -f docker-compose.test.yml up -d

# Wait for services to be ready
echo "Waiting for services to start..."
npx wait-on tcp:27017 --timeout 60000

echo "--- Installing dependencies ---"
npm ci
(cd src/server && npm ci)

echo "--- Running verification for add-websocket-notifications ---"

# Set a unique database for this test run
export MONGO_URI_TEST="mongodb://localhost:27017/add-websocket-notifications-$RANDOM"

# Run the specific test file for this task
npx jest --runInBand "tasks/add-websocket-notifications/tests/websocket.test.ts"

echo "✅ add-websocket-notifications verified"
