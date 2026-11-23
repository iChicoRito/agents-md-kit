# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   .\install.ps1 [options] [target folder]                         (from a clone)
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For claude -Project existing
# Options (any option not given is asked; with nobody to ask, the default is used):
#   -For claude|agents|both    which agents (default: both)
#   -Project new|existing      new/empty or existing project (default: detected from the folder)
#   -Prompt yes|no             add PROMPT.md (existing: always yes; new: default no)
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
param([string]$Target = (Get-Location).Path, [string]$For = "", [string]$Project = "", [string]$Prompt = "", [switch]$Help)
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
    Write-Host "  Usage: install.ps1 [options] [target folder]"
    Write-Host ""
    Write-Host "    -For claude          Claude Code only        CLAUDE.md + .claude/"
    Write-Host "    -For agents          Codex / other agents    AGENTS.md + .agents/"
    Write-Host "    -For both            Claude Code and Codex   all of the above (default)"
    Write-Host ""
    Write-Host "    -Project new         new or empty project (fill the files as you build)"
    Write-Host "    -Project existing    project that already has code"
    Write-Host ""
    Write-Host "    -Prompt yes|no       add PROMPT.md, the prompt that makes your AI fill"
    Write-Host "                         the placeholders (existing: always added; new: default no)"
    Write-Host ""
    Write-Host "  Options you leave out are asked. Target folder: current folder if not given."
    Write-Host ""
    return
}

if (-not (Test-Path $Target -PathType Container)) { Write-Fail "Target folder not found: $Target"; return }
$Target = (Resolve-Path $Target).Path

# ---------- header ----------
Write-Host ""
Write-Part "  agents-md-kit" White; Write-Part "  AI agent setup for your project" DarkGray -End
Write-Part "  --------------------------------------------------" DarkGray -End

# ---------- questions (only when someone can answer) ----------
if ($For -and $For -notin @("claude", "agents", "both")) { Write-Fail "Unknown -For value: $For (use claude, agents or both)"; return }
if ($Project -and $Project -notin @("new", "existing")) { Write-Fail "Unknown -Project value: $Project (use new or existing)"; return }
if ($Prompt -and $Prompt -notin @("yes", "no")) { Write-Fail "Unknown -Prompt value: $Prompt (use yes or no)"; return }

# Empty folder (ignoring .git) means a new project.
$detected = if (@(Get-ChildItem -LiteralPath $Target -Force | Where-Object { $_.Name -ne ".git" }).Count -eq 0) { "new" } else { "existing" }
$canAsk = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected

function Read-Answer([string]$Text, [string]$Default, [string[]]$Valid) {
    $tries = 0
    while ($true) {
        try { $a = Read-Host "  $Text" } catch { return $Default }
        $a = "$a".Trim().ToLower()
        if (-not $a) { return $Default }
        if ($Valid -contains $a) { return $a }
        $tries++
        if ($tries -ge 3) { Write-Part "  No valid answer, using the default." Yellow -End; return $Default }
        Write-Part "  Please type one of: $($Valid -join ' ')" Yellow -End
    }
}

if (-not $For) {
    if ($canAsk) {
        Write-Host ""
        Write-Part "  Which AI agents will you use in this project?" White -End
        Write-Host ""
        Write-Part "    1" Cyan; Write-Part "  Claude Code only         "; Write-Part "CLAUDE.md + .claude/" DarkGray -End
        Write-Part "    2" Cyan; Write-Part "  Codex / other agents     "; Write-Part "AGENTS.md + .agents/" DarkGray -End
        Write-Part "    3" Cyan; Write-Part "  Both "; Write-Part "(recommended)" Green; Write-Part "       "; Write-Part "CLAUDE.md + AGENTS.md + both folders" DarkGray -End
        Write-Host ""
        $For = @{ "1" = "claude"; "2" = "agents"; "3" = "both" }[(Read-Answer "Choose [1-3, Enter = 3]" "3" @("1", "2", "3"))]
    } else { $For = "both" }
}

if (-not $Project) {
    if ($canAsk) {
        if ($detected -eq "new") { $def = "1"; $note = "this folder looks empty" } else { $def = "2"; $note = "this folder already has files" }
        Write-Host ""
        Write-Part "  Is this a new or an existing project?" White -End
        Write-Host ""
        Write-Part "    1" Cyan; Write-Part "  New / empty project      "; Write-Part "you fill the files as you build" DarkGray -End
        Write-Part "    2" Cyan; Write-Part "  Existing project         "; Write-Part "adds PROMPT.md so your AI fills them from your code" DarkGray -End
        Write-Host ""
        $Project = @{ "1" = "new"; "2" = "existing" }[(Read-Answer "Choose [1-2, Enter = $def, $note]" $def @("1", "2"))]
    } else { $Project = $detected }
}

if ($Project -eq "existing") {
    if ($Prompt -eq "no") { Write-Part "  Existing project: PROMPT.md is always added." Yellow -End }
    $Prompt = "yes"
} elseif (-not $Prompt) {
    if ($canAsk) {
        Write-Host ""
        Write-Part "  PROMPT.md makes your AI fill the placeholders from your code. Useful after your first features exist." DarkGray -End
        $a = Read-Answer "Add PROMPT.md for later? [y/N]" "n" @("y", "n", "yes", "no")
        $Prompt = if ($a -in "y", "yes") { "yes" } else { "no" }
    } else { $Prompt = "no" }
}

$label = @{ claude = "Claude Code only"; agents = "Codex / other agents"; both = "Claude Code + Codex" }[$For]
Write-Host ""
Write-Step "Version:  " $For $label
Write-Step "Project:  " $Project
Write-Step "Prompt:   " $Prompt "PROMPT.md"
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
        if ($rel -eq 'PROMPT.md' -and $Prompt -eq 'no') { return }
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
    $promptUrl = "https://github.com/iChicoRito/agents-md-kit/blob/main/PROMPTS.md#$anchor"
    if ($Prompt -eq "yes" -and $skipped -contains "PROMPT.md") {
        Write-Part "    1. Fill the [PLACEHOLDERS] in "; Write-Part $main White; Write-Part " and "; Write-Part "docs/" White; Write-Part "." -End
        Write-Part "       Your project already had a PROMPT.md, so the kit's prompt was not added." Yellow -End
        Write-Part "       Copy the prompt from: "; Write-Part $promptUrl Cyan -End
    } elseif ($Project -eq "existing") {
        Write-Part "    1. Fill the [PLACEHOLDERS] in "; Write-Part $main White; Write-Part " and "; Write-Part "docs/" White; Write-Part ". Tell your AI:" -End
        Write-Part "       Read PROMPT.md and do what it says." Cyan -End
        Write-Part "       (or copy the prompt from PROMPT.md. Online: $promptUrl)" DarkGray -End
    } elseif ($Prompt -eq "yes") {
        Write-Part "    1. Fill the [PLACEHOLDERS] in "; Write-Part $main White; Write-Part " and "; Write-Part "docs/" White; Write-Part " as you build." -End
        Write-Part "       After your first features exist, tell your AI: "; Write-Part "Read PROMPT.md and do what it says." Cyan -End
    } else {
        Write-Part "    1. Fill the [PLACEHOLDERS] in "; Write-Part $main White; Write-Part " and "; Write-Part "docs/" White; Write-Part " as you build." -End
        Write-Part "       Later, to let your AI fill them from your code, copy the prompt: $promptUrl" DarkGray -End
    }
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
