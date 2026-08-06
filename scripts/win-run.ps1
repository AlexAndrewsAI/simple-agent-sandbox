# run.ps1 - Start an interactive shell inside the sandbox container

param(
    [Alias("a")]
    [switch]$AutomountCwd,
    [Alias("n")]
    [switch]$NoInternet
)

# --- Prerequisite: config files ----------------------------------------------
. (Join-Path $PSScriptRoot "_config_check.ps1")

# --- Auto-cd to mounted subfolder / automount_cwd ----------------------------
$mountOutput = & (Join-Path $PSScriptRoot "win-cd-mount.ps1") -ProjectRoot $checkRoot -ConfigPath (Join-Path $checkRoot "config.yml") -ComposePath (Join-Path $checkRoot "docker-compose.yml") -ForceAutomount:$AutomountCwd.IsPresent
$mountLines = $mountOutput | Where-Object { $_ -ne $null -and $_ -ne "" }

$containerCwd = $null
$automountVolume = $null

if ($mountLines -is [array]) {
    if ($mountLines.Count -ge 1) { $containerCwd = $mountLines[0] }
    if ($mountLines.Count -ge 2) { $automountVolume = $mountLines[1] }
} elseif ($mountLines) {
    $containerCwd = $mountLines
}

# --- Resolve no-internet: CLI flag takes precedence over config -----------------
$noInternetEnabled = $false
$yq = Get-Command yq -ErrorAction SilentlyContinue
if ($yq) {
    $cfgNoInternet = (& yq -r '.options.no_internet // false' (Join-Path $checkRoot "config.yml") 2>$null)
    if ($cfgNoInternet -eq "true") { $noInternetEnabled = $true }
}
if ($NoInternet.IsPresent) { $noInternetEnabled = $true }

$composeArgs = @("-f", (Join-Path $checkRoot "docker-compose.yml"))
$noNetworkOverride = $null
if ($noInternetEnabled) {
    $noNetworkOverride = Join-Path ([System.IO.Path]::GetTempPath()) ("no-internet-" + [guid]::NewGuid().ToString("N") + ".yml")
    @'
services:
  sandbox:
    network_mode: none
'@ | Set-Content -Path $noNetworkOverride -Encoding UTF8
    $composeArgs += @("-f", $noNetworkOverride)
}

if ($containerCwd) {
    if ($automountVolume) {
        docker compose @composeArgs run --rm $automountVolume.Split(" ") sandbox bash -c "cd '$containerCwd' && exec bash"
    } else {
        docker compose @composeArgs run --rm sandbox bash -c "cd '$containerCwd' && exec bash"
    }
} else {
    docker compose @composeArgs run --rm sandbox bash
}

if ($noNetworkOverride) {
    Remove-Item $noNetworkOverride -ErrorAction SilentlyContinue
}
