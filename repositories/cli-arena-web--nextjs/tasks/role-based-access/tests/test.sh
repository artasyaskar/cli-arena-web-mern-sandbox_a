#!/bin/bash

# 1. Check that the RBAC routes are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/admin/data)
if [ "$response" -ne 401 ]; then
  echo "RBAC test failed. Admin route not properly protected."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/editor/data)
if [ "$response" -ne 401 ]; then
  echo "RBAC test failed. Editor route not properly protected."
  exit 1
fi

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/user/data)
if [ "$response" -ne 401 ]; then
  echo "RBAC test failed. User route not properly protected."
  exit 1
fi

# 2. Test signup with role
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"email":"admin@example.com","password":"password123","name":"Admin User","role":"ADMIN"}' http://localhost:3000/api/auth/signup)
if [ "$response" -ne 201 ]; then
  echo "RBAC test failed. Admin signup should succeed."
  exit 1
fi

# 3. Test signup with invalid role
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"email":"invalid@example.com","password":"password123","name":"Invalid User","role":"INVALID"}' http://localhost:3000/api/auth/signup)
if [ "$response" -ne 400 ]; then
  echo "RBAC test failed. Invalid role should be rejected."
  exit 1
fi

# 4. Test admin access with invalid token
response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer invalid-token" http://localhost:3000/api/admin/data)
if [ "$response" -ne 401 ]; then
  echo "RBAC test failed. Invalid token should be rejected."
  exit 1
fi

# In a real test, you would need to mock JWT tokens and database
# to test the complete RBAC flow including role validation.

echo "RBAC test passed!"
exit 0
