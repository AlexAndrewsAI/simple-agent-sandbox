#!/bin/bash
# installer.sh - Conditional tool installer driven by config.yml
# Reads /tmp/config.yml using yq and installs all tools listed under install.<key>.
set -euo pipefail

# Count of install entries
count=$(yq '.install | length' /tmp/config.yml)

if [ "$count" -eq 0 ]; then
  echo "No install entries found in config.yml"
  exit 0
fi

# Iterate over each key in .install
for i in $(seq 0 $((count - 1))); do
  key=$(yq ".install | keys[$i]" /tmp/config.yml)
  cmd=$(yq ".install.$key" /tmp/config.yml)

  echo "Installing $key: $cmd"
  eval "$cmd"
  echo "$key install complete"
done