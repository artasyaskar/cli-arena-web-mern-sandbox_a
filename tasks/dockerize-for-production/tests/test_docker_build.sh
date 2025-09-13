#!/bin/bash
set -e

# This script tests the production Docker builds.

# --- Test Client ---
echo "--- Testing client container ---"
CLIENT_RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082)
if [ "$CLIENT_RESPONSE_CODE" -ne 200 ]; then
  echo "Client test failed: Expected status code 200, but got $CLIENT_RESPONSE_CODE"
  exit 1
fi
echo "Client test passed."

# --- Test Server ---
echo "--- Testing server container ---"
SERVER_RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8083/api/products)
if [ "$SERVER_RESPONSE_CODE" -ne 200 ]; then
  echo "Server test failed: Expected status code 200, but got $SERVER_RESPONSE_CODE"
  exit 1
fi
echo "Server test passed."

exit 0
