#!/bin/bash
# build.sh - Build the Docker image
set -euo pipefail
docker compose build --progress=plain
