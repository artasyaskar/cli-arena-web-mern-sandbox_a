#!/usr/bin/env bash
set -euo pipefail

# This script sets up Cypress and creates the initial E2E tests.

echo "--- Applying solution for task: add-e2e-tests-cypress ---"

# 1. Add Cypress dependency and script to client package.json
sed -i'' -e '/"vite":/a\
    "cypress": "^12.11.0",' src/client/package.json

sed -i'' -e '/"preview": "vite preview"/a\
    "e2e": "cypress open",\
    "e2e:headless": "cypress run",' src/client/package.json


# 2. Create cypress.config.ts at the project root
cp tasks/add-e2e-tests-cypress/resources/cypress.config.ts .


# 3. Create the Cypress test files in cypress/e2e/
mkdir -p cypress/e2e
cp tasks/add-e2e-tests-cypress/tests/login.cy.ts cypress/e2e/
cp tasks/add-e2e-tests-cypress/tests/checkout.cy.ts cypress/e2e/

echo "--- Cypress E2E testing setup and initial tests created successfully. ---"
