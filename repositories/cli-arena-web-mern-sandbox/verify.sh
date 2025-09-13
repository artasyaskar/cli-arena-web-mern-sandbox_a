#!/usr/bin/env bash
set -euo pipefail
cd "/repo" || true

if [ -z "${1:-}" ]; then
  echo "Usage: ./verify.sh <task-id>"
  exit 1
fi

TASK_ID=$1
TASK_DIR="tasks/$TASK_ID"

if [ ! -d "$TASK_DIR" ]; then
  echo "Error: Task '$TASK_ID' directory not found."
  exit 1
fi

VERIFY_SCRIPT="$TASK_DIR/verify.sh"

if [ ! -f "$VERIFY_SCRIPT" ]; then
  echo "Error: verify.sh not found for task '$TASK_ID'."
  exit 1
fi

# Make sure the script is executable
chmod +x "$VERIFY_SCRIPT"

# Execute the task-specific verification script
exec "$VERIFY_SCRIPT"
