#!/bin/bash
# build.sh - Build the Docker image (and optionally push to Docker Hub)
set -euo pipefail
cd "$(dirname "$0")/.." || exit

# --- Prerequisite: config files ----------------------------------------------
source scripts/_config_check.sh

# Resolve sandbox password: env var > interactive prompt > default.
# Accept both SANDBOX_PW (preferred) and SANDBOX_PASSWORD (legacy)
# from the environment for backward compatibility.
if [ -z "${SANDBOX_PW:-}" ]; then
  SANDBOX_PW="${SANDBOX_PASSWORD:-}"
fi
if [ -z "${SANDBOX_PW:-}" ]; then
  if [ -t 0 ]; then
    read -r -s -p "Enter password for sandbox user (default: sandbox): " SANDBOX_PW
    echo
  fi
fi
if [ -z "${SANDBOX_PW:-}" ]; then
  SANDBOX_PW="sandbox"
fi

if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  docker compose build --progress=plain --build-arg SANDBOX_PW="$SANDBOX_PW" "$@"
elif command -v docker-compose &>/dev/null; then
  docker-compose build --progress=plain --build-arg SANDBOX_PW="$SANDBOX_PW" "$@"
else
  echo "Error: neither 'docker compose' nor 'docker-compose' is installed" >&2
  exit 1
fi
