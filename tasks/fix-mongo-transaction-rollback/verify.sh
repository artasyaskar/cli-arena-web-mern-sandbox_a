#!/usr/bin/env bash
set -euo pipefail

# Get the root directory of the project
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

COMPOSE_FILE="tasks/fix-mongo-transaction-rollback/docker-compose.replicaset.yml"

# Function to clean up services on script exit
cleanup() {
    echo "--- Cleaning up services ---"
    docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
}
trap cleanup EXIT

echo "--- Starting replica set for fix-mongo-transaction-rollback ---"
# Use --wait to ensure the replica set is initialized (waits for healthcheck)
docker compose -f "$COMPOSE_FILE" up -d --wait

echo "--- Installing dependencies ---"
npm ci
(cd src/server && npm ci)

echo "--- Running verification for fix-mongo-transaction-rollback ---"

# Set a unique database for this test run with the replica set option
export MONGO_URI_TEST="mongodb://localhost:27017/fix-mongo-transaction-rollback-$RANDOM?replicaSet=rs0"

# Run the specific test file for this task
npx jest --runInBand "tasks/fix-mongo-transaction-rollback/tests/transaction.test.ts"

echo "✅ fix-mongo-transaction-rollback verified"
