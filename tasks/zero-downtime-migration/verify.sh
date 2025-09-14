#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'zero-downtime-migration' task with enhanced checks.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"
export MONGO_URI="mongodb://localhost:27017/zero-downtime-test"

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
(cd src/server && npm ci)
(cd src/server && npm run seed)
(cd src/server && npm run dev &)
npx wait-on http://localhost:8080 --timeout=120000

echo "--- Running the solution script ---"
bash "tasks/zero-downtime-migration/solution.sh"

# --- Phase 1: Expand ---
echo "--- Verifying Phase 1: Expand ---"
kill %1
(cd src/server && npm run dev &)
npx wait-on http://localhost:8080 --timeout=120000
# Data integrity check: create a product, check both fields are written
curl -s -X POST -H "Content-Type: application/json" -d '{"name":"Test Product","description":"...","price":123,"category":"Test"}' http://localhost:8080/api/products
DB_CHECK_EXPAND=$(node -e "
  const m = require('mongoose');
  const P = require('./src/server/src/models/Product').default;
  m.connect('$MONGO_URI').then(async () => {
    const p = await P.findOne({ name: 'Test Product' });
    console.log(p && p.price === 123 && p.priceV2.amount === 123 ? 'ok' : 'fail');
    await m.disconnect();
  });
")
if [ "$DB_CHECK_EXPAND" != "ok" ]; then echo "Expand phase data integrity check failed."; exit 1; fi
echo "Expand phase verified."

# --- Phase 2: Migrate ---
echo "--- Verifying Phase 2: Migrate (with concurrent requests) ---"
bash "tasks/zero-downtime-migration/tests/concurrent-requests.sh" 10 &
CONCURRENT_PID=$!
sleep 1 # Let the requests start
# Run the migration script
node "tasks/zero-downtime-migration/resources/migration-script.js"
wait $CONCURRENT_PID
# Check that no requests failed during migration
if grep -v "200" /tmp/concurrent_requests.log | grep -v "201"; then
    echo "Concurrent request check failed: Some requests failed during migration.";
    cat /tmp/concurrent_requests.log
    exit 1;
fi
echo "Concurrent request check passed."
# Data integrity check: all old products should now have the new field
DB_CHECK_MIGRATE=$(node -e "
  const m = require('mongoose');
  const P = require('./src/server/src/models/Product').default;
  m.connect('$MONGO_URI').then(async () => {
    const count = await P.countDocuments({ price: { \$exists: true }, priceV2: { \$exists: false } });
    console.log(count === 0 ? 'ok' : 'fail');
    await m.disconnect();
  });
")
if [ "$DB_CHECK_MIGRATE" != "ok" ]; then echo "Migrate phase data integrity check failed."; exit 1; fi
echo "Migrate phase verified."

# --- Phase 3: Contract ---
echo "--- Verifying Phase 3: Contract ---"
kill %1
(cd src/server && npm run dev &)
npx wait-on http://localhost:8080 --timeout=120000
# Run the cleanup script
node "tasks/zero-downtime-migration/resources/cleanup-script.js"
# Data integrity check: the old 'price' field should be gone
DB_CHECK_CONTRACT=$(node -e "
  const m = require('mongoose');
  const P = require('./src/server/src/models/Product').default;
  m.connect('$MONGO_URI').then(async () => {
    const count = await P.countDocuments({ price: { \$exists: true } });
    console.log(count === 0 ? 'ok' : 'fail');
    await m.disconnect();
  });
")
if [ "$DB_CHECK_CONTRACT" != "ok" ]; then echo "Contract phase data integrity check failed."; exit 1; fi
echo "Contract phase verified."

# --- Testing Rollback ---
echo "--- Testing Rollback Procedure ---"
# We'll run the rollback script and check that the priceV2 field is gone.
node "tasks/zero-downtime-migration/resources/rollback.js"
DB_CHECK_ROLLBACK=$(node -e "
  const m = require('mongoose');
  const P = require('./src/server/src/models/Product').default;
  m.connect('$MONGO_URI').then(async () => {
    const count = await P.countDocuments({ priceV2: { \$exists: true } });
    console.log(count === 0 ? 'ok' : 'fail');
    await m.disconnect();
  });
")
if [ "$DB_CHECK_ROLLBACK" != "ok" ]; then echo "Rollback check failed."; exit 1; fi
echo "Rollback procedure verified."

echo "✅ zero-downtime-migration verified"
