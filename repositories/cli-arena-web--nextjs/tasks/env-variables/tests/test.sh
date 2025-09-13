#!/bin/bash

# 1. Check that the env demo routes are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
if [ "$response" -ne 200 ]; then
  echo "Environment variables test failed. Home page not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/env-demo)
if [ "$response" -ne 200 ]; then
  echo "Environment variables test failed. Env demo API not accessible."
  exit 1
fi

# 2. Test API response content
response=$(curl -s http://localhost:3000/api/env-demo)
if ! echo "$response" | grep -q "serverSide"; then
  echo "Environment variables test failed. API should return serverSide data."
  exit 1
fi

if ! echo "$response" | grep -q "clientSide"; then
  echo "Environment variables test failed. API should return clientSide data."
  exit 1
fi

# 3. Test wrong HTTP method
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/env-demo)
if [ "$response" -ne 405 ]; then
  echo "Environment variables test failed. Wrong method should return 405."
  exit 1
fi

# 4. Test page content
response=$(curl -s http://localhost:3000/)
if ! echo "$response" | grep -q "Environment Variables Demo"; then
  echo "Environment variables test failed. Page should display env var demo."
  exit 1
fi

# In a real test, you would need to check that the environment variables
# are actually being loaded and displayed correctly.

echo "Environment variables test passed!"
exit 0
