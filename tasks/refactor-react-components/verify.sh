#!/usr/bin/env bash
set -euo pipefail

# Get the root directory of the project
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

echo "--- Running verification for refactor-react-components ---"

# This task's verification is a static test checking file structure.
# No services are needed, but we need to install root dependencies for Jest.
npm ci

# Run the specific test file for this task
npx jest --runInBand "tasks/refactor-react-components/tests/component.structure.test.ts"

echo "✅ refactor-react-components verified"
