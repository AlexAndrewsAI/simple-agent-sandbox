#!/bin/bash
# _config_check.sh — Shared config-file prerequisite check
# Source this from build.sh or run.sh.  Derives the project root from its own
# location so it works regardless of the caller's working directory.
# Exits with code 1 if the user declines to copy missing example files.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

missing_files=()
[ ! -f "$PROJECT_ROOT/config.yml" ] && missing_files+=("config.yml")
[ ! -f "$PROJECT_ROOT/docker-compose.yml" ] && missing_files+=("docker-compose.yml")

if [ ${#missing_files[@]} -gt 0 ]; then
  echo "The following config files are missing:"
  for file in "${missing_files[@]}"; do
    echo "  - $file"
  done
  echo ""
  if [ -t 0 ]; then
    # Interactive terminal — prompt the user
    read -p "Copy from example files? [y/N] " -n 1 -r
    echo
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    # Non-interactive (CI, pipes, etc.) — auto-copy if possible
    echo "Non-interactive mode detected — auto-copying from example files."
  fi
  for file in "${missing_files[@]}"; do
    example="${file%.yml}.example.yml"
    if [ -f "$PROJECT_ROOT/$example" ]; then
      cp "$PROJECT_ROOT/$example" "$PROJECT_ROOT/$file"
      echo "Copied $example to $file"
    else
      echo "ERROR: $example not found" >&2
      exit 1
    fi
  done
fi
