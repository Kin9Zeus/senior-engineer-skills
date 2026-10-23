#Requires -Version 5.1
<#
.SYNOPSIS
  Devleck Senior Engineer Skills - installer (Windows).

.DESCRIPTION
  Copies skills/, commands/ and agents/ into your agent's directory.
  Shows exactly what it will do and asks before overwriting anything.

.PARAMETER Agent
  claude | cursor | codex | opencode | antigravity. Auto-detected if omitted.

.PARAMETER Project
  Install into .\.claude\ in the current directory instead of your home folder.

.PARAMETER SkillsOnly
  Skip commands and agents.

.PARAMETER Uninstall
  Remove what this installed.

.PARAMETER DryRun
  Show what would happen; change nothing.

.PARAMETER Yes
  Do not prompt (for CI).

.EXAMPLE
  ./install.ps1
  ./install.ps1 -Agent cursor
  ./install.ps1 -Project
  ./install.ps1 -Uninstall
#>
param(
    [ValidateSet('claude', 'cursor', 'codex', 'opencode', 'antigravity')]
    [string]$Agent,
    [switch]$Project,
    [switch]$SkillsOnly,
    [switch]$Uninstall,
    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$Src = Split-Path -Parent $MyInvocation.MyCommand.Path

$SkillNames = @(
    'senior-engineer', 'project-audit', 'project-blueprint', 'security-hardening',
    'database-engineering', 'api-contracts', 'devops-platform', 'observability-slo',
    'testing-strategy', 'performance-engineering', 'accessibility-audit',
    'web-presence-audit', 'privacy-compliance', 'release-readiness', 'engineering-standards',
    'security-incident-response', 'php-hardening', 'pentest-methodology', 'cloud-security',
    'ai-security'
)

function Ok([string]$m)   { Write-Host "  [ok] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host $m -ForegroundColor Yellow }
function Fail([string]$m) { Write-Host $m -ForegroundColor Red }
function Dim([string]$m)  { Write-Host $m -ForegroundColor DarkGray }

Write-Host ""
Write-Host "  Devleck . Senior Engineer Skills" -ForegroundColor Yellow
Dim "  20 skills . 14 commands . 8 agents"
Write-Host ""

# --- Resolve the target ------------------------------------------------------
if (-not $Agent) {
    $Agent = if     (Test-Path "$HOME\.claude")             { 'claude' }
             elseif (Test-Path "$HOME\.cursor")             { 'cursor' }
             elseif (Test-Path "$HOME\.codex")              { 'codex' }
             elseif (Test-Path "$HOME\.config\opencode")    { 'opencode' }
             elseif (Test-Path "$HOME\.gemini\antigravity") { 'antigravity' }
             else                                           { 'claude' }
}

$Base = if ($Project) { Join-Path (Get-Location) '.claude' }
        else {
            switch ($Agent) {
                'claude'      { "$HOME\.claude" }
                'cursor'      { "$HOME\.cursor" }
                'codex'       { "$HOME\.codex" }
                'opencode'    { "$HOME\.config\opencode" }
                'antigravity' { "$HOME\.gemini\antigravity" }
            }
        }

$SkillsDir = Join-Path $Base 'skills'
$CmdsDir   = Join-Path $Base 'commands'
$AgentsDir = Join-Path $Base 'agents'

Write-Host ("  Agent   {0}{1}" -f $Agent, $(if ($Project) { ' (project-local)' } else { '' }))
Write-Host  "  Target  $Base"
Write-Host ""

# --- Uninstall ---------------------------------------------------------------
if ($Uninstall) {
    Warn "This will remove:"
    foreach ($s in $SkillNames) {
        $p = Join-Path $SkillsDir $s
        if (Test-Path $p) { Write-Host "    $p" }
    }
    Get-ChildItem $CmdsDir   -Filter 'snr-*.md' -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "    $($_.FullName)" }
    Get-ChildItem $AgentsDir -Filter 'snr-*.md' -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "    $($_.FullName)" }
    Write-Host ""
    if (-not $Yes) {
        $a = Read-Host "  Proceed? [y/N]"
        if ($a -notmatch '^[yY]') { Write-Host "  Cancelled."; exit 0 }
    }
    foreach ($s in $SkillNames) {
        $p = Join-Path $SkillsDir $s
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
    Get-ChildItem $CmdsDir   -Filter 'snr-*.md' -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem $AgentsDir -Filter 'snr-*.md' -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host ""
    Write-Host "  Removed." -ForegroundColor Green
    Dim "  Restart your agent to apply."
    Write-Host ""
    exit 0
}

# --- Sanity check ------------------------------------------------------------
if (-not (Test-Path (Join-Path $Src 'skills'))) {
    Fail "  No skills/ directory found next to this script."
    Fail "  Run it from inside the cloned repository."
    Write-Host ""
    exit 1
}

$found = @($SkillNames | Where-Object { Test-Path (Join-Path $Src "skills\$_\SKILL.md") })
if ($found.Count -eq 0) {
    Fail "  skills/ contains no SKILL.md files. Is the clone complete?"
    Write-Host ""
    exit 1
}

# --- Plan --------------------------------------------------------------------
Write-Host "  Will install"
Write-Host ("    {0} skills   -> {1}" -f $found.Count, $SkillsDir)

$cmdFiles   = @(Get-ChildItem (Join-Path $Src 'commands') -Filter '*.md' -ErrorAction SilentlyContinue)
$agentFiles = @(Get-ChildItem (Join-Path $Src 'agents')   -Filter '*.md' -ErrorAction SilentlyContinue)
if (-not $SkillsOnly) {
    if ($cmdFiles.Count)   { Write-Host ("    {0} commands -> {1}" -f $cmdFiles.Count,   $CmdsDir) }
    if ($agentFiles.Count) { Write-Host ("    {0} agents   -> {1}" -f $agentFiles.Count, $AgentsDir) }
}

$conflicts = @($SkillNames | Where-Object { Test-Path (Join-Path $SkillsDir $_) })
if ($conflicts.Count) {
    Write-Host ""
    Warn "  Already present (will be replaced):"
    $conflicts | ForEach-Object { Write-Host "    $_" }
}

Write-Host ""
if ($DryRun) { Dim "  -DryRun: nothing was changed."; Write-Host ""; exit 0 }
if (-not $Yes) {
    $a = Read-Host "  Proceed? [Y/n]"
    if ($a -match '^[nN]') { Write-Host "  Cancelled."; exit 0 }
}

# --- Install -----------------------------------------------------------------
if (-not (Test-Path $SkillsDir)) { New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null }

foreach ($s in $SkillNames) {
    $from = Join-Path $Src "skills\$s"
    if (-not (Test-Path $from)) { continue }
    $to = Join-Path $SkillsDir $s
    if (Test-Path $to) { Remove-Item $to -Recurse -Force }
    Copy-Item $from $to -Recurse -Force
    Ok $s
}

if (-not $SkillsOnly) {
    if ($cmdFiles.Count) {
        if (-not (Test-Path $CmdsDir)) { New-Item -ItemType Directory -Path $CmdsDir -Force | Out-Null }
        $cmdFiles | Copy-Item -Destination $CmdsDir -Force
        Ok 'commands'
    }
    if ($agentFiles.Count) {
        if (-not (Test-Path $AgentsDir)) { New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null }
        $agentFiles | Copy-Item -Destination $AgentsDir -Force
        Ok 'agents'
    }
}

Write-Host ""
Write-Host "  Installed." -ForegroundColor Green
Write-Host "  Restart your agent, then try:"
Write-Host ""
Write-Host "    /snr-audit      " -ForegroundColor Yellow -NoNewline; Write-Host "full audit of the current repository"
Write-Host "    /snr-scorecard  " -ForegroundColor Yellow -NoNewline; Write-Host "fast 15-domain rating"
Write-Host "    /snr-build      " -ForegroundColor Yellow -NoNewline; Write-Host "architect and scaffold something new"
Write-Host "    /snr-ship       " -ForegroundColor Yellow -NoNewline; Write-Host "go/no-go release gate"
Write-Host "    /snr-incident   " -ForegroundColor Yellow -NoNewline; Write-Host "breach / leaked key / exploited CVE response"
Write-Host "    /snr-pentest    " -ForegroundColor Yellow -NoNewline; Write-Host "authorised, scoped security test"
Write-Host ""
Write-Host "  Or just describe the work - the skills activate on their own."
Write-Host ""
Dim "  Docs: https://github.com/Kin9Zeus/senior-engineer-skills"
Write-Host ""
