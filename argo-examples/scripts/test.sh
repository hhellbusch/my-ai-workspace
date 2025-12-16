#!/bin/bash

# Check for required dependencies
for cmd in find jq; do
  if ! command -v $cmd &> /dev/null; then
    echo "ERROR: Required command '$cmd' not found. Please install it first."
    exit 1
  fi
done

# Reusable function to discover directories and convert to JSON array
get_directories_as_json() {
  local path=$1
  local label=$2
  
  # Get list of directories (excluding hidden directories)
  local dirs=$(find ${path} -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -exec basename {} \; | sort)
  
  # Convert to JSON array format
  local json_array=$(echo "$dirs" | jq -R -s -c 'split("\n") | map(select(length > 0))')
  
  echo "Discovered ${label} directories: $json_array"
  echo "$json_array"
}

# Change to the argo-examples directory to ensure relative paths work
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# Discover applications
APP_ARRAY=$(get_directories_as_json "./apps" "application")
echo "APP_DIRECTORIES=$APP_ARRAY"