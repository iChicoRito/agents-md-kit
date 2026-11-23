# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   .\install.ps1 [-For claude|agents|both] [target folder]          (from a clone)
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For claude
# -For claude: Claude Code only (CLAUDE.md, .claude/)
# -For agents: Codex and other agents only (AGENTS.md, .agents/)
# -For both:   both (default when no choice is given and nobody can be asked)
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
param([string]$Target = (Get-Location).Path, [string]$For = "", [switch]$Help)
$ErrorActionPreference = 'Stop'

$archive = "https://github.com/iChicoRito/agents-md-kit/archive/refs/heads/main.zip"

# ---------- output style ----------
function Write-Part([string]$Text, [string]$Color = "", [switch]$End) {
    if ($Color) { Write-Host $Text -ForegroundColor $Color -NoNewline } else { Write-Host $Text -NoNewline }
    if ($End) { Write-Host "" }
}
function Write-Step([string]$Label, [string]$Value, [string]$Note = "") {
    Write-Part "  > " Cyan; Write-Part $Label; Write-Part $Value White
    if ($Note) { Write-Part " ($Note)" DarkGray }
    Write-Host ""
}
function Write-Fail([string]$Message) {
    Write-Host ""; Write-Part "  Error: " Red; Write-Part $Message -End; Write-Host ""
}

if ($Help) {
    Write-Host ""
    Write-Part "  agents-md-kit" White; Write-Part " installer" -End
    Write-Host ""
    Write-Host "  Usage: install.ps1 [-For claude|agents|both] [target folder]"
    Write-Host ""
    Write-Host "    -For claude   Claude Code only        CLAUDE.md + .claude/"
    Write-Host "    -For agents   Codex / other agents    AGENTS.md + .agents/"
    Write-Host "    -For both     Claude Code and Codex   all of the above (default)"
    Write-Host ""
    Write-Host "  No -For: you are asked. Target folder: current folder if not given."
    Write-Host ""
    return
}

if (-not (Test-Path $Target -PathType Container)) { Write-Fail "Target folder not found: $Target"; return }
$Target = (Resolve-Path $Target).Path

# ---------- header ----------
Write-Host ""
Write-Part "  agents-md-kit" White; Write-Part "  AI agent setup for your project" DarkGray -End
Write-Part "  --------------------------------------------------" DarkGray -End

# ---------- choose version ----------
if (-not $For) {
    $canAsk = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
    if ($canAsk) {
        Write-Host ""
        Write-Part "  Which AI agents will you use in this project?" White -End
        Write-Host ""
        Write-Part "    1" Cyan; Write-Part "  Claude Code only         "; Write-Part "CLAUDE.md + .claude/" DarkGray -End
        Write-Part "    2" Cyan; Write-Part "  Codex / other agents     "; Write-Part "AGENTS.md + .agents/" DarkGray -End
        Write-Part "    3" Cyan; Write-Part "  Both "; Write-Part "(recommended)" Green; Write-Part "       "; Write-Part "CLAUDE.md + AGENTS.md + both folders" DarkGray -End
        Write-Host ""
        $tries = 0
        while (-not $For) {
            try { $answer = Read-Host "  Choose [1-3, Enter = 3]" } catch { $answer = ""; $tries = 3 }
            switch ("$answer".Trim()) {
                "1" { $For = "claude" }
                "2" { $For = "agents" }
                { $_ -in "3", "" } { $For = "both" }
                default {
                    $tries++
                    if ($tries -ge 3) { $For = "both"; Write-Part "  No valid choice, using: both" Yellow -End }
                    else { Write-Part "  Please type 1, 2 or 3." Yellow -End }
                }
            }
        }
    } else {
        $For = "both"
    }
}
if ($For -notin @("claude", "agents", "both")) { Write-Fail "Unknown -For value: $For (use claude, agents or both)"; return }

$label = @{ claude = "Claude Code only"; agents = "Codex / other agents"; both = "Claude Code + Codex" }[$For]
Write-Host ""
Write-Step "Version:  " $For $label
Write-Step "Target:   " $Target

# ---------- find or download the template ----------
$tmp = $null
try {
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "template\$For"))) {
        $Template = Join-Path $PSScriptRoot "template\$For"
    } else {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ("agents-md-kit-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        Write-Part "  > " Cyan; Write-Part "Download: "
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $archive -OutFile "$tmp\kit.zip" -UseBasicParsing
            Expand-Archive -Path "$tmp\kit.zip" -DestinationPath $tmp
        } catch {
            Write-Part "failed" Red -End
            Write-Fail "Could not download the template. Check your internet connection."; return
        }
        $Template = (Get-ChildItem -Path $tmp -Directory | ForEach-Object { Join-Path $_.FullName "template\$For" } |
            Where-Object { Test-Path $_ } | Select-Object -First 1)
        if (-not $Template) { Write-Part "failed" Red -End; Write-Fail "Download incomplete: template\$For not found"; return }
        Write-Part "done" Green -End
    }

    # ---------- copy ----------
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

    # ---------- summary ----------
    Write-Host ""
    Write-Part "  Result" White -End
    Write-Part "    + " Green; Write-Part "$copied file(s) added" -End
    if ($null -ne $gitignoreAdded) {
        if ($gitignoreAdded.Count) {
            Write-Part "    ~ " Green; Write-Part ".gitignore kept, $($gitignoreAdded.Count) line(s) added: $($gitignoreAdded -join ', ')" -End
        } else {
            Write-Part "    = " DarkGray; Write-Part ".gitignore kept, nothing to add" -End
        }
    }
    if ($skipped.Count) {
        Write-Part "    ! " Yellow; Write-Part "$($skipped.Count) file(s) already existed, left untouched. Merge by hand:" -End
        $skipped | ForEach-Object { Write-Part "        $_" DarkGray -End }
    }

    $main = if ($For -eq "agents") { "AGENTS.md" } else { "CLAUDE.md" }
    Write-Host ""
    Write-Part "  Next steps" White -End
    $anchor = @{ claude = "claude-code-only-claude"; agents = "codex-or-other-agents-agents"; both = "both-both" }[$For]
    Write-Part "    1. Fill the [PLACEHOLDERS] in "; Write-Part $main White; Write-Part " and "; Write-Part "docs/" White; Write-Part ". Copy this prompt for your AI:" -End
    Write-Part "       https://github.com/iChicoRito/agents-md-kit/blob/main/PROMPTS.md#$anchor" Cyan -End
    Write-Part "    2. Install the skills: "; Write-Part "docs/guides/setup.md" White -End
    if ($For -eq "agents") {
        Write-Part "    3. Start your agent and ask it to read "; Write-Part "AGENTS.md" White -End
    } else {
        Write-Part "    3. In Claude Code, run "; Write-Part "/memory" White; Write-Part " and "; Write-Part "/skills" White; Write-Part " to check what loads" -End
    }
    Write-Host ""
    Write-Part "  Done." Green; Write-Part " Guide: https://github.com/iChicoRito/agents-md-kit/blob/main/GUIDE.md" DarkGray -End
    Write-Host ""
} finally {
    if ($tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
