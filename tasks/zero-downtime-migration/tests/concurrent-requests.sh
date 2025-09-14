#!/bin/bash

# This script sends concurrent read and write requests to the server.
# It's designed to be run in the background during the migration to test for downtime.

API_URL="http://localhost:8080/api/products"
LOG_FILE="/tmp/concurrent_requests.log"
touch $LOG_FILE

echo "Starting concurrent requests..."

# This loop will run for a specified duration (passed as the first argument)
END_TIME=$((SECONDS + $1))

while [ $SECONDS -lt $END_TIME ]; do
    # Send a read request
    curl -s -o /dev/null -w "%{http_code}\n" $API_URL >> $LOG_FILE &

    # Send a write request
    curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"name":"Concurrent Test","description":"...","price":10,"category":"Test"}' $API_URL >> $LOG_FILE &

    sleep 0.1 # Small delay between batches of requests
done

echo "Concurrent requests finished."
