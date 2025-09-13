#!/bin/bash

# 1. Check that the auth routes are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/auth/signup)
if [ "$response" -ne 400 ]; then
  echo "Auth test failed. Signup route not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/auth/login)
if [ "$response" -ne 400 ]; then
  echo "Auth test failed. Login route not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/auth/refresh)
if [ "$response" -ne 400 ]; then
  echo "Auth test failed. Refresh route not accessible."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/auth/logout)
if [ "$response" -ne 200 ]; then
  echo "Auth test failed. Logout route not accessible."
  exit 1
fi

# 2. Test signup with missing fields
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com"}' http://localhost:3000/api/auth/signup)
if [ "$response" -ne 400 ]; then
  echo "Auth test failed. Signup should return 400 for missing fields."
  exit 1
fi

# 3. Test login with missing fields
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com"}' http://localhost:3000/api/auth/login)
if [ "$response" -ne 400 ]; then
  echo "Auth test failed. Login should return 400 for missing fields."
  exit 1
fi

# 4. Test refresh with missing token
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{}' http://localhost:3000/api/auth/refresh)
if [ "$response" -ne 400 ]; then
  echo "Auth test failed. Refresh should return 400 for missing token."
  exit 1
fi

# In a real test, you would need to mock the database and JWT tokens
# to test the complete authentication flow including token validation.

echo "JWT authentication test passed!"
exit 0
