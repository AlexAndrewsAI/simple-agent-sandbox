#!/bin/bash
# installer.sh - Conditional tool installer driven by config.yml
# Reads /tmp/config.yml using yq and installs tools marked as true in the install list.
set -euo pipefail

# Hermes agent by NousResearch
if [ "$(yq '.install.hermes' /tmp/config.yml)" = "true" ]; then
  echo "Installing hermes"
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh -o /tmp/hermes_install.sh
  bash /tmp/hermes_install.sh
  rm -f /tmp/hermes_install.sh
  echo "Hermes install complete"
else
  echo "Skipping hermes"
fi

# Devin CLI by Cognition
# Note: the install script is interactive (requires login), so we ignore its exit code.
# The binary should still be downloaded to ~/.local/bin/devin.
if [ "$(yq '.install.devin' /tmp/config.yml)" = "true" ]; then
  echo "Installing devin"
  curl -fsSL https://cli.devin.ai/install.sh -o /tmp/devin_install.sh
  bash /tmp/devin_install.sh || echo "Devin install script exited non-zero (interactive login not possible in build); binary may still be present"
  rm -f /tmp/devin_install.sh
  if command -v devin &>/dev/null; then
    echo "Devin binary installed successfully"
  else
    echo "Warning: devin binary not found in PATH after install"
  fi
else
  echo "Skipping devin"
fi
