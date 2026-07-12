#!/bin/bash
# push.sh - Build and push Docker image to Docker Hub with version and latest tags.
# Usage: ./scripts/push.sh [--dry-run]
set -euo pipefail

cd "$(dirname "$0")/.." || exit

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[DRY-RUN] No commands will be executed"
fi

# Image config
IMAGE="alexandrewsai/simple-agent-sandbox"

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

echo "Image:  $IMAGE"
echo "Version: $VERSION"
echo "Tags:   $VERSION, latest"
echo ""

# --- Build the image ---------------------------------------------------------
echo "Building $IMAGE:$VERSION ..."
if $DRY_RUN; then
  echo "  docker compose build"
else
  if ! docker compose build 2>&1; then
    echo ""
    echo "============================================================"
    echo "  Build failed."
    echo "============================================================"
    exit 1
  fi
fi

# --- Tag with version --------------------------------------------------------
echo "Tagging $IMAGE:$VERSION ..."
if $DRY_RUN; then
  echo "  docker tag $IMAGE:latest $IMAGE:$VERSION"
else
  docker tag "$IMAGE:latest" "$IMAGE:$VERSION"
fi

# --- Push both tags to Docker Hub --------------------------------------------
echo "Pushing $IMAGE:$VERSION ..."
if $DRY_RUN; then
  echo "  docker push $IMAGE:$VERSION"
else
  if ! docker push "$IMAGE:$VERSION" 2>&1; then
    echo ""
    echo "============================================================"
    echo "  Push failed! You may need to sign in to Docker Hub first."
    echo ""
    echo "  Run: docker login"
    echo "============================================================"
    exit 1
  fi
fi

echo "Pushing $IMAGE:latest ..."
if $DRY_RUN; then
  echo "  docker push $IMAGE:latest"
else
  if ! docker push "$IMAGE:latest" 2>&1; then
    echo ""
    echo "============================================================"
    echo "  Push failed! You may need to sign in to Docker Hub first."
    echo ""
    echo "  Run: docker login"
    echo "============================================================"
    exit 1
  fi
fi

echo ""
echo "Done. Pushed $IMAGE:$VERSION and $IMAGE:latest to Docker Hub."
