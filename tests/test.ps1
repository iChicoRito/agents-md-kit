# Tests install.ps1 without a keyboard: every version, new and existing projects, rerun, update.
# Usage: powershell -File tests\test.ps1     (exit code 0 = all passed)
$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot
$work = Join-Path ([IO.Path]::GetTempPath()) ("kit-test-" + [guid]::NewGuid())
New-Item -ItemType Directory $work | Out-Null
$ps = (Get-Process -Id $PID).Path   # same PowerShell that runs the tests
$script:n = 0; $script:fails = 0
function Test-That([string]$Name, [scriptblock]$Check) {
    $script:n++
    $ok = $false; try { $ok = [bool](& $Check) } catch { $ok = $false }
    if ($ok) { "  ok   $Name" } else { "  FAIL $Name"; $script:fails++ }
}
# Runs the installer in a child process with no keyboard (stdin redirected), so nothing is asked.
function Invoke-Install([string[]]$Arguments) {
    $script:log = "" | & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $kit "install.ps1") @Arguments 2>&1 | Out-String
    $script:log = $script:log -replace "$([char]27)\[[0-9;?]*[A-Za-z]", ''   # drop color codes
    return $LASTEXITCODE -eq 0 -and $script:log -notmatch 'Error:'
}
function Test-HasAll([string]$Version, [string]$Dir, [bool]$WithPrompt) {
    $root = Join-Path $kit "template\$Version"
    foreach ($f in Get-ChildItem $root -Recurse -Force -File) {
        $rel = $f.FullName.Substring($root.Length).TrimStart('\', '/')
        if ($rel -eq 'PROMPT.md' -and -not $WithPrompt) { continue }
        if (-not (Test-Path (Join-Path $Dir $rel))) { "       missing: $rel" | Write-Host; return $false }
    }
    return $true
}
function Get-Snapshot([string]$Dir) {
    (Get-ChildItem $Dir -Recurse -Force -File | Sort-Object FullName | ForEach-Object { $_.FullName + ":" + (Get-FileHash $_.FullName).Hash }) -join "`n"
}

try {
    $version = (Get-Content (Join-Path $kit "VERSION") -Raw).Trim()
    "== version $version"
    Test-That "install.ps1 version matches VERSION" { (Get-Content (Join-Path $kit "install.ps1")) -contains ('$kitVersion = "' + $version + '"   # keep equal to the VERSION file (the tests check this)') }
    foreach ($v in "claude", "agents", "both") {
        "== $v"
        $main = if ($v -eq "agents") { "AGENTS.md" } else { "CLAUDE.md" }

        $d = Join-Path $work "$v-new"; New-Item -ItemType Directory $d | Out-Null
        Test-That "new: installs without error" { Invoke-Install @($d, "-For", $v, "-Project", "new", "-Prompt", "no") }
        Test-That "new: every kit file is there" { Test-HasAll $v $d $false }
        Test-That "new: no PROMPT.md" { -not (Test-Path "$d\PROMPT.md") }
        $rulesDir = if ($v -eq "agents") { ".agents/rules" } else { ".claude/rules" }
        Test-That "new: graphify rule installed" { Test-Path (Join-Path $d "$rulesDir/graphify.md") }
        Test-That "new: every rule file is listed in $main" { $txt = Get-Content (Join-Path $d $main) -Raw; -not (Get-ChildItem (Join-Path $d $rulesDir) -Filter *.md | Where-Object { -not $txt.Contains("$rulesDir/$($_.Name)") }) }
        Test-That "new: no kit marker file added" { -not (Test-Path "$d\.agents-md-kit") }
        if ($v -eq "claude") { Test-That "new: no .agents folder" { -not (Test-Path "$d\.agents") } }
        if ($v -eq "agents") { Test-That "new: no .claude folder" { -not (Test-Path "$d\.claude") } }

        $before = Get-Snapshot $d
        Test-That "rerun: installs without error" { Invoke-Install @($d, "-For", $v, "-Project", "new", "-Prompt", "no") }
        Test-That "rerun: no file changed" { (Get-Snapshot $d) -eq $before }

        $d = Join-Path $work "$v-existing"; New-Item -ItemType Directory $d | Out-Null
        Set-Content "$d\$main" "my own instructions"; Set-Content "$d\app.js" "x"; Set-Content "$d\.gitignore" "node_modules"
        Test-That "existing: installs without error" { Invoke-Install @($d, "-For", $v) }
        Test-That "existing: own $main untouched" { (Get-Content "$d\$main" -Raw).Trim() -eq "my own instructions" }
        Test-That "existing: PROMPT.md added" { Test-Path "$d\PROMPT.md" }
        Test-That "existing: .gitignore keeps own line" { (Get-Content "$d\.gitignore") -contains "node_modules" }
        Test-That "existing: .gitignore gets kit lines" { (Get-Content "$d\.gitignore") -contains "*.kit-new" }
        Test-That "existing: $main listed as left untouched" { $script:log -match 'already existed' }

        $d = Join-Path $work "$v-update"; New-Item -ItemType Directory $d | Out-Null
        Invoke-Install @($d, "-For", $v, "-Project", "new", "-Prompt", "no") | Out-Null
        Add-Content "$d\$main" "# my notes"; Remove-Item "$d\docs\glossary.md"
        Test-That "update: runs without error" { Invoke-Install @($d, "-Update") }
        Test-That "update: detects version $v" { $script:log -match "Agents\s+$v" }
        Test-That "update: deleted file restored" { Test-Path "$d\docs\glossary.md" }
        Test-That "update: changed file gets .kit-new" { Test-Path "$d\$main.kit-new" }
        Test-That "update: own edit kept" { (Get-Content "$d\$main") -contains "# my notes" }
        Test-That "update: .kit-new is the kit version" { (Get-FileHash "$d\$main.kit-new").Hash -eq (Get-FileHash (Join-Path $kit "template\$v\$main")).Hash }
        Test-That "update: no PROMPT.md added" { -not (Test-Path "$d\PROMPT.md") }
    }
    "== dry run and add-command"
    $d = Join-Path $work "dry"; New-Item -ItemType Directory $d | Out-Null
    Set-Content "$d\CLAUDE.md" "mine"; Set-Content "$d\.gitignore" "node_modules"
    $dryBefore = Get-Snapshot $d
    Test-That "dry run: runs without error" { Invoke-Install @($d, "-For", "both", "-DryRun") }
    Test-That "dry run: no file changed" { (Get-Snapshot $d) -eq $dryBefore }
    Test-That "dry run: says what would happen" { $script:log -match 'Would copy' }
    $pp = Join-Path $work "profile\Microsoft.PowerShell_profile.ps1"
    Test-That "add-command: runs without error" { Invoke-Install @("-AddCommand", "-ProfilePath", $pp) }
    Test-That "add-command: adds to the profile" { (Get-Content $pp) -match '^function agents-md-kit ' }
    Test-That "add-command: second run adds nothing" { (Invoke-Install @("-AddCommand", "-ProfilePath", $pp)) -and @((Get-Content $pp) -match '^function agents-md-kit ').Count -eq 1 }

    "== check"
    $d = Join-Path $work "check"; New-Item -ItemType Directory $d | Out-Null
    Invoke-Install @($d, "-For", "both", "-Project", "new", "-Prompt", "no") | Out-Null
    Test-That "check: runs without error" { Invoke-Install @($d, "-Check") }
    Test-That "check: fresh install has placeholders" { $script:log -match 'placeholders left' -and $script:log -match 'CLAUDE\.md' }
    Test-That "check: skips the ADR template" { $script:log -notmatch '0000-template' }
    $re = [regex]'\[[A-Z][A-Z0-9 _,./:-]+\](?!\()'
    Get-ChildItem $d -Recurse -File -Include *.md, *.yaml | Where-Object { $_.Name -ne '0000-template.md' } | ForEach-Object {
        [IO.File]::WriteAllText($_.FullName, $re.Replace([IO.File]::ReadAllText($_.FullName), 'filled'))
    }
    Add-Content "$d\docs\README.md" "See [API](api/README.md)."
    Test-That "check: all filled, links ignored" { (Invoke-Install @($d, "-Check")) -and $script:log -match 'no placeholders left' }
    $empty = Join-Path $work "empty"; New-Item -ItemType Directory $empty | Out-Null
    Test-That "check: empty folder fails" { -not (Invoke-Install @($empty, "-Check")) }

    "== graphify"
    # Asks first, installs or builds only with a yes. Fake tools, nothing real is installed.
    $stubs = Join-Path $work "stubs"; New-Item -ItemType Directory "$stubs\have", "$stubs\inst" | Out-Null
    $stubGraphify = "@echo off`r`necho graphify %* >> `"%STUBLOG%`"`r`nmkdir graphify-out 2>nul`r`necho {}> graphify-out\graph.json`r`necho [graphify watch] Rebuilt: 7 nodes, 9 edges, 2 communities`r`n"
    [IO.File]::WriteAllText("$stubs\have\graphify.cmd", $stubGraphify)
    [IO.File]::WriteAllText("$stubs\graphify.tpl", $stubGraphify)
    [IO.File]::WriteAllText("$stubs\inst\uv.cmd", "@echo off`r`necho uv %* >> `"%STUBLOG%`"`r`nif `"%1 %2`"==`"tool install`" copy /y `"%~dp0..\graphify.tpl`" `"%~dp0graphify.cmd`" >nul`r`n")
    $sysPath = "$env:SystemRoot\System32;$env:SystemRoot"
    # Runs the installer with only the fake tools on PATH. Returns the project folder.
    function Invoke-Gfy([string]$Name, [string]$ToolDir, [string[]]$Options, [bool]$WithGraph = $false) {
        $dir = Join-Path $work "gfy-$Name"; New-Item -ItemType Directory $dir | Out-Null
        if ($WithGraph) { New-Item -ItemType Directory "$dir\graphify-out" | Out-Null; Set-Content "$dir\graphify-out\graph.json" "{}" }
        Remove-Item "$stubs\inst\graphify.cmd" -ErrorAction SilentlyContinue
        $script:gfyLog = Join-Path $stubs "log-$Name.txt"; Set-Content $script:gfyLog ""
        $oldPath = $env:PATH; $env:STUBLOG = $script:gfyLog; $env:PATH = "$ToolDir;$sysPath"
        try { Invoke-Install (@($dir, "-For", "claude", "-Project", "new", "-Prompt", "no") + $Options) | Out-Null }
        finally { $env:PATH = $oldPath; Remove-Item Env:STUBLOG -ErrorAction SilentlyContinue }
        $dir
    }
    function Get-StubLog { (Get-Content $script:gfyLog | Where-Object { $_.Trim() }) -join ";" }
    $gA = Invoke-Gfy "A" "$stubs\have" @("-Graphify", "yes"); $logA = Get-StubLog; $outA = $script:log
    Test-That "graphify yes (installed): graph built" { (Test-Path "$gA\graphify-out\graph.json") -and $logA -match 'graphify update \.' -and $outA -match 'built' }
    $gB = Invoke-Gfy "B" "$stubs\inst" @("-Graphify", "yes"); $logB = Get-StubLog
    Test-That "graphify yes (missing): installs, then builds" { $logB -match 'uv tool install graphifyy' -and $logB -match 'graphify update \.' -and (Test-Path "$gB\graphify-out\graph.json") }
    $gC = Invoke-Gfy "C" "$stubs\have" @("-Graphify", "no"); $logC = Get-StubLog; $outC = $script:log
    Test-That "graphify no: nothing runs" { -not $logC -and -not (Test-Path "$gC\graphify-out") -and $outC -match 'skipped' }
    $gD = Invoke-Gfy "D" "$stubs\have" @(); $logD = Get-StubLog; $outD = $script:log
    Test-That "graphify (nobody to ask): nothing runs, tip shown" { -not $logD -and -not (Test-Path "$gD\graphify-out") -and $outD -match 'Optional: build a code graph' }
    $gE = Invoke-Gfy "E" "$stubs\have" @("-Graphify", "yes") $true; $logE = Get-StubLog; $outE = $script:log
    Test-That "graphify: existing graph is left alone" { -not $logE -and $outE -match 'graph found' }
    $gG = Invoke-Gfy "G" "$stubs\have" @("-DryRun", "-Graphify", "yes"); $logG = Get-StubLog
    Test-That "graphify: dry run changes nothing" { -not $logG -and -not (Test-Path "$gG\graphify-out") }
    Test-That "bad -Graphify value fails" { -not (Invoke-Install @($work, "-Graphify", "maybe")) }

    "== skills"
    # Asks first, installs or updates only with a yes. Fake claude and npx, empty fake home.
    $sk = Join-Path $work "sk"; New-Item -ItemType Directory $sk | Out-Null
    [IO.File]::WriteAllText("$sk\claude.cmd", "@echo off`r`necho claude %* >> `"%STUBLOG%`"`r`nif `"%1 %2`"==`"plugin list`" ( echo   * superpowers@other& echo   * caveman@caveman& echo   * mattpocock-skills@mattpocock )`r`n")
    [IO.File]::WriteAllText("$sk\npx.cmd", "@echo off`r`necho npx %* >> `"%STUBLOG%`"`r`n")
    function Invoke-Skl([string]$Name, [string[]]$Options, [string]$FakeHome = "") {
        $dir = Join-Path $work "sk-$Name"; New-Item -ItemType Directory $dir | Out-Null
        $script:sklLog = Join-Path $sk "log-$Name.txt"; Set-Content $script:sklLog ""
        if (-not $FakeHome) { $FakeHome = Join-Path $work "home-$Name"; New-Item -ItemType Directory $FakeHome | Out-Null }
        $oldPath = $env:PATH; $env:STUBLOG = $script:sklLog; $env:PATH = "$sk;$sysPath"
        $env:AGENTS_MD_KIT_HOME = $FakeHome
        try { Invoke-Install (@($dir, "-Project", "new", "-Prompt", "no", "-Graphify", "no") + $Options) | Out-Null }
        finally { $env:PATH = $oldPath; Remove-Item Env:AGENTS_MD_KIT_HOME -ErrorAction SilentlyContinue; Remove-Item Env:STUBLOG -ErrorAction SilentlyContinue }
    }
    function Get-SklLog { (Get-Content $script:sklLog | Where-Object { $_.Trim() }) -join ";" }
    Invoke-Skl "A" @("-For", "claude", "-Skills", "yes"); $lA = Get-SklLog
    Test-That "skills yes (claude): missing plugins installed, installed one only updated, no npx" { $lA -match 'plugin install superpowers --marketplace obra/superpowers' -and $lA -match 'plugin install ponytail --marketplace DietrichGebert/ponytail' -and $lA -match 'plugin update caveman@caveman' -and $lA -notmatch 'plugin install caveman' -and $lA -notmatch 'npx' }
    Test-That "skills: restart note shown after a Claude plugin change" { $script:log -match 'restart Claude Code' }
    Invoke-Skl "B" @("-For", "agents", "-Skills", "yes"); $lB = Get-SklLog
    Test-That "skills (agents): no restart note" { $script:log -notmatch 'restart Claude Code' }
    Test-That "skills yes (agents): npx skills add for all three, codex only, no claude" { ([regex]::Matches($lB, 'skills add')).Count -eq 3 -and $lB -match '--agent codex --global' -and $lB -notmatch 'claude' }
    Invoke-Skl "C" @("-For", "both", "-Skills", "yes"); $lC = Get-SklLog
    Test-That "skills yes (both): plugins for claude, skills for codex" { $lC -match 'claude plugin install' -and ([regex]::Matches($lC, 'npx')).Count -eq 3 }
    $homeH = Join-Path $work "home-H"; New-Item -ItemType Directory "$homeH\.claude\skills\ponytail" -Force | Out-Null
    Invoke-Skl "H" @("-For", "claude", "-Skills", "yes") $homeH; $lH = Get-SklLog
    Test-That "skills: a skill already in ~/.claude/skills is not installed as a plugin" { $lH -notmatch 'plugin install ponytail' -and $lH -match 'plugin install superpowers' }
    Invoke-Skl "D" @("-For", "both", "-Skills", "no"); $lD = Get-SklLog
    Test-That "skills no: nothing runs" { -not $lD }
    Invoke-Skl "E" @("-For", "both"); $lE = Get-SklLog
    Test-That "skills (nobody to ask): nothing runs" { -not $lE }
    Invoke-Skl "F" @("-For", "both", "-DryRun", "-Skills", "yes"); $lF = Get-SklLog
    Test-That "skills: dry run changes nothing" { -not $lF }
    Test-That "bad -Skills value fails" { -not (Invoke-Install @($work, "-Skills", "maybe")) }

    "== graph view"
    # An interactive, Obsidian-style graph.html built from graphify-out/graph.json
    $py = $null
    foreach ($c in "python", "py", "python3") {
        if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { continue }
        & $c -c "import sys; sys.exit(sys.version_info < (3, 8))" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $py = $c; break }
    }
    if ($py) {
        Test-That "graph view: generator tests pass" {
            $ErrorActionPreference = "Continue"   # the tests print expected errors to stderr
            $o = & $py (Join-Path $kit "tests\test_graph_view.py") 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) { Write-Host $o }
            $LASTEXITCODE -eq 0
        }
        $d = Join-Path $work "gview"; New-Item -ItemType Directory "$d\graphify-out" | Out-Null
        Copy-Item (Join-Path $kit "tests\fixtures\graph.json") "$d\graphify-out\graph.json"
        Test-That "graph view: installer builds graph.html" { (Invoke-Install @($d, "-GraphView")) -and (Test-Path "$d\graphify-out\graph.html") -and ((Get-Content "$d\graphify-out\graph.html" -Raw) -match 'AuthModule') }
        Remove-Item "$d\graphify-out\graph.html"
        Test-That "graph view: dry run writes nothing" { (Invoke-Install @($d, "-GraphView", "-DryRun")) -and -not (Test-Path "$d\graphify-out\graph.html") }
        $ng = Join-Path $work "nograph"; New-Item -ItemType Directory $ng | Out-Null
        Test-That "graph view: no graph fails" { -not (Invoke-Install @($ng, "-GraphView")) }
    } else { "  skip  graph view tests: no Python 3.8+ found" }

    "== errors"
    Test-That "unknown -For value fails" { -not (Invoke-Install @($work, "-For", "nope")) }
    Test-That "missing folder fails" { -not (Invoke-Install @((Join-Path $work "does-not-exist"), "-For", "both")) }
    Test-That "bad -Version value fails" { -not (Invoke-Install @($work, "-Version", "abc")) }
} finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
""
"$($script:n - $script:fails)/$($script:n) passed"
if ($script:fails) { exit 1 }
