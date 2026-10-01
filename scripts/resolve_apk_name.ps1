$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$override = $env:APP_NAME_OVERRIDE

if ($override) {
    $label = $override
} else {
    $manifest = Join-Path $root 'android\app\src\main\AndroidManifest.xml'
    if (-not (Test-Path $manifest)) {
        Write-Error 'AndroidManifest.xml not found'
    }
    $content = Get-Content -Raw $manifest
    if ($content -notmatch 'android:label="([^"]+)"') {
        Write-Error 'android:label not found in manifest'
    }
    $label = $matches[1]
}

$pubspec = Join-Path $root 'pubspec.yaml'
if (-not (Test-Path $pubspec)) {
    Write-Error 'pubspec.yaml not found'
}

$versionLine = Get-Content $pubspec |
    Where-Object { $_ -match '^\s*version:\s*(.+)$' } |
    Select-Object -First 1

if (-not $versionLine) {
    Write-Error 'version: not found in pubspec.yaml'
}

$raw = ($versionLine -replace '^\s*version:\s*', '').Trim()

if ($raw -match '^([^+]+)\+(\d+)$') {
    $suffix = "V$($matches[1])+$($matches[2])"
} elseif ($raw -match '^([^+]+)$') {
    $suffix = "V$($matches[1])"
} else {
    Write-Error "Invalid version format: $raw"
}

$safe = ($label -replace '[\\/:*?"<>|]', '').Trim()
$safe = ($safe -replace '\s+', '_')

if ([string]::IsNullOrWhiteSpace($safe)) {
    Write-Error 'App label is empty after sanitization'
}

Write-Output "${safe}_${suffix}.apk"
