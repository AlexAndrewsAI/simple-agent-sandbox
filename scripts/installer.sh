#!/bin/bash
# installer.sh - Conditional tool installer driven by config.yml
# Reads /tmp/config.yml using yq and installs all tools listed under install.<key>.
set -euo pipefail
set -x

# Ensure ~/.local/bin is on PATH so newly-installed binaries are visible
# to the `command -v` fallback check below.
export PATH="$HOME/.local/bin:$PATH"

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

  # Run the install command. If it fails, check whether the tool binary
  # already exists on PATH — if so, skip silently; otherwise propagate the
  # error so set -e aborts the build.
  if ! eval "$cmd"; then
    if command -v "$key" &>/dev/null; then
      echo "$key install reported failure but binary is present — skipping"
    else
      echo "ERROR: $key install failed and binary not found" >&2
      exit 1
    fi
  fi

  echo "$key install complete"
  installed_path=$(command -v "$key" || true)
  if [ -n "$installed_path" ]; then
    echo "Installed at: $installed_path"
  fi
done
