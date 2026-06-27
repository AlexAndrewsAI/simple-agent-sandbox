#!/bin/bash
# build.sh - Build the Docker image (and optionally push to Docker Hub)
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose build --progress=plain "$@"
if [[ "${PUSH_IMAGE:-0}" == "1" ]]; then
  docker push alexandrewsai/simple-agent-sandbox:latest
fi
