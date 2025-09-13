#!/bin/bash

# Use a unique IP for this test run
TEST_IP="192.168.1.$(($RANDOM % 254 + 1))"
CHECK_IP="192.168.1.$(($RANDOM % 254 + 100))"

# 1. Check that the rate limited route is accessible
response=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Forwarded-For: $CHECK_IP" http://localhost:3000/api/limited)
if [ "$response" -ne 200 ]; then
  echo "Rate limiting test failed. Limited route not accessible."
  exit 1
fi

# 2. Test rate limiting by making 5 requests
echo "Testing rate limiting (5 requests)..."
for i in {1..5}; do
  response=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Forwarded-For: $TEST_IP" http://localhost:3000/api/limited)
  if [ "$response" -ne 200 ]; then
    echo "Rate limiting test failed. Request $i should succeed (got $response)."
    exit 1
  fi
done

# 3. Test that the 6th request is rate limited
response=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Forwarded-For: $TEST_IP" http://localhost:3000/api/limited)
if [ "$response" -ne 429 ]; then
  echo "Rate limiting test failed. 6th request should be rate limited (got $response)."
  exit 1
fi

# 4. Test wrong HTTP method
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/limited)
if [ "$response" -ne 405 ]; then
  echo "Rate limiting test failed. Wrong method should return 405 (got $response)."
  exit 1
fi

# 5. Test rate limit headers (use a new IP to avoid rate limiting)
HEADERS_IP="192.168.1.$(($RANDOM % 254 + 200))"
response=$(curl -s -D /tmp/headers.txt -H "X-Forwarded-For: $HEADERS_IP" http://localhost:3000/api/limited > /dev/null && grep -E "(X-RateLimit-Limit|X-RateLimit-Remaining|X-RateLimit-Reset)" /tmp/headers.txt)
if [ -z "$response" ]; then
  echo "Rate limiting test failed. Rate limit headers not found."
  exit 1
fi

# In a real test, you would need to wait for the rate limit window to reset
# and test that requests are allowed again after the time window expires.

echo "Rate limiting test passed!"
exit 0
