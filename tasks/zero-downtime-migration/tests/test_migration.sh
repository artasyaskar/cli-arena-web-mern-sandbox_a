#!/bin/bash
set -e

# This script tests the application during the migration.

PHASE=$1
echo "--- Testing application health during phase: $PHASE ---"

# Test creating a new product
CREATE_RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"name":"Test Product","description":"A product for testing","price":123,"category":"Test"}' http://localhost:8080/api/products)
if [ "$CREATE_RESPONSE_CODE" -ne 201 ]; then
  echo "Test failed (Phase $PHASE): Could not create product. Expected 201, got $CREATE_RESPONSE_CODE"
  exit 1
fi

# Test getting all products
GET_RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/products)
if [ "$GET_RESPONSE_CODE" -ne 200 ]; then
  echo "Test failed (Phase $PHASE): Could not get products. Expected 200, got $GET_RESPONSE_CODE"
  exit 1
fi

echo "Application health check passed for phase: $PHASE"
exit 0
