# _config_check.ps1 — Shared config-file prerequisite check
# Dot-source this from win-build.ps1 or win-run.ps1.
# Derives the project root from its own location in scripts/.
# Exits with code 1 if the user declines to copy missing example files.

$checkRoot = Split-Path -Parent $PSScriptRoot

$missingFiles = @()
if (-not (Test-Path "$checkRoot\config.yml")) {
  $missingFiles += "config.yml"
}
if (-not (Test-Path "$checkRoot\docker-compose.yml")) {
  $missingFiles += "docker-compose.yml"
}

if ($missingFiles.Count -gt 0) {
  Write-Host "The following config files are missing:" -ForegroundColor Yellow
  foreach ($file in $missingFiles) {
    Write-Host "  - $file"
  }
  Write-Host ""

  if (-not [Console]::IsInputRedirected) {
    # Interactive terminal — prompt the user
    $response = Read-Host "Copy from example files? [y/N]"
  } else {
    # Non-interactive (CI, pipes, etc.) — auto-copy if possible
    Write-Host "Non-interactive mode detected — auto-copying from example files."
    $response = "y"
  }

  if ($response -eq 'y' -or $response -eq 'Y') {
    foreach ($file in $missingFiles) {
      $example = $file -replace '\.yml$', '.example.yml'
      if (Test-Path "$checkRoot\$example") {
        Copy-Item "$checkRoot\$example" "$checkRoot\$file"
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
