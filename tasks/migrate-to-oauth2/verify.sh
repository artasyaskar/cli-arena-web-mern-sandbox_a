#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'migrate-to-oauth2' task.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# --- Cleanup ---
cleanup() {
    echo "--- Cleaning up ---"
    kill $(jobs -p) || true
    docker compose -f docker-compose.test.yml down --volumes --remove-orphans
}
trap cleanup EXIT

# --- Main execution ---

echo "--- Starting services ---"
docker compose -f docker-compose.test.yml up -d --wait

echo "--- Installing dependencies ---"
npm ci
(cd src/server && npm ci)
(cd src/client && npm ci)

echo "--- Starting mock OAuth server ---"
node "tasks/migrate-to-oauth2/resources/mock-oauth-server.js" &
sleep 3 # Give it time to start

echo "--- Starting main application ---"
(cd src/server && npm run dev &)
(cd src/client && npm run dev &)
npx wait-on http://localhost:8080 http://localhost:3000 --timeout 120000

echo "--- Running the solution to migrate to OAuth 2.0 ---"
bash "tasks/migrate-to-oauth2/solution.sh"

echo "--- Testing the OAuth 2.0 flow ---"
# The test script needs a more direct way to test the flow,
# as simulating browser redirects with curl is complex.
# We'll directly hit the callback endpoint after getting a code.

# 1. Get an authorization code from the mock provider
REDIRECT_URL=$(curl -s -w %{redirect_url} -o /dev/null "http://localhost:4000/auth?response_type=code&client_id=test&redirect_uri=http://localhost:8080/api/auth/oauth/callback&state=xyz")
CODE=$(echo "$REDIRECT_URL" | grep -o 'code=[^&]*' | cut -d= -f2)

if [ -z "$CODE" ]; then
    echo "Verification failed: Could not get authorization code from mock provider."
    exit 1
fi
echo "Successfully obtained authorization code."

# 2. Hit the server's callback endpoint with the code and check for the cookie
HEADERS=$(curl -s -i "http://localhost:8080/api/auth/oauth/callback?code=$CODE")
if echo "$HEADERS" | grep -q "Set-Cookie: token="; then
    echo "Verification passed: Server returned a token cookie."
else
    echo "Verification failed: Server did not return a token cookie."
    echo "Received headers:"
    echo "$HEADERS"
    exit 1
fi

# 3. Verify the old login route is disabled
LOGIN_RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/api/auth/login)
if [ "$LOGIN_RESPONSE_CODE" -eq 404 ]; then
    echo "Verification passed: Old login route is disabled (404)."
else
    echo "Verification failed: Old login route is still active (expected 404, got $LOGIN_RESPONSE_CODE)."
    exit 1
fi


echo "✅ migrate-to-oauth2 verified"
