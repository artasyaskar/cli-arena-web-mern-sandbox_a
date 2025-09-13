#!/bin/bash

# 1. Check that the job queue routes are accessible
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"task":"test"}' http://localhost:3000/api/enqueue)
if [ "$response" -ne 200 ]; then
  echo "Job queue test failed. Enqueue route not accessible."
  exit 1
fi

# 2. Test enqueue with valid task
response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"task":"test-task"}' http://localhost:3000/api/enqueue)
if ! echo "$response" | grep -q "id"; then
  echo "Job queue test failed. Enqueue should return job ID."
  exit 1
fi

# Extract job ID from response
job_id=$(echo "$response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$job_id" ]; then
  echo "Job queue test failed. Could not extract job ID."
  exit 1
fi

# 3. Test initial status (should be pending) - check immediately
response=$(curl -s "http://localhost:3000/api/status?id=$job_id")
if ! echo "$response" | grep -q "pending"; then
  echo "Job queue test failed. Initial status should be pending."
  exit 1
fi

# 4. Poll for completion (wait up to 4 seconds)
echo "Waiting for job to complete..."
for i in {1..8}; do
  response=$(curl -s "http://localhost:3000/api/status?id=$job_id")
  if echo "$response" | grep -q "completed"; then
    echo "Job queue test passed! Job completed successfully."
    exit 0
  fi
  sleep 0.5
done

echo "Job queue test failed. Job did not complete within expected time."
exit 1
