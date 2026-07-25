#!/bin/bash
# run.sh - Start an interactive shell inside the sandbox container
set -euo pipefail
ORIGINAL_CWD="$(pwd)"
cd "$(dirname "$0")/.." || exit

# --- Prerequisite: config files ----------------------------------------------
source scripts/_config_check.sh

# --- yq availability (needed for auto-cd and automount) ----------------------
if ! command -v yq &>/dev/null; then
    echo "WARNING: yq not found — auto_cd_mount and automount_cwd features disabled." >&2
    echo "Install yq: https://github.com/mikefarahyq#install" >&2
fi

# --- Parse options from config.yml -------------------------------------------
auto_cd_mount=$(yq -r '.options.auto_cd_mount // true' config.yml 2>/dev/null || echo "true")
automount_cwd=$(yq -r '.options.automount_cwd // false' config.yml 2>/dev/null || echo "false")

# --- Determine container working directory ------------------------------------
container_cwd=""
automount_volume=""

if [[ "$auto_cd_mount" != "false" || "$automount_cwd" != "false" ]]; then
    volumes=$(yq -r '.services.sandbox.volumes[]? | select(. != null)' docker-compose.yml 2>/dev/null || true)
    if [[ -n "$volumes" ]]; then
        cwd="$ORIGINAL_CWD"
        cwd_in_mount=false

        for vol in $volumes; do
            if [[ "$vol" != *:* ]]; then
                continue
            fi
            host_part="${vol%%:*}"
            container_part="${vol##*:}"
            [[ -z "$host_part" || -z "$container_part" ]] && continue

            # Resolve relative host paths
            if [[ "$host_part" == /* ]]; then
                host_abs="$host_part"
            else
                host_abs="$PROJECT_ROOT/$host_part"
            fi
            host_abs=$(realpath "$host_abs" 2>/dev/null || echo "$host_abs")
            cwd_abs=$(realpath "$cwd" 2>/dev/null || echo "$cwd")

            # Check if cwd is within this mount
            if [[ "$cwd_abs" == "$host_abs"* ]]; then
                rel_path="${cwd_abs#"$host_abs"}"
                rel_path="${rel_path#/}"  # Remove leading slash if present
                if [[ -n "$rel_path" ]]; then
                    container_cwd="$container_part/$rel_path"
                else
                    container_cwd="$container_part"
                fi
                cwd_in_mount=true
                break
            fi
        done

        # If cwd is NOT within any mount and automount_cwd is enabled, mount it
        if [[ "$cwd_in_mount" == "false" && "$automount_cwd" != "false" ]]; then
            automount_volume="-v $ORIGINAL_CWD:/cwd"
            container_cwd="/cwd"
        fi
    else
        # No volumes defined — automount_cwd still works
        if [[ "$automount_cwd" != "false" ]]; then
            automount_volume="-v $ORIGINAL_CWD:/cwd"
            container_cwd="/cwd"
        fi
    fi
fi

# --- Run docker ----------------------------------------------------------------
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
    if [[ -n "$container_cwd" ]]; then
        vol_args=()
        if [[ -n "$automount_volume" ]]; then
            read -ra vol_args <<< "$automount_volume"
        fi
        docker compose run --rm "${vol_args[@]}" sandbox bash -c "cd '$container_cwd' && exec bash"
    else
        docker compose run --rm sandbox bash
    fi
elif command -v docker-compose &>/dev/null; then
    if [[ -n "$container_cwd" ]]; then
        vol_args=()
        if [[ -n "$automount_volume" ]]; then
            read -ra vol_args <<< "$automount_volume"
        fi
        docker-compose run --rm "${vol_args[@]}" sandbox bash -c "cd '$container_cwd' && exec bash"
    else
        docker-compose run --rm sandbox bash
    fi
else
    echo "Error: neither 'docker compose' nor 'docker-compose' is installed" >&2
    exit 1
fi
