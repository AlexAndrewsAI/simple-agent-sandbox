# build.ps1 - Build the Docker image (and optionally push to Docker Hub)
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path "$repoRoot\config.yml")) {
  Write-Host "config.yml not found. Create it from the example:" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  cp config.example.yml config.yml"
  Write-Host ""
  Write-Host "Then edit config.yml to enable the tools you want."
  exit 1
}

if (-not (Test-Path "$repoRoot\docker-compose.yml")) {
  Write-Host "docker-compose.yml not found. Create it from the example:" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  cp docker-compose.example.yml docker-compose.yml"
  Write-Host ""
  Write-Host "Then uncomment/adjust the volume mounts in docker-compose.yml."
  exit 1
}

docker compose build --progress=plain

