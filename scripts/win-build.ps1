# build.ps1 - Build the Docker image (and optionally push to Docker Hub)

# --- Prerequisite: config files ----------------------------------------------
. (Join-Path $PSScriptRoot "_config_check.ps1")

# Resolve sandbox password: env var > interactive prompt > default
if (-not $env:SANDBOX_PASSWORD) {
    if (-not [Console]::IsInputRedirected) {
        $securePassword = Read-Host -AsSecureString "Enter password for sandbox user (default: sandbox)"
        if ($null -eq $securePassword -or $securePassword.Length -eq 0) {
            $env:SANDBOX_PASSWORD = "sandbox"
        } else {
            # Convert SecureString to plain text (required for docker build-arg)
            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
            try {
                $env:SANDBOX_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
            } finally {
                [System.Runtime.InteropServices.Marshal]::FreeBSTR($ptr)
            }
        }
    } else {
        $env:SANDBOX_PASSWORD = "sandbox"
    }
}

docker compose build --progress=plain --build-arg SANDBOX_PASSWORD="$env:SANDBOX_PASSWORD" @args
