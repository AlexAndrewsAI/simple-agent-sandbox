#!/bin/bash
# build.sh - Build the Docker image (and optionally push to Docker Hub)
set -euo pipefail
cd "$(dirname "$0")/.." || exit

# --- Prerequisite: config files ----------------------------------------------
source scripts/_config_check.sh

# Prompt for sandbox user password
read -r -s -p "Enter password for sandbox user (default: sandbox): " SANDBOX_PASSWORD
echo
if [ -z "$SANDBOX_PASSWORD" ]; then
  SANDBOX_PASSWORD="sandbox"
fi

if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  docker compose build --progress=plain --build-arg SANDBOX_PASSWORD="$SANDBOX_PASSWORD" "$@"
elif command -v docker-compose &>/dev/null; then
  docker-compose build --progress=plain --build-arg SANDBOX_PASSWORD="$SANDBOX_PASSWORD" "$@"
else
  echo "Error: neither 'docker compose' nor 'docker-compose' is installed" >&2
  exit 1
fi
