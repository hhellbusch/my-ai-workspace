#!/bin/bash

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