#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'generate-unit-tests' task.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR" # Ensure we are at the root

# --- Main execution ---

echo "--- Installing dependencies ---"
(cd src/server && npm ci)
(cd src/server && npm install mongodb-memory-server) # Ensure this dev dependency is available

echo "--- Running the solution to generate the test file ---"
bash "$ROOT_DIR/tasks/generate-unit-tests/solution.sh"

echo "--- Running tests with coverage ---"
# We use a temporary file to store the coverage output
COVERAGE_OUTPUT=$(mktemp)
# The output of npm test is redirected to the file and also to the console
(cd src/server && npm test -- --coverage --coverageReporters="json-summary" --collectCoverageFrom="src/repositories/productRepository.ts") 2>&1 | tee $COVERAGE_OUTPUT

echo "--- Verifying test coverage ---"
# We'll use the json-summary reporter to get a machine-readable output.
# The summary is at the end of the file, after the test results.
SUMMARY_JSON_STRING=$(grep '{"total":' $COVERAGE_OUTPUT | tail -n 1)

if [ -z "$SUMMARY_JSON_STRING" ]; then
    echo "Could not find coverage summary in test output."
    exit 1
fi

# Now, parse the JSON to get the coverage for the target file.
COVERAGE_PERCENT=$(echo "$SUMMARY_JSON_STRING" | jq -r '.total.lines.pct')

if (( $(echo "$COVERAGE_PERCENT >= 90" | bc -l) )); then
    echo "Coverage check passed: ${COVERAGE_PERCENT}%"
else
    echo "Coverage check failed: ${COVERAGE_PERCENT}% is less than 90%"
    exit 1
fi

echo "✅ generate-unit-tests verified"
