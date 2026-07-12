#!/bin/bash
# push.sh - Tag HEAD with the current version and push to origin.
# Also moves the "latest" tag to HEAD and pushes it.
# Usage: ./scripts/push.sh [--dry-run]
set -euo pipefail

cd "$(dirname "$0")/.." || exit

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[DRY-RUN] No commands will be executed"
fi

# --- Read version ------------------------------------------------------------
if [ ! -f pyproject.toml ]; then
  echo "Error: pyproject.toml not found" >&2
  exit 1
fi

VERSION=$(grep -oP '^version\s*=\s*"\K[^"]+' pyproject.toml)
if [ -z "$VERSION" ]; then
  echo "Error: could not extract version from pyproject.toml" >&2
  exit 1
fi

TAG="v$VERSION"
echo "Version: $VERSION"
echo "Tag:     $TAG"
echo ""

# --- Create version tag at HEAD ----------------------------------------------
if git rev-parse "$TAG" &>/dev/null; then
  echo "Tag $TAG already exists locally at $(git rev-parse --short "$TAG") — skipping creation"
else
  echo "Creating tag $TAG at HEAD..."
  $DRY_RUN || git tag "$TAG"
fi

# --- Push branch and version tag ---------------------------------------------
echo "Pushing branch and tag $TAG to origin..."
if $DRY_RUN; then
  echo "  git push origin HEAD --follow-tags"
else
  if ! git push origin HEAD --follow-tags 2>&1; then
    echo ""
    echo "============================================================"
    echo "  Push failed! You may need to sign in first."
    echo ""
    echo "  Options:"
    echo "    gh auth login         # GitHub CLI login"
    echo "    git push and enter credentials"
    echo "============================================================"
    exit 1
  fi
fi

# --- Move "latest" tag to HEAD ------------------------------------------------
echo "Moving 'latest' tag to HEAD..."
if $DRY_RUN; then
  echo "  git tag -d latest 2>/dev/null; git tag latest"
  echo "  git push origin :latest 2>/dev/null; git push origin latest"
else
  # Delete local latest if it exists
  if git rev-parse latest &>/dev/null; then
    git tag -d latest
  fi
  git tag latest
  # Delete remote latest if it exists, then push the new one
  git push origin :latest 2>/dev/null || true
  if ! git push origin latest 2>&1; then
    echo ""
    echo "============================================================"
    echo "  Push failed! You may need to sign in first."
    echo ""
    echo "  Options:"
    echo "    gh auth login         # GitHub CLI login"
    echo "    git push and enter credentials"
    echo "============================================================"
    exit 1
  fi
fi

echo ""
echo "Done. Pushed $TAG and updated 'latest' tag on origin."
