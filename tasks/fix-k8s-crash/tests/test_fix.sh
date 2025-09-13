#!/bin/bash
set -e

# This script tests the fix for the k8s crash scenario.

# It sends a checkout request with the problematic discount code.
# The script will exit with a non-zero status if the request fails.

# The URL of the service will be passed as the first argument.
SERVICE_URL=$1

echo "--- Testing checkout with CRASHTEST discount code ---"

# We need a product ID to test the checkout. We'll just use a dummy one for this test.
PRODUCT_ID="60d5ecb8b4854b32348a22a3"

# Send a POST request to the checkout endpoint.
# We expect this to fail with the buggy version and succeed with the fixed version.
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"productId\":\"$PRODUCT_ID\",\"discountCode\":\"CRASHTEST\"}" $SERVICE_URL/api/products/checkout)

if [ "$RESPONSE_CODE" -ne 200 ]; then
  echo "Test failed: Expected status code 200, but got $RESPONSE_CODE"
  exit 1
fi

echo "Test passed: Checkout with CRASHTEST discount code was successful."
exit 0
