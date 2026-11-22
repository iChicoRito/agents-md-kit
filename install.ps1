# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   .\install.ps1 [target folder]                          (from a clone)
#   irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1 | iex
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
param([string]$Target = (Get-Location).Path)
$ErrorActionPreference = 'Stop'

$archive = "https://github.com/iChicoRito/agents-md-kit/archive/refs/heads/main.zip"
if (-not (Test-Path $Target -PathType Container)) { throw "Target folder not found: $Target" }
$Target = (Resolve-Path $Target).Path

# Use the template next to this script; if run through irm | iex, download it.
$tmp = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "template"))) {
    $Template = Join-Path $PSScriptRoot "template"
} else {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("agents-md-kit-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Write-Host "Downloading template..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $archive -OutFile "$tmp\kit.zip" -UseBasicParsing
    Expand-Archive -Path "$tmp\kit.zip" -DestinationPath $tmp
    $Template = (Get-ChildItem -Path $tmp -Directory | ForEach-Object { Join-Path $_.FullName "template" } |
        Where-Object { Test-Path $_ } | Select-Object -First 1)
    if (-not $Template) { throw "Download failed: template folder not found" }
}

try {
    $copied = 0; $skipped = @(); $gitignoreAdded = $null
    Get-ChildItem -Path $Template -Recurse -Force -File | ForEach-Object {
        $rel = $_.FullName.Substring($Template.Length).TrimStart('\', '/')
        $dest = Join-Path $Target $rel
        if ($rel -eq '.gitignore' -and (Test-Path $dest)) {
            $have = @(Get-Content -LiteralPath $dest | ForEach-Object { $_.Trim() })
            $missing = @(Get-Content -LiteralPath $_.FullName | ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and -not $_.StartsWith('#') -and $have -notcontains $_ })
            if ($missing.Count) {
                $raw = [IO.File]::ReadAllText($dest)
                $nl = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
                $text = $(if ($raw -and -not $raw.EndsWith("`n")) { $nl } else { '' }) +
                    "$nl# Added by agents-md-kit$nl" + ($missing -join $nl) + $nl
                [IO.File]::AppendAllText($dest, $text)
            }
            $gitignoreAdded = $missing
            return
        }
        if (Test-Path $dest) { $skipped += $rel; return }
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $dest
        $copied++
    }

    Write-Host "Copied $copied file(s) into $Target"
    if ($null -ne $gitignoreAdded) {
        if ($gitignoreAdded.Count) { Write-Host "Updated existing .gitignore, added: $($gitignoreAdded -join ', ')" }
        else { Write-Host "Existing .gitignore already has all template lines" }
    }
    if ($skipped.Count) {
        Write-Host "Skipped $($skipped.Count) existing file(s), merge by hand:"
        $skipped | ForEach-Object { Write-Host "  $_" }
    }
    Write-Host "Next: fill the [PLACEHOLDERS] in CLAUDE.md and docs/. Skills setup: docs/guides/setup.md"
} finally {
    if ($tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
