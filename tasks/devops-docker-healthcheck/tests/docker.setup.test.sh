#!/usr/bin/env bash
set -euo pipefail

# This test script checks the docker-compose.yml for the required changes.
# It uses grep as a simple YAML parser for this task.

COMPOSE_FILE="docker-compose.yml"
WAIT_SCRIPT="scripts/wait-for-services.sh"

echo "--- Running Docker Setup Test ---"

# Check 1: Redis service exists
if ! grep -q "redis:" "$COMPOSE_FILE"; then
    echo "FAIL: The 'redis:' service is not defined in $COMPOSE_FILE"
    exit 1
fi
echo "PASS: Redis service is defined."

# Check 2: Redis healthcheck exists
# A bit brittle, but checks if 'healthcheck:' is under 'redis:'
if ! sed -n '/redis:/,/services:/p' "$COMPOSE_FILE" | grep -q "healthcheck:"; then
    echo "FAIL: The redis service does not have a healthcheck."
    exit 1
fi
echo "PASS: Redis service has a healthcheck."

# Check 3: API service depends on Redis
if ! sed -n '/api:/,/services:/p' "$COMPOSE_FILE" | grep -q "redis"; then
    echo "FAIL: The api service does not appear to depend on redis."
    exit 1
fi
echo "PASS: API service depends on redis."

# Check 4: API service command uses a wait script
if ! grep -q "wait-for-services.sh" "$COMPOSE_FILE"; then
    echo "FAIL: The api service command does not use the wait-for-services.sh script."
    exit 1
fi
echo "PASS: API service uses the wait script."

# Check 5: The wait script itself exists and is executable
if [ ! -f "$WAIT_SCRIPT" ]; then
    echo "FAIL: The wait script $WAIT_SCRIPT does not exist."
    exit 1
fi
if [ ! -x "$WAIT_SCRIPT" ]; then
    echo "FAIL: The wait script $WAIT_SCRIPT is not executable."
    exit 1
fi
echo "PASS: Wait script exists and is executable."


echo "--- Docker Setup Test Passed Successfully ---"
exit 0
