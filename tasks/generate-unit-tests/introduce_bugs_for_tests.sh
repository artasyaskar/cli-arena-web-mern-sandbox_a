#!/bin/bash
set -e

# This script introduces a bug into the product repository that the unit tests should catch.
# The bug is in the 'findAll' method's aggregation pipeline.
# We will change the 'from' field in the $lookup stage to a non-existent collection.
# This will cause the 'purchaseCount' to be calculated incorrectly (it will always be 0).

TARGET_FILE="src/server/src/repositories/productRepository.ts"

# Use sed to replace the line with the bug
sed -i "s/from: 'purchases'/from: 'non_existent_purchases'/" $TARGET_FILE

echo "Bug introduced into product repository."
