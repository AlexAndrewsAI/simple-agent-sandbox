#!/bin/bash
# run.sh - Start an interactive shell inside the sandbox container
cd "$(dirname "$0")/.."
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  docker compose run --rm sandbox bash
elif command -v docker-compose &>/dev/null; then
  docker-compose run --rm sandbox bash
else
  echo "Error: neither 'docker compose' nor 'docker-compose' is installed" >&2
  exit 1
fi
