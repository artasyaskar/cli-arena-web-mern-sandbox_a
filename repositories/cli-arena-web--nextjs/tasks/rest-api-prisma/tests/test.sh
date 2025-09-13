#!/bin/bash

# 1. Check that the posts API routes are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/posts)
if [ "$response" -ne 200 ]; then
  echo "REST API test failed. Posts route not accessible."
  exit 1
fi

# 2. Test GET all posts
response=$(curl -s http://localhost:3000/api/posts)
if ! echo "$response" | grep -q "\[\]"; then
  echo "REST API test failed. GET posts should return empty array initially."
  exit 1
fi

# 3. Test POST create post
response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"Test Post","content":"Test content"}' http://localhost:3000/api/posts)
if ! echo "$response" | grep -q "Test Post"; then
  echo "REST API test failed. POST should create a post."
  exit 1
fi

# 4. Test POST with missing fields
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"title":"Test Post"}' http://localhost:3000/api/posts)
if [ "$response" -ne 400 ]; then
  echo "REST API test failed. POST with missing content should return 400."
  exit 1
fi

# 5. Test GET posts after creation
response=$(curl -s http://localhost:3000/api/posts)
if ! echo "$response" | grep -q "Test Post"; then
  echo "REST API test failed. GET posts should return created post."
  exit 1
fi

# 6. Test wrong HTTP method
response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT http://localhost:3000/api/posts)
if [ "$response" -ne 405 ]; then
  echo "REST API test failed. Wrong method should return 405."
  exit 1
fi

# In a real test, you would need to extract the post ID from the response
# and test the individual post endpoints (GET /api/posts/[id], PUT, DELETE).

echo "REST API test passed!"
exit 0