# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   .\install.ps1 [-For claude|agents|both] [target folder]          (from a clone)
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For claude
# -For claude: Claude Code only (CLAUDE.md, .claude/)
# -For agents: Codex and other agents only (AGENTS.md, .agents/)
# -For both:   both (default when no choice is given and nobody can be asked)
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
param([string]$Target = (Get-Location).Path, [string]$For = "")
$ErrorActionPreference = 'Stop'

$archive = "https://github.com/iChicoRito/agents-md-kit/archive/refs/heads/main.zip"
if (-not (Test-Path $Target -PathType Container)) { throw "Target folder not found: $Target" }
$Target = (Resolve-Path $Target).Path

# No choice given: ask if someone is at the keyboard, else use "both".
if (-not $For) {
    $answer = ""
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        Write-Host "Which AI agents will you use in this project?"
        Write-Host "  1) Claude Code only"
        Write-Host "  2) Codex or other agents only"
        Write-Host "  3) Both (default)"
        try { $answer = Read-Host "Choose 1, 2 or 3" } catch { $answer = "" }
    }
    $For = switch ($answer) { "1" { "claude" } "2" { "agents" } default { "both" } }
}
if ($For -notin @("claude", "agents", "both")) { throw "Unknown -For value: $For (use claude, agents or both)" }
Write-Host "Installing for: $For"

# Use the template next to this script; if run through irm, download it.
$tmp = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "template\$For"))) {
    $Template = Join-Path $PSScriptRoot "template\$For"
} else {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("agents-md-kit-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Write-Host "Downloading template..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $archive -OutFile "$tmp\kit.zip" -UseBasicParsing
    Expand-Archive -Path "$tmp\kit.zip" -DestinationPath $tmp
    $Template = (Get-ChildItem -Path $tmp -Directory | ForEach-Object { Join-Path $_.FullName "template\$For" } |
        Where-Object { Test-Path $_ } | Select-Object -First 1)
    if (-not $Template) { throw "Download failed: template\$For not found" }
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
    $main = if ($For -eq "agents") { "AGENTS.md" } else { "CLAUDE.md" }
    Write-Host "Next: fill the [PLACEHOLDERS] in $main and docs/. Skills setup: docs/guides/setup.md"
} finally {
    if ($tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
