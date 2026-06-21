# run.ps1 - Start an interactive shell inside the sandbox container
# Reads mounts from config.yml and passes them as -v flags to docker compose run

$configPath = Join-Path $PSScriptRoot "..\config.yml"

$volumeFlags = @()

if (Test-Path $configPath) {
    $inMounts = $false
    Get-Content $configPath | ForEach-Object {
        $line = $_
        if ($line -match '^mounts:') {
            $inMounts = $true
            return
        }
        if ($inMounts -and $line -match '^\s*-\s*"(.+)"$') {
            $volumeFlags += "-v"
            $volumeFlags += $Matches[1]
        }
    }
}

$dockerArgs = @("compose", "run", "--rm")
if ($volumeFlags.Count -gt 0) {
    $dockerArgs += $volumeFlags
}
$dockerArgs += "sandbox"
docker @dockerArgs
