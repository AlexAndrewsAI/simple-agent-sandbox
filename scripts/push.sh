#!/bin/bash
# push.sh - Build and push Docker image to Docker Hub with version and branch tags.
# Usage: ./scripts/push.sh [--branch TAG] [--dry-run]
#   --branch TAG   Source tag to use for versioning (default: latest)
#   --dry-run      Print commands without executing
set -euo pipefail

cd "$(dirname "$0")/.." || exit

# --- Prerequisite: config files ----------------------------------------------
source scripts/_config_check.sh

# --- Parse arguments ----------------------------------------------------------
BRANCH="latest"
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      if [[ $# -lt 2 ]]; then
        echo "Error: --branch requires a tag name" >&2
        exit 1
      fi
      BRANCH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if $DRY_RUN; then
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
echo "Branch:  $BRANCH"
echo "Tags:    $VERSION, $BRANCH"
echo ""

# --- Build the image ---------------------------------------------------------
echo "Building $IMAGE:$BRANCH ..."
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

  # --- Validate source image exists --------------------------------------------
  if ! docker image inspect "$IMAGE:$BRANCH" &>/dev/null; then
    echo ""
    echo "============================================================"
    echo "  Error: $IMAGE:$BRANCH not found after build."
    echo "  Check that the image tag in docker-compose.yml matches."
    echo "============================================================"
    exit 1
  fi
fi

# --- Tag with version --------------------------------------------------------
echo "Tagging $IMAGE:$VERSION ..."
if $DRY_RUN; then
  echo "  docker tag $IMAGE:$BRANCH $IMAGE:$VERSION"
else
  docker tag "$IMAGE:$BRANCH" "$IMAGE:$VERSION"
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

echo "Pushing $IMAGE:$BRANCH ..."
if $DRY_RUN; then
  echo "  docker push $IMAGE:$BRANCH"
else
  if ! docker push "$IMAGE:$BRANCH" 2>&1; then
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
echo "Done. Pushed $IMAGE:$VERSION and $IMAGE:$BRANCH to Docker Hub."
