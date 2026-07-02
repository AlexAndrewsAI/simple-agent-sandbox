# run.ps1 - Start an interactive shell inside the sandbox container

# --- Prerequisite: config files ----------------------------------------------
. "$PSScriptRoot\_config_check.ps1"

docker compose run --rm sandbox
