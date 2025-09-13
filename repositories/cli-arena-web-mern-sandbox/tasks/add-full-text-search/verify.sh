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

echo "--- Starting services for add-full-text-search ---"
docker compose -f docker-compose.test.yml up -d --wait || docker compose -f docker-compose.test.yml up -d

# Wait for services to be ready
echo "Waiting for services to start..."
npx wait-on tcp:27017 --timeout 60000

echo "--- Installing dependencies ---"
npm ci
(cd src/server && npm ci)

echo "--- Seeding database for tests ---"

# Set a unique database for this test run.
# Both the seed script (using MONGO_URI) and Jest (using MONGO_URI_TEST)
# must point to the same database.
UNIQUE_DB_URI="mongodb://localhost:27017/add-full-text-search-$RANDOM"
export MONGO_URI=$UNIQUE_DB_URI
export MONGO_URI_TEST=$UNIQUE_DB_URI

# Run the seed script
(cd src/server && npm run db:seed)

echo "--- Running verification for add-full-text-search ---"

# Run the specific test file for this task
npx jest --runInBand "tasks/add-full-text-search/tests/search.test.ts"

echo "✅ add-full-text-search verified"
