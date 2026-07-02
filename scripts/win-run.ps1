# run.ps1 - Start an interactive shell inside the sandbox container
$repoRoot = Split-Path -Parent $PSScriptRoot

# --- Prerequisite: config files ----------------------------------------------
$missingFiles = @()
if (-not (Test-Path "$repoRoot\config.yml")) {
  $missingFiles += "config.yml"
}
if (-not (Test-Path "$repoRoot\docker-compose.yml")) {
  $missingFiles += "docker-compose.yml"
}

if ($missingFiles.Count -gt 0) {
  Write-Host "The following config files are missing:" -ForegroundColor Yellow
  foreach ($file in $missingFiles) {
    Write-Host "  - $file"
  }
  Write-Host ""
  $response = Read-Host "Copy from example files? [y/N]"
  if ($response -eq 'y' -or $response -eq 'Y') {
    foreach ($file in $missingFiles) {
      $example = $file -replace '\.yml$', '.example.yml'
      if (Test-Path "$repoRoot\$example") {
        Copy-Item "$repoRoot\$example" "$repoRoot\$file"
        Write-Host "Copied $example to $file" -ForegroundColor Green
      } else {
        Write-Host "ERROR: $example not found" -ForegroundColor Red
        exit 1
      }
    }
  } else {
    exit 1
  }
}

docker compose run --rm sandbox
