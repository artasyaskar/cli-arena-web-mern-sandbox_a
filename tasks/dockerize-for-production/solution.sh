#!/bin/bash
set -e

# This script provides the solution for the dockerize-for-production task.
# It copies the new Dockerfiles into their respective directories.

# --- Server Dockerfile ---
echo "--- Creating server Dockerfile.prod ---"
cp "tasks/dockerize-for-production/resources/Dockerfile.prod.server" "src/server/Dockerfile.prod"

# --- Client Dockerfile and Nginx config ---
echo "--- Creating client Dockerfile.prod ---"
cp "tasks/dockerize-for-production/resources/Dockerfile.prod.client" "src/client/Dockerfile.prod"

echo "--- Creating nginx.conf for client ---"
cat <<'EOF' > "src/client/nginx.conf"
server {
  listen 80;
  server_name localhost;

  location / {
    root /usr/share/nginx/html;
    index index.html;
    try_files $uri $uri/ /index.html;
  }
}
EOF

echo "Production Dockerfiles created successfully."
