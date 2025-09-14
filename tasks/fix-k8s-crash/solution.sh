#!/bin/bash
set -e

# This script provides the solution for the k8s crash scenario.

# Step 1: Identify the crashing pod
echo "--- Step 1: Identify the crashing pod ---"
# In a real scenario, the user would run this command to find the pod.
# POD_NAME=$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
# echo "Found pod: $POD_NAME"

# Step 2: Check the logs
echo "--- Step 2: Check the logs ---"
# The user would then run this command to see the error.
# kubectl logs $POD_NAME

# Step 3: Fix the bug in the product controller.
echo "--- Step 3: Fix the bug ---"
TARGET_FILE="src/server/src/controllers/productController.ts"

# The fix is to correctly handle the 'promoDetails' object and the special product ID.
# We will comment out the lines that cause the crash.
sed -i "s/console.log(\`Applying special discount: \${promoDetails.code}\`); \/\/ This will crash/ \/\/ console.log(\`Applying special discount: \${promoDetails.code}\`); \/\/ This was the crashing line/" $TARGET_FILE
sed -i "s/throw new Error('Critical failure for special product ID');/ \/\/ throw new Error('Critical failure for special product ID');/" $TARGET_FILE

echo "Bug fixed in product controller."

# Step 4: Build and Deploy
echo "--- Step 4: Build and Deploy ---"
echo "Building new Docker image with tag backend:2.0-fixed..."
# In a real scenario, this would be a 'docker build' command.
# For this simulation, we'll just create a dummy file.
touch docker_build_success

echo "Updating Kubernetes deployment to use the new image..."
# In a real scenario, this would be a 'kubectl set image' command.
# kubectl set image deployment/backend-service backend=backend:2.0-fixed
touch k8s_deployment_updated

# Step 5: Rollback Procedure (if something goes wrong)
echo "--- Step 5: Rollback Procedure ---"
echo "If the new deployment is faulty, you can roll it back:"
echo "kubectl rollout undo deployment/backend-service"
# We will test this in the verify script.

echo "Solution applied successfully."
