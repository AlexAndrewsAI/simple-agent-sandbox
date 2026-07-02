#!/bin/bash
# build.sh - Build the Docker image (and optionally push to Docker Hub)
set -euo pipefail
cd "$(dirname "$0")/.."

# --- Prerequisite: config files ----------------------------------------------
missing_files=()
[ ! -f config.yml ] && missing_files+=("config.yml")
[ ! -f docker-compose.yml ] && missing_files+=("docker-compose.yml")

if [ ${#missing_files[@]} -gt 0 ]; then
  echo "The following config files are missing:"
  for file in "${missing_files[@]}"; do
    echo "  - $file"
  done
  echo ""
  read -p "Copy from example files? [y/N] " -n 1 -r
  echo
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    for file in "${missing_files[@]}"; do
      example="${file%.yml}.example.yml"
      if [ -f "$example" ]; then
        cp "$example" "$file"
        echo "Copied $example to $file"
      else
        echo "ERROR: $example not found" >&2
        exit 1
      fi
    done
  else
    exit 1
  fi
fi

docker compose build --progress=plain "$@"

