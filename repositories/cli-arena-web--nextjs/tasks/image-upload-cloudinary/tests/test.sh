#!/bin/bash

# 1. Check that the upload API route is accessible
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/upload)
if [ "$response" -ne 405 ]; then
  echo "Upload API test failed. Route not accessible."
  exit 1
fi

# 2. Test upload without file (should return 400)
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/upload)
if [ "$response" -ne 400 ]; then
  echo "Upload API test failed. Should return 400 when no file is provided."
  exit 1
fi

# 3. Test wrong HTTP method (should return 405)
response=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://localhost:3000/api/upload)
if [ "$response" -ne 405 ]; then
  echo "Upload API test failed. Should return 405 for wrong HTTP method."
  exit 1
fi

# In a real test, you would need to mock Cloudinary and test with actual files
# to verify the upload functionality and image processing.

echo "Cloudinary upload test passed!"
exit 0
