# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   .\install.ps1 [options] [target folder]                         (from a clone)
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For claude -Project existing
# Options (any option not given is asked; with nobody to ask, the default is used):
#   -For claude|agents|both    which agents (default: both)
#   -Project new|existing      new/empty or existing project (default: detected from the folder)
#   -Prompt yes|no             add PROMPT.md (existing: always yes; new: default no)
# Environment: NO_COLOR=1 turns colors off. AGENTS_MD_KIT_UI=plain uses typed answers instead of arrow-key menus.
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
# This file is plain ASCII on purpose (Windows PowerShell 5.1 misreads UTF-8 files without a BOM),
# so the Unicode symbols are built from code points.
param([string]$Target = (Get-Location).Path, [string]$For = "", [string]$Project = "", [string]$Prompt = "", [switch]$Help)
$ErrorActionPreference = 'Stop'

$archive = "https://github.com/iChicoRito/agents-md-kit/archive/refs/heads/main.zip"
$repo = "https://github.com/iChicoRito/agents-md-kit"

# ---------- output style ----------
# A terminal with ANSI support (Windows Terminal, Windows 10+ console) gets the full look.
# Older hosts (for example PowerShell ISE) get basic colors and ASCII symbols.
$E = [char]27
$vt = [bool]($Host.UI.psobject.Properties['SupportsVirtualTerminal'] -and $Host.UI.SupportsVirtualTerminal)
$noColor = [bool]$env:NO_COLOR
$ansi = @{ Accent = "$E[38;5;173m"; Dim = "$E[2m"; Green = "$E[32m"; Yellow = "$E[33m"; Red = "$E[31m"; Bold = "$E[1m" }
$basic = @{ Accent = 'DarkYellow'; Dim = 'DarkGray'; Green = 'Green'; Yellow = 'Yellow'; Red = 'Red'; Bold = 'White' }
if ($vt) {
    $DOT = [string][char]0x25CF; $PTR = [string][char]0x276F; $ELB = [string][char]0x2514; $STAR = [string][char]0x273B
    $SEP = [string][char]0x00B7; $UP = [string][char]0x2191; $DN = [string][char]0x2193
    $TL = [string][char]0x256D; $TR = [string][char]0x256E; $BL = [string][char]0x2570; $BR = [string][char]0x256F
    $H = [string][char]0x2500; $V = [string][char]0x2502; $TEE = [string][char]0x251C
    $SPIN = @(0x280B, 0x2819, 0x2839, 0x2838, 0x283C, 0x2834, 0x2826, 0x2827, 0x2807, 0x280F | ForEach-Object { [string][char]$_ })
} else {
    $DOT = "*"; $PTR = ">"; $ELB = "'-"; $STAR = "*"; $SEP = "-"; $UP = "up"; $DN = "down"
    $TL = "+"; $TR = "+"; $BL = "+"; $BR = "+"; $H = "-"; $V = "|"; $TEE = "|-"
    $SPIN = @("|", "/", "-", "\")
}
$state = @{ done = $false; failed = $false }   # for the "Cancelled" message on Ctrl+C
function Format-Files([int]$Count) { if ($Count -eq 1) { "1 file" } else { "$Count files" } }

function Write-Part([string]$Text, [string]$Style = "", [switch]$End) {
    if (-not $Style -or $noColor) { Write-Host $Text -NoNewline }
    elseif ($vt) { Write-Host "$($ansi[$Style])$Text$E[0m" -NoNewline }
    else { Write-Host $Text -ForegroundColor $basic[$Style] -NoNewline }
    if ($End) { Write-Host "" }
}
# One finished step, like Claude Code's tool lines: "* Label   value - note"
function Write-Done([string]$Label, [string]$Value, [string]$Note = "") {
    Write-Part "  $DOT " Green; Write-Part $Label.PadRight(10); Write-Part $Value Bold
    if ($Note) { Write-Part " $SEP $Note" Dim }
    Write-Host ""
}
function Write-Fail([string]$Message) {
    $state.failed = $true
    Write-Host ""; Write-Part "  $DOT Error: " Red; Write-Part $Message -End; Write-Host ""
}

if ($Help) {
    Write-Host ""
    Write-Part "  $STAR " Accent; Write-Part "agents-md-kit" Bold; Write-Part " installer" Dim -End
    Write-Host ""
    Write-Part "  Usage" Bold; Write-Part "  install.ps1 [options] [target folder]" -End
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
    Write-Part "  Options you leave out are asked. Target folder: current folder if not given." Dim -End
    Write-Host ""
    return
}

if ($For -and $For -notin @("claude", "agents", "both")) { Write-Fail "Unknown -For value: $For (use claude, agents or both)"; return }
if ($Project -and $Project -notin @("new", "existing")) { Write-Fail "Unknown -Project value: $Project (use new or existing)"; return }
if ($Prompt -and $Prompt -notin @("yes", "no")) { Write-Fail "Unknown -Prompt value: $Prompt (use yes or no)"; return }
if (-not (Test-Path $Target -PathType Container)) { Write-Fail "Target folder not found: $Target"; return }
$Target = (Resolve-Path $Target).Path

# Empty folder (ignoring .git) means a new project.
$detected = if (@(Get-ChildItem -LiteralPath $Target -Force | Where-Object { $_.Name -ne ".git" }).Count -eq 0) { "new" } else { "existing" }
$canAsk = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
$menus = $canAsk -and $vt -and $env:AGENTS_MD_KIT_UI -ne "plain"

# Typed fallback: returns one of $Valid, or $Default.
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

# Shows a menu of "Label|hint" options and returns the chosen number (1-based).
# With menus: arrow keys, j/k, number keys, Enter; the menu is erased after the choice.
function Select-Option([string]$Question, [int]$Default, [string[]]$Options) {
    $n = $Options.Count
    Write-Host ""; Write-Part "  $Question" Bold -End; Write-Host ""
    if (-not $menus) {
        for ($i = 0; $i -lt $n; $i++) {
            $lab, $hint = $Options[$i] -split '\|', 2
            Write-Part ("    {0}" -f ($i + 1)) Accent; Write-Part ("  {0} " -f $lab.PadRight(24)); Write-Part $hint Dim -End
        }
        Write-Host ""
        return [int](Read-Answer "Choose [1-$n, Enter = $Default]" "$Default" @(1..$n | ForEach-Object { "$_" }))
    }
    $sel = $Default
    $draw = {
        for ($i = 0; $i -lt $n; $i++) {
            $lab, $hint = $Options[$i] -split '\|', 2
            Write-Host "$E[2K" -NoNewline
            if ($i + 1 -eq $sel) { Write-Part ("  {0} {1}. {2}" -f $PTR, ($i + 1), $lab.PadRight(24)) Accent }
            else { Write-Part ("    {0}. {1}" -f ($i + 1), $lab.PadRight(24)) }
            Write-Part " $hint" Dim -End
        }
        Write-Host "$E[2K"
        Write-Host "$E[2K" -NoNewline; Write-Part "  $UP/$DN move $SEP Enter select $SEP 1-$n pick $SEP Ctrl+C quit" Dim -End
    }
    try { [Console]::CursorVisible = $false } catch {}
    try {
        & $draw
        while ($true) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq 'Enter') { break }
            if ($k.Key -eq 'UpArrow' -or $k.KeyChar -eq 'k') { if ($sel -gt 1) { $sel-- } }
            elseif ($k.Key -eq 'DownArrow' -or $k.KeyChar -eq 'j') { if ($sel -lt $n) { $sel++ } }
            elseif ($k.KeyChar -ge [char]'1' -and $k.KeyChar -le [char](48 + $n)) { $sel = [int][string]$k.KeyChar; break }
            Write-Host "$E[$($n + 2)A" -NoNewline
            & $draw
        }
    } finally { try { [Console]::CursorVisible = $true } catch {} }
    # Erase question and menu (blank, question, blank, n options, blank, hint).
    Write-Host "$E[$($n + 5)A$E[J" -NoNewline
    return $sel
}

# ---------- welcome ----------
$w = 50
$showTarget = $Target
if ($HOME -and $Target.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) { $showTarget = "~" + $Target.Substring($HOME.Length) }
Write-Host ""
Write-Part ("  $TL" + ($H * $w) + $TR) Accent -End
Write-Part "  $V " Accent; Write-Part $STAR Accent; Write-Part " "; Write-Part "Welcome to agents-md-kit" Bold; Write-Part (" " * ($w - 27)); Write-Part $V Accent -End
Write-Part "  $V" Accent; Write-Part (" " * $w); Write-Part $V Accent -End
Write-Part "  $V" Accent; Write-Part "   "; Write-Part "AI agent setup for Claude Code and Codex" Dim; Write-Part (" " * ($w - 43)); Write-Part $V Accent -End
Write-Part ("  $BL" + ($H * $w) + $BR) Accent -End
Write-Host ""
Write-Part "  Folder: $showTarget" Dim -End
if ($menus) { Write-Part "  Pick with arrow keys. Nothing is overwritten." Dim -End } else { Write-Part "  Nothing is overwritten." Dim -End }
if (-not ($canAsk -and -not $menus)) { Write-Host "" }   # typed questions bring their own blank line

# ---------- questions (only when someone can answer) ----------
if (-not $For) {
    if ($canAsk) {
        $a = Select-Option "Which AI agents will you use in this project?" 3 @(
            "Claude Code only|CLAUDE.md + .claude/",
            "Codex / other agents|AGENTS.md + .agents/",
            "Both (recommended)|CLAUDE.md + AGENTS.md + both folders")
        $For = @{ 1 = "claude"; 2 = "agents"; 3 = "both" }[$a]
    } else { $For = "both" }
}
$label = @{ claude = "Claude Code only"; agents = "Codex / other agents"; both = "Claude Code + Codex" }[$For]
Write-Done "Agents" $For $label

if (-not $Project) {
    if ($canAsk) {
        $def = if ($detected -eq "new") { 1 } else { 2 }
        $a = Select-Option "Is this a new or an existing project?" $def @(
            ("New / empty project|you fill the files as you build" + $(if ($def -eq 1) { " $SEP this folder looks empty" } else { "" })),
            ("Existing project|your AI fills them from your code" + $(if ($def -eq 2) { " $SEP this folder has files" } else { "" })))
        $Project = @{ 1 = "new"; 2 = "existing" }[$a]
    } else { $Project = $detected }
}
Write-Done "Project" $Project

$promptNote = ""
if ($Project -eq "existing") {
    if ($Prompt -eq "no") { $promptNote = "always added for existing projects" }
    $Prompt = "yes"
} elseif (-not $Prompt) {
    if ($canAsk) {
        if ($menus) {
            $a = Select-Option "Add PROMPT.md for later?" 2 @(
                "Yes|your AI fills the placeholders from your code",
                "No|copy the prompt from GitHub later")
            $Prompt = if ($a -eq 1) { "yes" } else { "no" }
        } else {
            Write-Host ""
            Write-Part "  PROMPT.md makes your AI fill the placeholders from your code. Useful after your first features exist." Dim -End
            $a = Read-Answer "Add PROMPT.md for later? [y/N]" "n" @("y", "n", "yes", "no")
            $Prompt = if ($a -in "y", "yes") { "yes" } else { "no" }
        }
    } else { $Prompt = "no" }
}
Write-Done "PROMPT.md" $Prompt $promptNote

# ---------- find or download the template ----------
$tmp = $null
try {
    Write-Host ""
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "template\$For"))) {
        $Template = Join-Path $PSScriptRoot "template\$For"
        Write-Done "Template" "local copy"
    } else {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ("agents-md-kit-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $text = "Downloading template from GitHub"
        if (-not $vt) { Write-Part "  $DOT $text..." -End }
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wc = New-Object Net.WebClient
            $task = $wc.DownloadFileTaskAsync($archive, "$tmp\kit.zip")
            if ($vt) {
                # Animated spinner while the download runs, like Claude Code's status line.
                try { [Console]::CursorVisible = $false } catch {}
                for ($i = 0; -not $task.IsCompleted; $i++) {
                    Write-Host "`r" -NoNewline; Write-Part $SPIN[$i % $SPIN.Count] Accent; Write-Part " $text "; Write-Part "($([int][Math]::Floor($i / 10))s)" Dim
                    Start-Sleep -Milliseconds 100
                }
                Write-Host "`r$E[2K" -NoNewline
                try { [Console]::CursorVisible = $true } catch {}
            } else { $task.Wait() }
            if ($task.IsFaulted) { throw $task.Exception }
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [IO.Compression.ZipFile]::ExtractToDirectory("$tmp\kit.zip", $tmp)
        } catch {
            if ($vt) { Write-Host "`r$E[2K" -NoNewline; try { [Console]::CursorVisible = $true } catch {} }
            Write-Fail "Could not download the template. Check your internet connection."; return
        }
        $Template = (Get-ChildItem -Path $tmp -Directory | ForEach-Object { Join-Path $_.FullName "template\$For" } |
            Where-Object { Test-Path $_ } | Select-Object -First 1)
        if (-not $Template) { Write-Fail "Download incomplete: template\$For not found"; return }
        Write-Done "Template" "downloaded" "latest from GitHub"
    }

    # ---------- copy ----------
    $copied = 0; $added = @(); $skipped = @(); $gitignoreAdded = $null
    Get-ChildItem -Path $Template -Recurse -Force -File | Sort-Object FullName | ForEach-Object {
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
        $copied++; $added += $rel
    }

    # ---------- result: a small tree of what changed ----------
    Write-Done "Copied" (Format-Files $copied)
    $rows = @()   # each row: list of @(text, style) parts
    $added | Group-Object { $p = $_ -split '[\\/]'; if ($p.Count -gt 1) { $p[0] + "/" } else { $p[0] } } | Sort-Object Name | ForEach-Object {
        if ($_.Name.EndsWith("/")) { $rows += , @(@("+ ", "Green"), @($_.Name.PadRight(13), ""), @((Format-Files $_.Count), "Dim")) }
        else { $rows += , @(@("+ ", "Green"), @($_.Name, "")) }
    }
    if ($null -ne $gitignoreAdded) {
        if ($gitignoreAdded.Count) { $rows += , @(@("~ ", "Green"), @(".gitignore".PadRight(13), ""), @("kept, added: $($gitignoreAdded -join ', ')", "Dim")) }
        else { $rows += , @(@("= .gitignore   kept, nothing to add", "Dim")) }
    }
    foreach ($s in $skipped) { $rows += , @(@("! ", "Yellow"), @($s.PadRight(13), ""), @("already existed, left untouched", "Yellow")) }
    for ($i = 0; $i -lt $rows.Count; $i++) {
        Write-Part ("    " + $(if ($i -eq $rows.Count - 1) { $ELB } else { $TEE }) + " ") Dim
        foreach ($part in $rows[$i]) { Write-Part $part[0] $part[1] }
        Write-Host ""
    }
    if ($skipped.Count) { Write-Part "      Files marked ! were kept as they are. Merge the kit's version by hand if you want it." Dim -End }

    # ---------- next steps ----------
    $main = if ($For -eq "agents") { "AGENTS.md" } else { "CLAUDE.md" }
    $anchor = @{ claude = "claude-code-only-claude"; agents = "codex-or-other-agents-agents"; both = "both-both" }[$For]
    $promptUrl = "$repo/blob/main/PROMPTS.md#$anchor"
    Write-Host ""
    Write-Part "  $STAR " Accent; Write-Part "Next steps" Bold -End
    Write-Host ""
    Write-Part "    1" Accent; Write-Part "  Fill the [PLACEHOLDERS] in "; Write-Part $main Bold; Write-Part " and "; Write-Part "docs/" Bold
    if ($Prompt -eq "yes" -and $skipped -contains "PROMPT.md") {
        Write-Part "." -End
        Write-Part "       Your project already had a PROMPT.md, so the kit's prompt was not added." Yellow -End
        Write-Part "       Copy the prompt from: "; Write-Part $promptUrl Accent -End
    } elseif ($Project -eq "existing") {
        Write-Part ". Tell your AI:" -End
        Write-Part "       $PTR " Accent; Write-Part "Read PROMPT.md and do what it says." Bold -End
    } elseif ($Prompt -eq "yes") {
        Write-Part " as you build." -End
        Write-Part "       After your first features exist, tell your AI:" -End
        Write-Part "       $PTR " Accent; Write-Part "Read PROMPT.md and do what it says." Bold -End
    } else {
        Write-Part " as you build." -End
        Write-Part "       Later, to let your AI fill them from your code: $promptUrl" Dim -End
    }
    Write-Part "    2" Accent; Write-Part "  Install the skills: "; Write-Part "docs/guides/setup.md" Bold -End
    if ($For -eq "agents") {
        Write-Part "    3" Accent; Write-Part "  Start your agent and ask it to read "; Write-Part "AGENTS.md" Bold -End
    } else {
        Write-Part "    3" Accent; Write-Part "  In Claude Code, run "; Write-Part "/memory" Bold; Write-Part " and "; Write-Part "/skills" Bold; Write-Part " to check what loads" -End
    }
    Write-Host ""
    Write-Part "  $DOT " Green; Write-Part "Done." Bold; Write-Part " Guide: $repo/blob/main/GUIDE.md" Dim -End
    Write-Host ""
    $state.done = $true
} finally {
    if (-not $state.done -and -not $state.failed) {
        try { [Console]::CursorVisible = $true } catch {}
        Write-Host ""; Write-Host ""; Write-Part "  $DOT Cancelled. Files already copied stay; run again to finish." Yellow -End; Write-Host ""
    }
    if ($tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
