# win-cd-mount.ps1 - Auto-cd to mounted subfolder and automount_cwd logic

param(
    [string]$ProjectRoot,
    [string]$ConfigPath,
    [string]$ComposePath,
    [switch]$ForceAutomount
)

# Returns an object with ContainerCwd and AutomountVolume properties
function Get-ContainerMountInfo {
    param(
        [string]$ProjectRoot,
        [string]$ConfigPath,
        [string]$ComposePath,
        [switch]$ForceAutomount
    )

    # Check if yq is available
    $yq = Get-Command yq -ErrorAction SilentlyContinue
    if (-not $yq) {
        Write-Warning "yq not found — auto_cd_mount and automount_cwd features disabled. Install yq: https://github.com/mikefarahyq#install"
        return @{ ContainerCwd = $null; AutomountVolume = $null }
    }

    # Parse options from config.yml (defaults: auto_cd_mount=true, automount_cwd=false)
    $autoCdMount = (& yq -r '.options.auto_cd_mount // true' $ConfigPath 2>$null)
    $automountCwd = (& yq -r '.options.automount_cwd // false' $ConfigPath 2>$null)

    # yq failures (missing/unreadable config) fall back to the same defaults
    # run.sh uses: auto_cd_mount=true, automount_cwd=false
    if ([string]::IsNullOrEmpty($autoCdMount)) { $autoCdMount = "true" }
    if ([string]::IsNullOrEmpty($automountCwd)) { $automountCwd = "false" }

    if ($ForceAutomount) {
        $automountCwd = "true"
    }

    if ($autoCdMount -eq "false" -and $automountCwd -eq "false") {
        return @{ ContainerCwd = $null; AutomountVolume = $null }
    }

    # Get volumes from docker-compose.yml
    $volumes = (& yq -r '.services.sandbox.volumes[]? | select(. != null)' $ComposePath 2>$null)
    if (-not $volumes) {
        # No volumes defined — automount_cwd still works
        if ($automountCwd -ne "false") {
            $cwd = (Get-Location).Path
            return @{ ContainerCwd = "/cwd"; AutomountVolume = "-v ${cwd}:/cwd" }
        }
        return @{ ContainerCwd = $null; AutomountVolume = $null }
    }

    $cwd = (Get-Location).Path
    $cwdInMount = $false

    foreach ($vol in @($volumes)) {
        $vol = $vol.Trim()
        if (-not $vol -or -not $vol.Contains(":")) {
            continue
        }

        $parts = $vol -split ":", 2
        if ($parts.Count -ne 2) { continue }
        $hostPart = $parts[0].Trim()
        $containerPart = $parts[1].Trim()

        # Skip empty parts
        if (-not $hostPart -or -not $containerPart) { continue }

        # Expand tilde to home directory
        if ($hostPart.StartsWith('~')) {
            $hostPart = $hostPart -replace '^~', $HOME
        }

        # Resolve relative host paths
        if (-not [System.IO.Path]::IsPathRooted($hostPart)) {
            $hostAbs = Join-Path $ProjectRoot $hostPart
        } else {
            $hostAbs = $hostPart
        }
        $hostAbs = (Resolve-Path $hostAbs -ErrorAction SilentlyContinue).ProviderPath
        $cwdAbs = (Resolve-Path $cwd -ErrorAction SilentlyContinue).ProviderPath

        if (-not $hostAbs -or -not $cwdAbs) { continue }

        # Check if cwd is within this mount
        if ($cwdAbs.StartsWith($hostAbs + [System.IO.Path]::DirectorySeparatorChar) -or $cwdAbs -eq $hostAbs) {
            $relPath = $cwdAbs.Substring($hostAbs.Length)
            # Normalize path separators for container (Unix-style)
            $relPath = $relPath.TrimStart([System.IO.Path]::DirectorySeparatorChar) -replace '\\', '/'
            if ($relPath) {
                $containerCwd = $containerPart + "/" + $relPath
            } else {
                $containerCwd = $containerPart
            }
            # Ensure leading slash
            if (-not $containerCwd.StartsWith("/")) {
                $containerCwd = "/" + $containerCwd
            }
            $cwdInMount = $true
            return @{ ContainerCwd = $containerCwd; AutomountVolume = $null }
        }
    }

    # If cwd is NOT within any mount and automount_cwd is enabled, mount it
    if ($automountCwd -ne "false") {
        return @{ ContainerCwd = "/cwd"; AutomountVolume = "-v ${cwd}:/cwd" }
    }

    return @{ ContainerCwd = $null; AutomountVolume = $null }
}

# --- Entry point --------------------------------------------------------------
$mountInfo = Get-ContainerMountInfo -ProjectRoot $ProjectRoot -ConfigPath $ConfigPath -ComposePath $ComposePath -ForceAutomount:$ForceAutomount
# Output as structured data: first line = container cwd, second line = automount volume
if ($mountInfo.ContainerCwd) {
    Write-Output $mountInfo.ContainerCwd
}
if ($mountInfo.AutomountVolume) {
    Write-Output $mountInfo.AutomountVolume
}
