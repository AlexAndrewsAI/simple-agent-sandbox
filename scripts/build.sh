#!/bin/bash
# build.sh - Build the Docker image (and optionally push to Docker Hub)
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f config.yml ]; then
  echo "config.yml not found. Create it from the example:"
  echo ""
  echo "  cp config.example.yml config.yml"
  echo ""
  echo "Then edit config.yml to enable the tools you want."
  exit 1
fi

if [ ! -f docker-compose.yml ]; then
  echo "docker-compose.yml not found. Create it from the example:"
  echo ""
  echo "  cp docker-compose.example.yml docker-compose.yml"
  echo ""
  echo "Then uncomment/adjust the volume mounts in docker-compose.yml."
  exit 1
fi

docker compose build --progress=plain "$@"

