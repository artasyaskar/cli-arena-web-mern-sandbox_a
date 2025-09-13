#!/usr/bin/env bash
set -euo pipefail

# Get the root directory of the project
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# Assume cypress.config.ts is in the root directory as part of the task solution
if [ ! -f "cypress.config.ts" ]; then
    echo "cypress.config.ts not found in the root directory. Copying from resources."
    cp "tasks/add-e2e-tests-cypress/resources/cypress.config.ts" .
fi

# Function to clean up services and background processes on script exit
cleanup() {
    echo "--- Cleaning up services and processes ---"
    # Kill all background jobs of this script
    if (jobs -p | grep .); then
       kill $(jobs -p)
    fi
    docker compose -f docker-compose.test.yml down --volumes --remove-orphans
}
trap cleanup EXIT

echo "--- Starting services for add-e2e-tests-cypress ---"
# Prefer compose --wait if supported
docker compose -f docker-compose.test.yml up -d --wait || docker compose -f docker-compose.test.yml up -d

# Wait for DB to be ready
echo "Waiting for database to start..."
npx wait-on tcp:27017 --timeout 60000

echo "--- Installing dependencies ---"
npm ci # For cypress and bcrypt
(cd src/server && npm ci)
(cd src/client && npm ci)

# Set a unique database for this test run
export MONGO_URI="mongodb://localhost:27017/add-e2e-tests-cypress-$RANDOM"

echo "--- Seeding user for E2E tests ---"
node "tasks/add-e2e-tests-cypress/tests/seed-user.js"

echo "--- Starting servers for E2E tests ---"
# Start server in the background
(cd src/server && npm run dev &)

# Start client in the background
(cd src/client && npm run dev &)

echo "Waiting for API server to be ready on port 8080..."
npx wait-on http://localhost:8080 --timeout 120000

echo "Waiting for client server to be ready on port 3000..."
npx wait-on http://localhost:3000 --timeout 120000

echo "--- Running Cypress E2E tests ---"
npx cypress run --config-file cypress.config.ts --headless

echo "✅ add-e2e-tests-cypress verified"
