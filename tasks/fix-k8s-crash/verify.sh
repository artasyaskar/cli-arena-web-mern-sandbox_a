#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'fix-k8s-crash' task.
# It sets up a local Kubernetes cluster using 'kind',
# introduces the bug, deploys a crashing version of the app,
# applies the solution, and verifies the fix.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# Function to ensure kind and kubectl are installed
ensure_tools() {
    if ! command -v kind &> /dev/null; then
        echo "kind could not be found, installing..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-$(uname)-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl could not be found, installing..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    fi
}

# --- Cleanup ---
cleanup() {
    echo "--- Cleaning up ---"
    kind delete cluster --name verify-k8s-crash || true
    docker rmi -f backend:1.0-buggy backend:2.0-fixed || true
}
trap cleanup EXIT

# --- Main execution ---
ensure_tools

echo "--- Creating Kubernetes cluster with kind ---"
kind create cluster --name verify-k8s-crash

echo "--- Introduce the bug ---"
bash "tasks/fix-k8s-crash/introduce_bug.sh"

echo "--- Building buggy Docker image ---"
# We need to build the server image. We'll use the main Dockerfile but tag it specifically.
docker build -t backend:1.0-buggy -f src/server/Dockerfile .

echo "--- Loading buggy image into kind cluster ---"
kind load docker-image backend:1.0-buggy --name verify-k8s-crash

echo "--- Deploying buggy application to Kubernetes ---"
kubectl apply -f "tasks/fix-k8s-crash/resources/deployment.yaml"

echo "--- Waiting for deployment to be ready ---"
kubectl wait --for=condition=available --timeout=120s deployment/backend-service

echo "--- Verifying the crash ---"
# We'll port-forward the service to test it.
kubectl port-forward svc/backend-service 8081:8080 &
sleep 5 # Give port-forwarding a moment to start

# We expect this test to fail, so we invert the exit code.
if ! bash "tasks/fix-k8s-crash/tests/test_fix.sh" http://localhost:8081; then
    echo "Successfully verified that the bug causes a crash."
else
    echo "Verification failed: The bug did not cause a crash as expected."
    exit 1
fi
kill %1 # Kill the port-forwarding

echo "--- Applying the solution ---"
bash "tasks/fix-k8s-crash/solution.sh"

echo "--- Building fixed Docker image ---"
docker build -t backend:2.0-fixed -f src/server/Dockerfile .

echo "--- Loading fixed image into kind cluster ---"
kind load docker-image backend:2.0-fixed --name verify-k8s-crash

echo "--- Deploying fixed application to Kubernetes ---"
kubectl set image deployment/backend-service backend=backend:2.0-fixed

echo "--- Waiting for deployment to be ready ---"
kubectl wait --for=condition=available --timeout=120s deployment/backend-service

echo "--- Verifying the fix ---"
kubectl port-forward svc/backend-service 8081:8080 &
sleep 5

if bash "tasks/fix-k8s-crash/tests/test_fix.sh" http://localhost:8081; then
    echo "Successfully verified the fix."
else
    echo "Verification failed: The fix did not work."
    exit 1
fi
kill %1

echo "✅ fix-k8s-crash verified"
