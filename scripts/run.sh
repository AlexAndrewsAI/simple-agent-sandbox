#!/bin/bash
# run.sh - Start an interactive shell inside the sandbox container
cd "$(dirname "$0")/.."
docker compose run --rm sandbox
