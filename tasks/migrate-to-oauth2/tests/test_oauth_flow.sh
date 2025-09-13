#!/bin/bash
set -e

# This script tests the OAuth 2.0 flow.

echo "--- Testing OAuth 2.0 flow ---"

# 1. Start the flow by hitting the client's login link (simulated)
# In a real browser, this would be a redirect. We'll capture the redirect URL.
AUTH_URL=$(curl -s -o /dev/null -w "%{redirect_url}" "http://localhost:3000/login")
# This is a simplification. In the verify script, we will directly call the auth server.

# 2. Simulate the redirect to the callback URL with a code
# We'll get the code from the mock auth server directly
AUTH_RESPONSE=$(curl -s "http://localhost:4000/auth?response_type=code&client_id=test&redirect_uri=http://localhost:8080/api/auth/oauth/callback&state=xyz")
CODE=$(echo $AUTH_RESPONSE | grep -o 'code=[^&]*' | cut -d= -f2)

if [ -z "$CODE" ]; then
    echo "Test failed: Did not receive authorization code from mock provider."
    exit 1
fi
echo "Received authorization code: $CODE"

# 3. Hit our server's callback endpoint with the code
# We expect a redirect to the frontend and a 'token' cookie.
CALLBACK_RESPONSE_HEADERS=$(curl -s -I "http://localhost:8080/api/auth/oauth/callback?code=$CODE")

# 4. Check for the cookie
if echo "$CALLBACK_RESPONSE_HEADERS" | grep -q "Set-Cookie: token="; then
    echo "Test passed: Received token cookie."
else
    echo "Test failed: Did not receive token cookie."
    echo "Headers received:"
    echo "$CALLBACK_RESPONSE_HEADERS"
    exit 1
fi

# 5. Check for the redirect to the frontend
if echo "$CALLBACK_RESPONSE_HEADERS" | grep -q "Location: http://localhost:3000"; then
    echo "Test passed: Redirected to frontend."
else
    echo "Test failed: Did not redirect to frontend."
    echo "Headers received:"
    echo "$CALLBACK_RESPONSE_HEADERS"
    exit 1
fi

exit 0
