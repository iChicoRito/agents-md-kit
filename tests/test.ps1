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
    foreach ($v in "claude", "agents", "both") {
        "== $v"
        $main = if ($v -eq "agents") { "AGENTS.md" } else { "CLAUDE.md" }

        $d = Join-Path $work "$v-new"; New-Item -ItemType Directory $d | Out-Null
        Test-That "new: installs without error" { Invoke-Install @($d, "-For", $v, "-Project", "new", "-Prompt", "no") }
        Test-That "new: every kit file is there" { Test-HasAll $v $d $false }
        Test-That "new: no PROMPT.md" { -not (Test-Path "$d\PROMPT.md") }
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
    "== errors"
    Test-That "unknown -For value fails" { -not (Invoke-Install @($work, "-For", "nope")) }
    Test-That "missing folder fails" { -not (Invoke-Install @((Join-Path $work "does-not-exist"), "-For", "both")) }
} finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
""
"$($script:n - $script:fails)/$($script:n) passed"
if ($script:fails) { exit 1 }
