#!/bin/bash
# build.sh - Build the Docker image (and optionally push to Docker Hub)
set -euo pipefail
cd "$(dirname "$0")/.." || exit

# --- Prerequisite: config files ----------------------------------------------
source scripts/_config_check.sh

if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  docker compose build --progress=plain "$@"
elif command -v docker-compose &>/dev/null; then
  docker-compose build --progress=plain "$@"
else
  echo "Error: neither 'docker compose' nor 'docker-compose' is installed" >&2
  exit 1
fi
