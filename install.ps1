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
#   -Update                    project already has the kit: add missing files, and save the
#                              newer kit version of changed files as <file>.kit-new
param([string]$Target = (Get-Location).Path, [string]$For = "", [string]$Project = "", [string]$Prompt = "", [switch]$Update, [string]$Version = "", [switch]$DryRun, [switch]$AddCommand, [string]$ProfilePath = $PROFILE, [switch]$Check, [switch]$GraphView, [string]$Graphify = "", [string]$Skills = "", [switch]$Help)
$ErrorActionPreference = 'Stop'

$kitVersion = "1.6.0"   # keep equal to the VERSION file (the tests check this)
$repo = "https://github.com/iChicoRito/agents-md-kit"
$archive = "$repo/archive/refs/heads/main.zip"

# ---------- output style ----------
# A terminal with ANSI support (Windows Terminal, Windows 10+ console) gets the full look.
# Older hosts (for example PowerShell ISE) get basic colors and ASCII symbols.
$E = [char]27
# Output sent to a file or pipe gets plain text, like the Bash installer.
$vt = [bool]($Host.UI.psobject.Properties['SupportsVirtualTerminal'] -and $Host.UI.SupportsVirtualTerminal) -and -not [Console]::IsOutputRedirected
$noColor = [bool]$env:NO_COLOR
$ansi = @{ Accent = "$E[38;5;173m"; Dim = "$E[2m"; Green = "$E[32m"; Yellow = "$E[33m"; Red = "$E[31m"; Bold = "$E[1m" }
$basic = @{ Accent = 'DarkYellow'; Dim = 'DarkGray'; Green = 'Green'; Yellow = 'Yellow'; Red = 'Red'; Bold = 'White' }
if ($vt) {
    $DOT = [string][char]0x25CF; $PTR = [string][char]0x276F; $ELB = [string][char]0x2514; $STAR = [string][char]0x273B
    $SEP = [string][char]0x00B7; $UP = [string][char]0x2191; $DN = [string][char]0x2193
    $TL = [string][char]0x256D; $TR = [string][char]0x256E; $BL = [string][char]0x2570; $BR = [string][char]0x256F
    $H = [string][char]0x2500; $V = [string][char]0x2502; $TEE = [string][char]0x251C; $FULL = [string][char]0x2588; $EMPTY = [string][char]0x2591
    $SPIN = @(0x280B, 0x2819, 0x2839, 0x2838, 0x283C, 0x2834, 0x2826, 0x2827, 0x2807, 0x280F | ForEach-Object { [string][char]$_ })
} else {
    $DOT = "*"; $PTR = ">"; $ELB = "'-"; $STAR = "*"; $SEP = "-"; $UP = "up"; $DN = "down"
    $TL = "+"; $TR = "+"; $BL = "+"; $BR = "+"; $H = "-"; $V = "|"; $TEE = "|-"; $FULL = "#"; $EMPTY = "-"
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
    Write-Part "  $DOT " Green; Write-Part $Label.PadRight(11); Write-Part $Value Bold
    if ($Note) { Write-Part " $SEP $Note" Dim }
    Write-Host ""
}
# Writes the bar and percent for a progress given in thousandths of a step, out of Total steps.
function Write-Bar([int]$Thousandths, [int]$Total) {
    $w = 28; $t = [Math]::Max($Total, 1)
    $fill = [int][Math]::Floor($Thousandths * $w / ($t * 1000)); $pct = [int][Math]::Floor($Thousandths * 100 / ($t * 1000))
    Write-Part ($FULL * $fill) Accent; Write-Part ($EMPTY * ($w - $fill)) Dim
    Write-Part (" {0,3}%  " -f $pct)
}
# One redrawn line: "Installing [bar] 52%  13/25". Nothing without ANSI support.
# The short pause per file only makes the bar visible; the copy itself takes a blink.
function Write-Progress-Bar([int]$Done, [int]$Total) {
    if (-not $vt) { return }
    Write-Host "`r" -NoNewline; Write-Part $SPIN[$Done % $SPIN.Count] Accent; Write-Part " Installing  "
    Write-Bar ($Done * 1000) $Total; Write-Part "$Done/$Total" Dim
    Start-Sleep -Milliseconds 15
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
    Write-Host "    -Update              the project already has the kit: add missing files, and"
    Write-Host "                         save the newer kit version of changed files as <file>.kit-new"
    Write-Host ""
    Write-Host "    -Version 1.0.0       install that released version instead of the latest"
    Write-Host "                         (list: $repo/releases)"
    Write-Host ""
    Write-Host "    -DryRun              show what would be added, merged or skipped; change nothing"
    Write-Host ""
    Write-Host "    -AddCommand          add the short command ""agents-md-kit"" to your PowerShell"
    Write-Host "                         profile (`$PROFILE), then stop"
    Write-Host ""
    Write-Host "    -Check               list the [PLACEHOLDERS] still left in CLAUDE.md, AGENTS.md"
    Write-Host "                         and docs/, then stop"
    Write-Host ""
    Write-Host "    -GraphView           build the graph view (graphify-out/graph.html, an interactive map of"
    Write-Host "                         your code, like Obsidian's graph) from graphify-out/graph.json, then stop"
    Write-Host ""
    Write-Host "    -Graphify yes|no     graphify, the code knowledge graph: yes = install it if missing"
    Write-Host "                         and build the graph without asking, no = skip it (default: ask)"
    Write-Host ""
    Write-Host "    -Skills yes|no       primary skills (Superpowers, Ponytail, Caveman, official repos):"
    Write-Host "                         yes = install them, or update those already installed, without"
    Write-Host "                         asking; no = skip (default: ask)"
    Write-Host ""
    Write-Part "  Options you leave out are asked. Target folder: current folder if not given." Dim -End
    Write-Host ""
    return
}

# ---------- -AddCommand: put the short command in the PowerShell profile, then stop ----------
if ($AddCommand) {
    $line = 'function agents-md-kit { & ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) @args }'
    Write-Host ""
    $hasIt = (Test-Path $ProfilePath) -and (Select-String -LiteralPath $ProfilePath -Pattern '^function agents-md-kit ' -Quiet)
    if ($hasIt) {
        Write-Done "Command" "agents-md-kit" "already in $ProfilePath"
    } else {
        if (-not $DryRun) {
            $dir = Split-Path $ProfilePath
            if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
            Add-Content -LiteralPath $ProfilePath -Value @("", "# agents-md-kit installer (added by -AddCommand)", $line) -Encoding UTF8
        }
        Write-Done "Command" "agents-md-kit" "$(if ($DryRun) { 'would be added to' } else { 'added to' }) $ProfilePath"
    }
    Write-Part "    Open a new PowerShell window, then type " Dim; Write-Part "agents-md-kit" Bold; Write-Part " in any project folder." Dim -End
    Write-Host ""
    return
}

if ($For -and $For -notin @("claude", "agents", "both")) { Write-Fail "Unknown -For value: $For (use claude, agents or both)"; return }
if ($Project -and $Project -notin @("new", "existing")) { Write-Fail "Unknown -Project value: $Project (use new or existing)"; return }
if ($Prompt -and $Prompt -notin @("yes", "no")) { Write-Fail "Unknown -Prompt value: $Prompt (use yes or no)"; return }
if ($Graphify -and $Graphify -notin @("yes", "no")) { Write-Fail "Unknown -Graphify value: $Graphify (use yes or no)"; return }
if ($Skills -and $Skills -notin @("yes", "no")) { Write-Fail "Unknown -Skills value: $Skills (use yes or no)"; return }
# A pinned version downloads that release; "1.0.0" and "v1.0.0" both work.
$Version = $Version -replace '^v', ''
if ($Version) {
    if ($Version -notmatch '^\d+(\.\d+)*$') { Write-Fail "Unknown -Version value: $Version (use a release number like 1.0.0)"; return }
    $archive = "$repo/archive/refs/tags/v$Version.zip"
}
$showVersion = if ($Version) { $Version } else { $kitVersion }
if (-not (Test-Path $Target -PathType Container)) { Write-Fail "Target folder not found: $Target"; return }
$Target = (Resolve-Path $Target).Path

# ---------- the kit's own files: this checkout, or a download of main / the pinned release ----------
$script:tmp = $null; $script:kitRoot = $null; $script:kitSrc = ""
function Get-KitRoot {
    if ($script:kitRoot) { return $true }
    if (-not $Version -and $PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "template"))) {
        $script:kitRoot = $PSScriptRoot; $script:kitSrc = "local"; return $true
    }
    $script:tmp = Join-Path ([IO.Path]::GetTempPath()) ("agents-md-kit-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $script:tmp | Out-Null
    $text = "Downloading template from GitHub"
    if (-not $vt) { Write-Part "  $DOT $text..." -End }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient
        $task = $wc.DownloadFileTaskAsync($archive, "$($script:tmp)\kit.zip")
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
        [IO.Compression.ZipFile]::ExtractToDirectory("$($script:tmp)\kit.zip", $script:tmp)
    } catch {
        if ($vt) { Write-Host "`r$E[2K" -NoNewline; try { [Console]::CursorVisible = $true } catch {} }
        if ($Version) { Write-Fail "Version $Version not found. See $repo/releases"; return $false }
        Write-Fail "Could not download the template. Check your internet connection."; return $false
    }
    $root = Get-ChildItem -Path $script:tmp -Directory | Select-Object -First 1
    if (-not $root -or -not (Test-Path (Join-Path $root.FullName "template"))) { Write-Fail "Download incomplete: template not found"; return $false }
    $script:kitRoot = $root.FullName; $script:kitSrc = "downloaded"
    return $true
}

# Returns a Python 3.8+ command, or $null. Graphify needs Python, so it is nearly always there.
function Find-Python {
    $ErrorActionPreference = "Continue"
    $cands = @()
    $gp = Join-Path $Target "graphify-out\.graphify_python"
    if (Test-Path $gp) { $cands += (Get-Content -LiteralPath $gp -Raw).Trim() }
    $cands += if ($env:OS -eq "Windows_NT") { "python", "py", "python3" } else { "python3", "python" }
    foreach ($c in $cands) {
        if (-not $c) { continue }
        if (-not (Get-Command $c -ErrorAction SilentlyContinue) -and -not (Test-Path -LiteralPath $c)) { continue }
        try { & $c -c "import sys; sys.exit(sys.version_info < (3, 8))" 2>$null | Out-Null } catch { continue }
        if ($LASTEXITCODE -eq 0) { return $c }
    }
    return $null
}

# Writes graphify-out/graph.html (Obsidian-style) from graphify-out/graph.json. Returns "<n> nodes", or $null on failure.
function New-GraphView {
    $ErrorActionPreference = "Continue"
    $py = Find-Python
    if (-not $py) { return $null }
    if (-not (Get-KitRoot)) { return $null }
    $gen = Join-Path $script:kitRoot "tools\graph-view\graph_view.py"
    $out = & $py $gen (Join-Path $Target "graphify-out\graph.json") -o (Join-Path $Target "graphify-out\graph.html") 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { return $null }
    if ($out -match '\((\d+) nodes') { return "$($Matches[1]) nodes" }
    return ""
}

# ---------- -GraphView: build the graph view, then stop ----------
if ($GraphView) {
    try {
        Write-Host ""
        if (-not (Test-Path (Join-Path $Target "graphify-out\graph.json"))) { Write-Fail "No graph found in $Target\graphify-out. Build one first: graphify update ."; return }
        if (-not (Find-Python)) { Write-Fail "Python 3.8 or newer is needed to build the graph view."; return }
        if ($DryRun) { Write-Done "Graph view" "would be built" "graphify-out/graph.html"; Write-Host ""; return }
        $nodes = New-GraphView
        if ($null -eq $nodes) { Write-Fail "Could not build the graph view."; return }
        Write-Done "Graph view" "built" "$(if ($nodes) { "$nodes $SEP " })graphify-out/graph.html"
        Write-Part "    $ELB open graphify-out/graph.html in your browser. Run this again after graphify updates the graph." Dim -End
        Write-Host ""
    } finally { if ($script:tmp) { Remove-Item -Recurse -Force $script:tmp -ErrorAction SilentlyContinue } }
    return
}

# ---------- -Check: list placeholders still left in the kit files, then stop ----------
# A placeholder is an uppercase word in brackets, like [PROJECT DESCRIPTION].
# Markdown links ([API](...)) are not placeholders. PROMPT.md and the ADR template
# (docs/architecture/decisions/0000-template.md) are meant to keep theirs, so they are skipped.
if ($Check) {
    $scan = @()
    foreach ($f in "CLAUDE.md", "AGENTS.md") { if (Test-Path (Join-Path $Target $f) -PathType Leaf) { $scan += $f } }
    $docs = Join-Path $Target "docs"
    if (Test-Path $docs -PathType Container) {
        $scan += @(Get-ChildItem -LiteralPath $docs -Recurse -File -Include *.md, *.yaml, *.yml | Sort-Object FullName |
            ForEach-Object { $_.FullName.Substring($Target.Length).TrimStart('\', '/') -replace '\\', '/' } |
            Where-Object { $_ -ne "docs/architecture/decisions/0000-template.md" })
    }
    if (-not $scan.Count) { Write-Fail "No CLAUDE.md, AGENTS.md or docs/ in $Target. Install the kit first."; return }
    $pattern = [regex]'\[[A-Z][A-Z0-9 _,./:-]+\](?!\()'   # case-sensitive by default
    $total = 0; $rows = @()
    foreach ($rel in $scan) {
        $found = @($pattern.Matches([IO.File]::ReadAllText((Join-Path $Target $rel))) | ForEach-Object { $_.Value })
        if (-not $found.Count) { continue }
        $list = ($found | Select-Object -Unique) -join ", "
        if ($list.Length -gt 60) { $list = $list.Substring(0, 57) + "..." }
        $total += $found.Count
        $rows += , @($rel, $found.Count, $list)
    }
    Write-Host ""
    if (-not $total) {
        Write-Done "Check" "no placeholders left" "$(Format-Files $scan.Count) checked"
        Write-Host ""
        return
    }
    Write-Done "Check" "$total placeholders left" "in $(Format-Files $rows.Count)"
    for ($i = 0; $i -lt $rows.Count; $i++) {
        Write-Part ("    " + $(if ($i -eq $rows.Count - 1) { $ELB } else { $TEE }) + " ") Dim
        Write-Part ("{0,-34} {1,3}  " -f $rows[$i][0], $rows[$i][1]); Write-Part $rows[$i][2] Dim -End
    }
    Write-Host ""
    Write-Part "  Fill them in, or tell your AI: " Dim; Write-Part "Read PROMPT.md and do what it says." Bold -End
    Write-Host ""
    return
}

# Empty folder (ignoring .git) means a new project.
$detected = if (@(Get-ChildItem -LiteralPath $Target -Force | Where-Object { $_.Name -ne ".git" }).Count -eq 0) { "new" } else { "existing" }
# Update mode: guess the installed version from the folders, and keep PROMPT.md as it was.
$hasClaude = Test-Path (Join-Path $Target ".claude"); $hasAgents = Test-Path (Join-Path $Target ".agents")
$installed = if ($hasClaude -and -not $hasAgents) { 1 } elseif ($hasAgents -and -not $hasClaude) { 2 } else { 3 }
if ($Update) {
    $Project = "existing"
    if (-not $Prompt) { $Prompt = if (Test-Path (Join-Path $Target "PROMPT.md")) { "yes" } else { "no" } }
}
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
Write-Part "  $V " Accent; Write-Part $STAR Accent; Write-Part " "; Write-Part "Welcome to agents-md-kit" Bold; Write-Part " v$showVersion" Dim
Write-Part (" " * ($w - 28 - "v$showVersion".Length)); Write-Part $V Accent -End
Write-Part "  $V" Accent; Write-Part (" " * $w); Write-Part $V Accent -End
Write-Part "  $V" Accent; Write-Part "   "; Write-Part "AI agent setup for Claude Code and Codex" Dim; Write-Part (" " * ($w - 43)); Write-Part $V Accent -End
Write-Part ("  $BL" + ($H * $w) + $BR) Accent -End
Write-Host ""
Write-Part "  Folder: $showTarget" Dim -End
if ($Update) { Write-Part "  Update mode: " Accent; Write-Part "missing files are added; newer kit files are saved as *.kit-new" Dim -End }
if ($DryRun) { Write-Part "  Dry run: " Accent; Write-Part "nothing will be changed, you only see what would happen" Dim -End }
if ($menus) { Write-Part "  Pick with arrow keys. Nothing is overwritten." Dim -End } else { Write-Part "  Nothing is overwritten." Dim -End }
if (-not ($canAsk -and -not $menus)) { Write-Host "" }   # typed questions bring their own blank line

# ---------- questions (only when someone can answer) ----------
if (-not $For) {
    if ($canAsk) {
        $def = if ($Update) { $installed } else { 3 }
        $a = Select-Option "Which AI agents will you use in this project?" $def @(
            "Claude Code only|CLAUDE.md + .claude/",
            "Codex / other agents|AGENTS.md + .agents/",
            "Both (recommended)|CLAUDE.md + AGENTS.md + both folders")
        $For = @{ 1 = "claude"; 2 = "agents"; 3 = "both" }[$a]
    } elseif ($Update) { $For = @{ 1 = "claude"; 2 = "agents"; 3 = "both" }[$installed] }
    else { $For = "both" }
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
if ($Update) {
    $promptNote = "kept as it was"
} elseif ($Project -eq "existing") {
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

# ---------- graphify (optional): asks first, never installs or builds without a yes ----------
# Runs a command in the project folder with a spinner. Returns Ok and the last output.
# While $script:barTotal is set (steps in the current group, $script:barDone finished) it also shows the
# progress bar. The running step creeps toward its end but never reaches it: we cannot know how long it takes.
$script:barDone = 0; $script:barTotal = 0
function Invoke-Spinner([string]$Text, [string]$Exe, [string[]]$CmdArgs, [string]$Dir) {
    $job = Start-Job -ArgumentList $Exe, $CmdArgs, $Dir -ScriptBlock {
        param($exe, $cmdArgs, $dir)
        Set-Location -LiteralPath $dir
        $out = & $exe @cmdArgs 2>&1 | Out-String
        [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out }
    }
    if ($vt) {
        try { [Console]::CursorVisible = $false } catch {}
        for ($i = 0; $job.State -eq 'Running'; $i++) {
            Write-Host "`r$E[2K" -NoNewline; Write-Part $SPIN[$i % $SPIN.Count] Accent; Write-Part " $Text "
            if ($script:barTotal -gt 0) { Write-Bar ($script:barDone * 1000 + 1000 - [int](100000 / (100 + $i))) $script:barTotal; Write-Part "$($script:barDone)/$($script:barTotal)  " Dim }
            Write-Part "($([int][Math]::Floor($i / 10))s)" Dim
            Start-Sleep -Milliseconds 100
        }
        Write-Host "`r$E[2K" -NoNewline
        try { [Console]::CursorVisible = $true } catch {}
    } else { Write-Part "  $DOT $Text..." -End }
    $res = @(Receive-Job $job -Wait) | Select-Object -Last 1
    Remove-Job $job -Force
    if ($script:barTotal -gt 0) { $script:barDone++ }
    [pscustomobject]@{ Ok = [bool]($res -and $res.Code -eq 0); Out = "$($res.Out)" }
}

# Yes/No question, default No. Returns $true for yes.
function Read-YesNo([string]$Question, [string]$YesHint, [string]$NoHint) {
    if ($menus) { return ((Select-Option $Question 2 @("Yes|$YesHint", "No|$NoHint")) -eq 1) }
    Write-Host ""; Write-Part "  $YesHint" Dim -End
    return ((Read-Answer "$Question [y/N]" "n" @("y", "n", "yes", "no")) -in "y", "yes")
}

function Test-Graphify { [bool](Get-Command graphify -ErrorAction SilentlyContinue) }

# Returns "handled" (done or declined), "skipped" (not possible) or "" (nobody was asked).
function Invoke-GraphifyStep {
    if (Test-Path (Join-Path $Target "graphify-out\graph.json")) {
        Write-Done "Graphify" "graph found" "the AI will query graphify-out/ first"; return "handled"
    }
    if (-not $Graphify -and -not $canAsk) { return "" }   # nobody to ask: the next steps mention it
    if ($Graphify -eq "no") { Write-Done "Graphify" "skipped" "build a graph later: graphify update ."; return "handled" }
    if (-not (Test-Graphify)) {
        $inst = $null
        if (Get-Command uv -ErrorAction SilentlyContinue) { $inst = @("uv", "tool", "install", "graphifyy") }
        elseif (Get-Command pipx -ErrorAction SilentlyContinue) { $inst = @("pipx", "install", "graphifyy") }
        else {
            foreach ($py in "python", "python3", "py") {
                if (Get-Command $py -ErrorAction SilentlyContinue) { $inst = @($py, "-m", "pip", "install", "--user", "graphifyy"); break }
            }
        }
        if (-not $inst) { Write-Done "Graphify" "not installed" "needs uv, pipx or Python. See docs/guides/setup.md"; return "skipped" }
        $yes = ($Graphify -eq "yes")
        if (-not $Graphify) {
            $yes = Read-YesNo "graphify is not installed. Install the official graphify?" "runs: $($inst -join ' ')" "you can install it later: see docs/guides/setup.md"
        }
        if (-not $yes) { Write-Done "Graphify" "not installed" "skipped, see docs/guides/setup.md"; return "handled" }
        $script:barDone = 0; $script:barTotal = 2   # install, then build (build may still be declined)
        $r = Invoke-Spinner "Installing graphify" $inst[0] $inst[1..($inst.Count - 1)] $Target
        if (-not $r.Ok) {
            $script:barTotal = 0
            Write-Done "Graphify" "install failed" "see docs/guides/setup.md"
            $r.Out -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 3 | ForEach-Object { Write-Part "        $_" Dim -End }
            return "skipped"
        }
        # a new tool may sit in a folder this terminal does not know yet
        if (-not (Test-Graphify)) {
            $dirs = @("$HOME\.local\bin")
            if (Get-Command uv -ErrorAction SilentlyContinue) { $dirs += @(& uv tool dir --bin 2>$null) }
            if ($inst[0] -in "python", "python3", "py") { $dirs += @(& $inst[0] -c "import sysconfig; print(sysconfig.get_path('scripts', 'nt_user'))" 2>$null) }
            foreach ($d in $dirs) {
                if ($d -and ((Test-Path "$d\graphify.exe") -or (Test-Path "$d\graphify.cmd"))) { $env:PATH = "$d;$env:PATH"; break }
            }
        }
        if (-not (Test-Graphify)) { Write-Done "Graphify" "installed" "open a new terminal, then run: graphify update ."; return "handled" }
        Write-Done "Graphify" "installed" "official package: graphifyy"
    } else { Write-Done "Graphify" "found" "already installed" }
    $build = ($Graphify -eq "yes")
    if (-not $Graphify) {
        $build = Read-YesNo "Build the code graph for this project now?" "runs: graphify update .  (reads your code only: no AI, no tokens)" "build it later: graphify update ."
    }
    if (-not $build) { Write-Done "Graph" "not built" "build it later: graphify update ."; return "handled" }
    if ($script:barTotal -ne 2) { $script:barDone = 0; $script:barTotal = 1 }   # graphify was already there: one step
    $r = Invoke-Spinner "Building the code graph" "graphify" @("update", ".") $Target
    $script:barTotal = 0
    if ($r.Ok) {
        $nodes = if ($r.Out -match 'Rebuilt: ([^\r\n\[]+)') { $Matches[1].Trim() } else { "" }
        Write-Done "Graph" "built" "$(if ($nodes) { "$nodes $SEP " })graphify-out/"
        $view = New-GraphView
        if ($null -ne $view) { Write-Done "Graph view" "built" "$(if ($view) { "$view $SEP " })open graphify-out/graph.html" }
        else { Write-Part "    $ELB graph view skipped (needs Python 3.8+). Try later: -GraphView" Dim -End }
        Write-Part "    $ELB commit graphify-out/ to share it, or add it to .gitignore to keep it local" Dim -End
    } else {
        Write-Done "Graph" "build failed" "run graphify update . yourself to see why"
        $r.Out -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 3 | ForEach-Object { Write-Part "        $_" Dim -End }
    }
    return "handled"
}

# ---------- primary skills (optional): Superpowers, Ponytail, Caveman from their official repos ----------
# Asks first (default No). npx skills add fetches the latest version, so it also updates what is already
# installed. Skills go to your user folder: Claude Code (~/.claude/skills), Codex (~/.agents/skills), or both
# with the same skills in each. Returns "handled" (done or declined) or "" (nobody was asked).
$skillList = @(
    @{ Name = "superpowers"; Repo = "obra/superpowers" },
    @{ Name = "ponytail"; Repo = "DietrichGebert/ponytail" },
    @{ Name = "caveman"; Repo = "JuliusBrussee/caveman" }
)
function Invoke-SkillsStep {
    if (-not $Skills -and -not $canAsk) { return "" }   # nobody to ask: the next steps mention it
    $later = "install later: see docs/guides/setup.md"
    if ($Skills -eq "no") { Write-Done "Skills" "skipped" $later; return "handled" }
    $yes = ($Skills -eq "yes")
    if (-not $Skills) {
        $yes = Read-YesNo "Install or update the primary skills (Superpowers, Ponytail, Caveman)?" "official repos. Skills you already have are updated" $later
    }
    if (-not $yes) { Write-Done "Skills" "skipped" $later; return "handled" }
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { Write-Done "Skills" "skipped" "needs Node.js (npx). See docs/guides/setup.md"; return "handled" }
    $agents = switch ($For) { "claude" { @("claude-code") } "agents" { @("codex") } default { @("claude-code", "codex") } }
    $ok = 0; $last = $null
    $script:barDone = 0; $script:barTotal = $skillList.Count
    foreach ($sk in $skillList) {
        $r = Invoke-Spinner "Installing $($sk.Name)" "npx" (@("--yes", "skills", "add", $sk.Repo, "--skill", "*", "--agent") + $agents + @("--global", "-y")) $Target
        if ($r.Ok) { Write-Done $sk.Name "installed or updated" "$($agents -join ' ') $SEP $($sk.Repo)"; $ok++ } else { Write-Done $sk.Name "failed" "run: npx skills add $($sk.Repo)"; $last = $r }
    }
    $script:barTotal = 0
    if ($last) { $last.Out -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 3 | ForEach-Object { Write-Part "        $_" Dim -End } }
    if ($ok -gt 0 -and $For -ne "agents") { Write-Part "    $ELB restart Claude Code to load the new skills" Dim -End }
    return "handled"
}

# ---------- find or download the template ----------
try {
    Write-Host ""
    if (-not (Get-KitRoot)) { return }
    $Template = Join-Path $script:kitRoot "template\$For"
    if (-not (Test-Path $Template)) { Write-Fail "Download incomplete: template\$For not found"; return }
    if ($script:kitSrc -eq "local") { Write-Done "Template" "local copy" }
    elseif ($Version) { Write-Done "Template" "downloaded" "release v$Version" }
    else { Write-Done "Template" "downloaded" "latest from GitHub" }

    # ---------- copy ----------
    $copied = 0; $same = 0; $added = @(); $skipped = @(); $newer = @(); $gitignoreAdded = $null
    $todo = @(Get-ChildItem -Path $Template -Recurse -Force -File | Sort-Object FullName |
        Where-Object { -not ($Prompt -eq 'no' -and $_.FullName.Substring($Template.Length).TrimStart('\', '/') -eq 'PROMPT.md') })
    if ($vt) { try { [Console]::CursorVisible = $false } catch {} }
    for ($k = 0; $k -lt $todo.Count; $k++) {
        Write-Progress-Bar $k $todo.Count
        $file = $todo[$k]
        $rel = $file.FullName.Substring($Template.Length).TrimStart('\', '/')
        $dest = Join-Path $Target $rel
        if ($rel -eq '.gitignore' -and (Test-Path $dest)) {
            $have = @(Get-Content -LiteralPath $dest | ForEach-Object { $_.Trim() })
            $missing = @(Get-Content -LiteralPath $file.FullName | ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and -not $_.StartsWith('#') -and $have -notcontains $_ })
            if ($missing.Count -and -not $DryRun) {
                $raw = [IO.File]::ReadAllText($dest)
                $nl = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
                $text = $(if ($raw -and -not $raw.EndsWith("`n")) { $nl } else { '' }) +
                    "$nl# Added by agents-md-kit$nl" + ($missing -join $nl) + $nl
                [IO.File]::AppendAllText($dest, $text)
            }
            $gitignoreAdded = $missing
            continue
        }
        if (Test-Path $dest) {
            # Same content (line endings ignored): nothing to do. Different: keep yours;
            # in update mode also save the kit's version beside it as .kit-new.
            $isSame = $false
            if (Test-Path $dest -PathType Leaf) {
                $isSame = ([IO.File]::ReadAllText($file.FullName) -replace "`r", "") -ceq ([IO.File]::ReadAllText($dest) -replace "`r", "")
            }
            if ($isSame) { $same++ }
            elseif ($Update -and (Test-Path $dest -PathType Leaf)) {
                if (-not $DryRun) { Copy-Item -LiteralPath $file.FullName -Destination "$dest.kit-new" -Force }
                $newer += $rel
            }
            else { $skipped += $rel }
            continue
        }
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $dest
        }
        $copied++; $added += $rel
    }
    Write-Progress-Bar $todo.Count $todo.Count
    if ($vt) { Write-Host "`r$E[2K" -NoNewline; try { [Console]::CursorVisible = $true } catch {} }

    # ---------- result: a small tree of what changed ----------
    if ($DryRun) {
        Write-Done "Dry run" "nothing was changed" "this is what would happen"
        Write-Done "Would copy" (Format-Files $copied)
    } else { Write-Done "Copied" (Format-Files $copied) }
    $rows = @()   # each row: list of @(text, style) parts
    $added | Group-Object { $p = $_ -split '[\\/]'; if ($p.Count -gt 1) { $p[0] + "/" } else { $p[0] } } | Sort-Object Name | ForEach-Object {
        if ($_.Name.EndsWith("/")) { $rows += , @(@("+ ", "Green"), @($_.Name.PadRight(12) + " ", ""), @((Format-Files $_.Count), "Dim")) }
        else { $rows += , @(@("+ ", "Green"), @($_.Name, "")) }
    }
    if ($null -ne $gitignoreAdded) {
        if ($gitignoreAdded.Count) { $rows += , @(@("~ ", "Green"), @(".gitignore".PadRight(12) + " ", ""), @("kept, $(if ($DryRun) { 'would add' } else { 'added' }): $($gitignoreAdded -join ', ')", "Dim")) }
        else { $rows += , @(, @("= .gitignore   kept, nothing to add", "Dim")) }
    }
    foreach ($s in $skipped) { $rows += , @(@("! ", "Yellow"), @($s.PadRight(12) + " ", ""), @("already existed, left untouched", "Yellow")) }
    foreach ($s in $newer) { $rows += , @(@("$UP ", "Accent"), @($s.PadRight(12) + " ", ""), @("newer kit version $(if ($DryRun) { 'would be saved' } else { 'saved' }) as $s.kit-new", "Accent")) }
    if ($same) { $rows += , @(, @("= $(Format-Files $same) already up to date", "Dim")) }
    for ($i = 0; $i -lt $rows.Count; $i++) {
        Write-Part ("    " + $(if ($i -eq $rows.Count - 1) { $ELB } else { $TEE }) + " ") Dim
        foreach ($part in $rows[$i]) { Write-Part $part[0] $part[1] }
        Write-Host ""
    }
    if ($skipped.Count) { Write-Part "      Files marked ! were kept as they are. Merge the kit's version by hand if you want it." Dim -End }
    $gfyState = ""
    if (-not $DryRun) { $gfyState = "$(Invoke-GraphifyStep)" }
    $skillsState = ""
    if (-not $DryRun) { $skillsState = "$(Invoke-SkillsStep)" }

    # ---------- next steps ----------
    $main = if ($For -eq "agents") { "AGENTS.md" } else { "CLAUDE.md" }
    $anchor = @{ claude = "claude-code-only-claude"; agents = "codex-or-other-agents-agents"; both = "both-both" }[$For]
    $promptUrl = "$repo/blob/main/PROMPTS.md#$anchor"
    Write-Host ""
    if ($DryRun) {
        Write-Part "  $STAR " Accent; Write-Part "Dry run finished." Bold; Write-Part " Nothing was changed." -End
        Write-Part "    Run the same command without "; Write-Part "-DryRun" Bold; Write-Part " to do it for real." -End
        Write-Host ""
        $state.done = $true
        return
    }
    Write-Part "  $STAR " Accent; Write-Part "Next steps" Bold -End
    Write-Host ""
    if ($Update) {
        if ($newer.Count) {
            Write-Part "    1" Accent; Write-Part "  Merge each "; Write-Part "*.kit-new" Bold; Write-Part " file into the file next to it, then delete the .kit-new. Or tell your AI:" -End
            Write-Part "       $PTR " Accent; Write-Part "Merge every *.kit-new file into the file next to it. Keep my project details. Then delete the .kit-new files." Bold -End
        } else {
            Write-Part "    1" Accent; Write-Part "  Nothing to merge. Your kit files match the latest version." -End
        }
        Write-Part "    2" Accent; Write-Part "  New skills or plugins? Check "; Write-Part "docs/guides/setup.md" Bold -End
        if (-not $gfyState) { Write-Part "    Optional: build a code graph the AI can query: graphify update .  (see docs/guides/setup.md)" Dim -End }
        Write-Host ""
        Write-Part "  $DOT " Green; Write-Part "Done." Bold; Write-Part " Guide: $repo/blob/main/GUIDE.md" Dim -End
        Write-Host ""
        $state.done = $true
        return
    }
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
    if ($skillsState) { Write-Part "    2" Accent; Write-Part "  Other skills (design, commit): "; Write-Part "docs/guides/setup.md" Bold -End }
    else { Write-Part "    2" Accent; Write-Part "  Install the skills: "; Write-Part "docs/guides/setup.md" Bold -End }
    if ($For -eq "agents") {
        Write-Part "    3" Accent; Write-Part "  Start your agent and ask it to read "; Write-Part "AGENTS.md" Bold -End
    } else {
        Write-Part "    3" Accent; Write-Part "  In Claude Code, run "; Write-Part "/memory" Bold; Write-Part " and "; Write-Part "/skills" Bold; Write-Part " to check what loads" -End
    }
    if (-not $gfyState) { Write-Part "    Optional: build a code graph the AI can query: graphify update .  (see docs/guides/setup.md)" Dim -End }
    Write-Part "    See which placeholders are left any time: add " Dim; Write-Part "-Check" Bold; Write-Part " to the install command" Dim -End
    Write-Host ""
    Write-Part "  $DOT " Green; Write-Part "Done." Bold; Write-Part " Guide: $repo/blob/main/GUIDE.md" Dim -End
    Write-Host ""
    $state.done = $true
} finally {
    if (-not $state.done -and -not $state.failed) {
        try { [Console]::CursorVisible = $true } catch {}
        Write-Host ""; Write-Host ""; Write-Part "  $DOT Cancelled. Files already copied stay; run again to finish." Yellow -End; Write-Host ""
    }
    if ($script:tmp) { Remove-Item -Recurse -Force $script:tmp -ErrorAction SilentlyContinue }
}
