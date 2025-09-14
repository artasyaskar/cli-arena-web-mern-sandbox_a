#!/usr/bin/env bash
set -euo pipefail

# This script verifies the 'fix-k8s-crash' task with enhanced checks.

# --- Setup ---
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# Function to ensure kind and kubectl are installed
ensure_tools() {
    # (omitted for brevity, same as before)
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
docker build -t backend:1.0-buggy -f src/server/Dockerfile .

echo "--- Loading buggy image into kind cluster ---"
kind load docker-image backend:1.0-buggy --name verify-k8s-crash

echo "--- Deploying buggy application to Kubernetes ---"
kubectl apply -f "tasks/fix-k8s-crash/resources/deployment.yaml"

echo "--- Waiting for deployment to be ready ---"
kubectl wait --for=condition=available --timeout=120s deployment/backend-service

echo "--- Verifying the crash scenarios ---"
POD_NAME=$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward svc/backend-service 8081:8080 &
sleep 5

# Test crash scenario 1: discount code
if ! curl -s -f -X POST -H "Content-Type: application/json" -d '{"productId":"dummy","discountCode":"CRASHTEST"}' http://localhost:8081/api/products/checkout; then
    echo "Successfully verified crash for discount code."
else
    echo "Verification failed: Did not crash for discount code."
    exit 1
fi
# After a crash, the pod will restart. We need to wait for it to be ready again.
kubectl wait --for=condition=ready --timeout=120s pod/$POD_NAME

# Test crash scenario 2: special product ID
if ! curl -s -f -X POST -H "Content-Type: application/json" -d '{"productId":"60d5f3b3b4854b32348a22a4"}' http://localhost:8081/api/products/checkout; then
    echo "Successfully verified crash for special product ID."
else
    echo "Verification failed: Did not crash for special product ID."
    exit 1
fi
kill %1 # Kill the port-forwarding

echo "--- Verifying pod logs for error messages ---"
LOGS=$(kubectl logs $POD_NAME)
if echo "$LOGS" | grep -q "TypeError: Cannot read properties of undefined (reading 'code')"; then
    echo "Found expected error message in logs. Check passed."
else
    echo "Did not find expected error message in logs. Check failed."
    exit 1
fi

echo "--- Applying the solution ---"
bash "tasks/fix-k8s-crash/solution.sh"

echo "--- Building fixed Docker image ---"
docker build -t backend:2.0-fixed -f src/server/Dockerfile .

echo "--- Loading fixed image into kind cluster ---"
kind load docker-image backend:2.0-fixed --name verify-k8s-crash

echo "--- Deploying fixed application to Kubernetes ---"
kubectl set image deployment/backend-service backend=backend:2.0-fixed
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

echo "--- Testing rollback procedure ---"
# First, let's break the deployment again by using the buggy image
kubectl set image deployment/backend-service backend=backend:1.0-buggy
kubectl wait --for=condition=available --timeout=120s deployment/backend-service
# Now, roll it back
kubectl rollout undo deployment/backend-service
kubectl wait --for=condition=available --timeout=120s deployment/backend-service
# Verify that the fix is back in place
kubectl port-forward svc/backend-service 8081:8080 &
sleep 5
if bash "tasks/fix-k8s-crash/tests/test_fix.sh" http://localhost:8081; then
    echo "Successfully verified the rollback procedure."
else
    echo "Verification failed: The rollback did not restore the working version."
    exit 1
fi
kill %1

echo "--- Verifying cluster health ---"
if ! kubectl get pods --field-selector=status.phase!=Running | grep "No resources found"; then
    echo "Cluster health check passed: All pods are running."
else
    echo "Cluster health check failed: Some pods are not running."
    exit 1
fi

echo "✅ fix-k8s-crash verified"
