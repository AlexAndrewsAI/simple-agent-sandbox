#!/bin/bash
# build.sh - Build the Docker image
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose build --progress=plain "$@"
