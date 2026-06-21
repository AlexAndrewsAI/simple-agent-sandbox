#!/bin/bash
# run.sh - Start an interactive shell inside the sandbox container
# Reads mounts from config.yml and passes them as -v flags to docker compose run
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.yml"

VOLUME_FLAGS=()
if [ -f "$CONFIG_FILE" ]; then
  count=$(yq '.mounts // [] | length' "$CONFIG_FILE")
  for i in $(seq 0 $((count - 1))); do
    mount=$(yq ".mounts[$i]" "$CONFIG_FILE")
    VOLUME_FLAGS+=("-v" "$mount")
  done
fi

docker compose run --rm "${VOLUME_FLAGS[@]}" sandbox
