#!/bin/bash
# build.sh - Build the Docker image (and optionally push to Docker Hub)
set -euo pipefail
cd "$(dirname "$0")/.." || exit

# --- Prerequisite: config files ----------------------------------------------
source scripts/_config_check.sh

docker compose build --progress=plain "$@"

