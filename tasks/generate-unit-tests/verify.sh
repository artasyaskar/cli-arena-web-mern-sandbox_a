#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'generate-unit-tests' task with enhanced checks.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR" # Ensure we are at the root
REPO_FILE_TO_BUG="src/server/src/repositories/productRepository.ts"
BACKUP_FILE="/tmp/productRepository.ts.bak"

# --- Cleanup ---
cleanup() {
    echo "--- Cleaning up ---"
    # Restore the original file if a backup exists
    if [ -f "$BACKUP_FILE" ]; then
        mv "$BACKUP_FILE" "$REPO_FILE_TO_BUG"
    fi
}
trap cleanup EXIT

# --- Main execution ---

echo "--- Installing dependencies ---"
(cd src/server && npm ci && npm install mongodb-memory-server)

echo "--- Running the solution to generate the test file ---"
bash "$ROOT_DIR/tasks/generate-unit-tests/solution.sh"

echo "--- Running tests to ensure they pass initially ---"
# Measure execution time
START_TIME=$(date +%s)
if ! (cd src/server && npm test); then
    echo "Initial test run failed. The tests should pass before introducing bugs."
    exit 1
fi
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo "Initial test run passed in ${EXECUTION_TIME} seconds."

echo "--- Verifying test performance (<5s) ---"
if [ "$EXECUTION_TIME" -lt 5 ]; then
    echo "Performance check passed."
else
    echo "Performance check failed: Execution time was ${EXECUTION_TIME}s, which is not less than 5s."
    exit 1
fi

echo "--- Verifying tests catch bugs ---"
# Backup the original file
cp "$REPO_FILE_TO_BUG" "$BACKUP_FILE"

# Introduce the bug
bash "$ROOT_DIR/tasks/generate-unit-tests/introduce_bugs_for_tests.sh"

# Run the tests again and expect them to fail
if (cd src/server && npm test); then
    echo "Bug detection check failed: Tests passed even after a bug was introduced."
    exit 1
else
    echo "Bug detection check passed: Tests failed as expected after bug introduction."
fi

# Restore the original file
mv "$BACKUP_FILE" "$REPO_FILE_TO_BUG"

echo "--- Verifying coverage reporting ---"
COVERAGE_OUTPUT=$(mktemp)
(cd src/server && npm test -- --coverage --coverageReporters="json-summary" --collectCoverageFrom="src/repositories/productRepository.ts") 2>&1 | tee $COVERAGE_OUTPUT
SUMMARY_JSON_STRING=$(grep '{"total":' $COVERAGE_OUTPUT | tail -n 1)
if [ -z "$SUMMARY_JSON_STRING" ]; then
    echo "Could not find coverage summary in test output."
    exit 1
fi
COVERAGE_PERCENT=$(echo "$SUMMARY_JSON_STRING" | jq -r '.total.lines.pct')
echo "Coverage report generated: ${COVERAGE_PERCENT}%"
if (( $(echo "$COVERAGE_PERCENT >= 90" | bc -l) )); then
    echo "Coverage check passed."
else
    echo "Coverage check failed: ${COVERAGE_PERCENT}% is less than 90%"
    exit 1
fi

echo "✅ generate-unit-tests verified"
