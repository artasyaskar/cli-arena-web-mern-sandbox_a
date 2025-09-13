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

echo "--- Starting services for add-file-upload-s3 ---"
# This test uses local file uploads, so only Mongo is needed.
docker compose -f docker-compose.test.yml up -d mongo

# Wait for services to be ready
echo "Waiting for services to start..."
npx wait-on tcp:27017 --timeout 60000

echo "--- Installing dependencies ---"
npm ci
(cd src/server && npm ci)

echo "--- Running verification for add-file-upload-s3 ---"

# Set a unique database for this test run
export MONGO_URI_TEST="mongodb://localhost:27017/add-file-upload-s3-$RANDOM"

# Run the specific test file for this task
npx jest --runInBand "tasks/add-file-upload-s3/tests/upload.test.ts"

echo "✅ add-file-upload-s3 verified"
