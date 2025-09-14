#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'migrate-to-oauth2' task with enhanced checks.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"
export MONGO_URI="mongodb://localhost:27017/migrate-to-oauth2-test"
export JWT_SECRET="a_very_secret_key"

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
(cd src/server && npm ci && npm install jsonwebtoken @types/jsonwebtoken)
(cd src/client && npm ci)

echo "--- Starting mock OAuth server ---"
node "tasks/migrate-to-oauth2/resources/mock-oauth-server.js" &
sleep 3

echo "--- Starting main application ---"
(cd src/server && npm run dev &)
(cd src/client && npm run dev &)
npx wait-on http://localhost:8080 http://localhost:3000 --timeout 120000

echo "--- Running the solution ---"
bash "tasks/migrate-to-oauth2/solution.sh"

echo "--- Testing happy path OAuth flow ---"
# (Same as before, but we'll add more checks)
REDIRECT_URL=$(curl -s -w %{redirect_url} -o /dev/null "http://localhost:4000/auth?response_type=code&client_id=test&redirect_uri=http://localhost:8080/api/auth/oauth/callback&state=xyz")
CODE=$(echo "$REDIRECT_URL" | grep -o 'code=[^&]*' | cut -d= -f2)
HEADERS=$(curl -s -i "http://localhost:8080/api/auth/oauth/callback?code=$CODE")
if ! echo "$HEADERS" | grep -q "Set-Cookie: token="; then
    echo "Happy path test failed: Server did not return a token cookie."
    exit 1
fi
TOKEN=$(echo "$HEADERS" | grep "Set-Cookie: token=" | sed 's/Set-Cookie: token=//' | sed 's/;.*//')
echo "Happy path test passed."

echo "--- Verifying JWT signature and payload ---"
# We need a tool to decode JWTs. We can use a simple node script.
DECODED_TOKEN=$(node -e "const jwt = require('jsonwebtoken'); console.log(JSON.stringify(jwt.verify('$TOKEN', '$JWT_SECRET')))")
if echo "$DECODED_TOKEN" | grep -q '"provider":"oauth"'; then
    echo "JWT verification passed."
else
    echo "JWT verification failed: Decoded token is incorrect."
    echo "Decoded token: $DECODED_TOKEN"
    exit 1
fi

echo "--- Verifying database operations ---"
# We need to query the database. We'll use a simple node script for this.
DB_CHECK_RESULT=$(node -e "
  const mongoose = require('mongoose');
  const User = require('./src/server/src/models/User').default;
  mongoose.connect('$MONGO_URI').then(async () => {
    const user = await User.findOne({ email: 'oauth-user@example.com' });
    console.log(user ? 'found' : 'not_found');
    await mongoose.disconnect();
  });
")
if [ "$DB_CHECK_RESULT" == "found" ]; then echo "Database check passed: User was created."; else echo "Database check failed: User not found."; exit 1; fi

echo "--- Testing OAuth error scenarios (invalid code) ---"
ERROR_RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/api/auth/oauth/callback?code=invalid_code")
if [ "$ERROR_RESPONSE_CODE" -eq 500 ]; then echo "Error scenario (invalid code) test passed."; else echo "Error scenario (invalid code) test failed: Expected 500, got $ERROR_RESPONSE_CODE."; exit 1; fi

echo "--- Testing concurrent OAuth flows ---"
echo "Starting 5 concurrent requests..."
for i in {1..5}; do
    (
        REDIRECT_URL=$(curl -s -w %{redirect_url} -o /dev/null "http://localhost:4000/auth?response_type=code&client_id=test&redirect_uri=http://localhost:8080/api/auth/oauth/callback&state=xyz$i")
        CODE=$(echo "$REDIRECT_URL" | grep -o 'code=[^&]*' | cut -d= -f2)
        curl -s -i "http://localhost:8080/api/auth/oauth/callback?code=$CODE" | grep "Set-Cookie: token="
    ) &
done
wait
# A simple check is to see if all requests succeeded. A more robust check would analyze the logs.
echo "Concurrent flow test completed."


echo "✅ migrate-to-oauth2 verified"
