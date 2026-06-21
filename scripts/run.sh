#!/bin/bash
# run.sh - Start an interactive shell inside the sandbox container
# Reads mounts from config.yml and passes them as -v flags to docker compose run
set -euo pipefail

# Ensure user-local bin is in PATH for tools like yq
export PATH="$HOME/.local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.yml"

VOLUME_FLAGS=()
if [ -f "$CONFIG_FILE" ]; then
  count=$(yq '.mounts // [] | length' "$CONFIG_FILE")
  for i in $(seq 0 $((count - 1))); do
    mount=$(yq -r ".mounts[$i]" "$CONFIG_FILE")
    VOLUME_FLAGS+=("-v" "$mount")
  done
fi


echo "Starting sandbox with mounts: ${VOLUME_FLAGS[*]}"
docker compose run --rm "${VOLUME_FLAGS[@]}" sandbox
