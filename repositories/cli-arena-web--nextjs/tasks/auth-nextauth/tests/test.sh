#!/bin/bash

# 1. Check that the NextAuth routes are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/auth/providers)
echo "Providers endpoint response: $response"
if [ "$response" -ne 200 ]; then
  echo "NextAuth test failed. Providers endpoint not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/auth/signin)
if [ "$response" -ne 200 ]; then
  echo "NextAuth test failed. Sign-in page not accessible."
  exit 1
fi

# 2. Test session API route
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/session)
if [ "$response" -ne 200 ]; then
  echo "NextAuth test failed. Session API not accessible."
  exit 1
fi

# 3. Test protected API route (should return 401 without auth)
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/protected)
if [ "$response" -ne 401 ]; then
  echo "NextAuth test failed. Protected route should require authentication."
  exit 1
fi

# 4. Test logout API route
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/logout)
if [ "$response" -ne 200 ]; then
  echo "NextAuth test failed. Logout API not accessible."
  exit 1
fi

# 5. Test wrong HTTP method for logout
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/logout)
if [ "$response" -ne 405 ]; then
  echo "NextAuth test failed. Logout should only accept POST method."
  exit 1
fi

# In a real test, you would need to mock GitHub OAuth and test the complete
# authentication flow including sign-in, session management, and logout.

echo "NextAuth test passed!"
exit 0

