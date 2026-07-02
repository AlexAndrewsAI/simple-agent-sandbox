# build.ps1 - Build the Docker image (and optionally push to Docker Hub)

# --- Prerequisite: config files ----------------------------------------------
. "$PSScriptRoot\_config_check.ps1"

docker compose build --progress=plain
