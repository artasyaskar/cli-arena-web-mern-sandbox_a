#!/bin/bash

# 1. Check that the i18n routes are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
if [ "$response" -ne 200 ]; then
  echo "i18n test failed. Home page not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/en)
if [ "$response" -ne 200 ]; then
  echo "i18n test failed. English locale not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/es)
if [ "$response" -ne 200 ]; then
  echo "i18n test failed. Spanish locale not accessible."
  exit 1
fi

# 2. Test API localization
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/hello?locale=en)
if [ "$response" -ne 200 ]; then
  echo "i18n test failed. English API not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/hello?locale=es)
if [ "$response" -ne 200 ]; then
  echo "i18n test failed. Spanish API not accessible."
  exit 1
fi

# 3. Test API response content
response=$(curl -s http://localhost:3000/api/hello?locale=en)
if ! echo "$response" | grep -q "Hello from API"; then
  echo "i18n test failed. English API response incorrect."
  exit 1
fi

response=$(curl -s http://localhost:3000/api/hello?locale=es)
if ! echo "$response" | grep -q "Hola desde la API"; then
  echo "i18n test failed. Spanish API response incorrect."
  exit 1
fi

# In a real test, you would need to check the actual page content
# to verify that the translations are working correctly.

echo "i18n test passed!"
exit 0
