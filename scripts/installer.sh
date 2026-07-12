#!/bin/bash
# installer.sh - Conditional tool installer driven by config.yml
# Reads /tmp/config.yml using yq and installs all tools listed under install.<key>.
set -euo pipefail

# Ensure both ~/.local/bin and ~/.npm-global/bin are on PATH so
# newly-installed binaries (pip, npm) are visible to the `command -v`
# fallback check below.
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"

# Validate that commands are safe before execution
# Allowlist of safe command patterns (extended regex)
# - curl with HTTPS for downloading installers
# - uv tool install for Python tools
# - npm install for Node.js packages
# - pip install for Python packages
# - bash execution of downloaded scripts (safely restricted)
#
# Security notes:
# - URL portions are restricted to [^[:space:]&|;<>$]+ so a URL cannot smuggle
#   in shell metacharacters (e.g. "https://x && rm ...").
# - File paths under /tmp are [^[:space:]]+ (no spaces), so the trailing
#   "&& ..." cleanup/download steps cannot be extended with extra commands.
# - Piped patterns only permit a single "| sh" / "| bash" at the end.
# - A defense-in-depth guard rejects command separators / substitution /
#   redirection that are never part of a legitimate install command.
validate_command() {
  local cmd="$1"

  # Defense in depth: reject characters that have no legitimate use in any
  # allowed install command (semicolons, backticks, command substitution,
  # and redirection). Pipe/&& are allowed because some patterns require them.
  local forbidden='[;<>$`]'
  if [[ "$cmd" =~ $forbidden ]]; then
    echo "ERROR: Command contains forbidden shell metacharacter: $cmd" >&2
    return 1
  fi

  local safe_patterns=(
    '^curl -[fLsSf]+ https://[^[:space:]&|;<>$]+[[:space:]]*\|[[:space:]]*sh$'
    '^curl -[fLsSf]+ https://[^[:space:]&|;<>$]+[[:space:]]*\|[[:space:]]*bash$'
    '^curl -[fLsSf]+ https://[^[:space:]&|;<>$]+[[:space:]]*-o[[:space:]]+/tmp/[^[:space:]]+[[:space:]]*&&[[:space:]]*bash[[:space:]]+/tmp/[^[:space:]]+[[:space:]]*&&[[:space:]]*rm[[:space:]]*-f[[:space:]]+/tmp/[^[:space:]]+$'
    '^curl -[fLsSf]+ https://[^[:space:]&|;<>$]+[[:space:]]*-o[[:space:]]+/tmp/[^[:space:]]+[[:space:]]*&&[[:space:]]*bash[[:space:]]+/tmp/[^[:space:]]+$'
    '^uv tool install [a-zA-Z0-9_-]+$'
    '^uv tool install [a-zA-Z0-9_-]+==[0-9.]+$'
    '^npm install( -[a-zA-Z]+)?( --[a-z-]+)?( [a-zA-Z0-9_@./+-]+)+$'
    '^pip install [a-zA-Z0-9_-]+$'
    '^pip install [a-zA-Z0-9_-]+==[0-9.]+$'
  )

  for pattern in "${safe_patterns[@]}"; do
    if [[ "$cmd" =~ $pattern ]]; then
      return 0
    fi
  done

  echo "ERROR: Command does not match safe patterns: $cmd" >&2
  echo "Safe patterns: curl downloads, uv tool install, npm install, pip install" >&2
  return 1
}

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

  # Validate command safety before execution
  if ! validate_command "$cmd"; then
    echo "ERROR: $key command failed validation" >&2
    exit 1
  fi

  # Run the install command. If it fails, check whether the tool binary
  # already exists on PATH — if so, skip with a warning; otherwise propagate
  # the error so set -e aborts the build.
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
