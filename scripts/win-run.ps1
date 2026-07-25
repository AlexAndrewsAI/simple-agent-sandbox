# run.ps1 - Start an interactive shell inside the sandbox container

# --- Prerequisite: config files ----------------------------------------------
. "$PSScriptRoot\_config_check.ps1"

# --- Auto-cd to mounted subfolder / automount_cwd ----------------------------
$mountOutput = & "$PSScriptRoot\win-cd-mount.ps1" -ProjectRoot $checkRoot -ConfigPath "$checkRoot\config.yml" -ComposePath "$checkRoot\docker-compose.yml"
$mountLines = $mountOutput | Where-Object { $_ -ne $null -and $_ -ne "" }

$containerCwd = $null
$automountVolume = $null

if ($mountLines -is [array]) {
    if ($mountLines.Count -ge 1) { $containerCwd = $mountLines[0] }
    if ($mountLines.Count -ge 2) { $automountVolume = $mountLines[1] }
} elseif ($mountLines) {
    $containerCwd = $mountLines
}

if ($containerCwd) {
    if ($automountVolume) {
        docker compose run --rm $automountVolume.Split(" ") sandbox bash -c "cd '$containerCwd' && exec bash"
    } else {
        docker compose run --rm sandbox bash -c "cd '$containerCwd' && exec bash"
    }
} else {
    docker compose run --rm sandbox bash
}
