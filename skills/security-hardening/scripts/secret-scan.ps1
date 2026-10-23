#Requires -Version 5.1
<#
.SYNOPSIS
  Devleck Senior Engineer Skills - read-only secret and risk-pattern scan (Windows).

.DESCRIPTION
  Scans the working tree and git history for credential-shaped strings and
  high-risk code patterns. Makes no network calls and modifies nothing.

  This is a triage aid, not a scanner. It finds obvious leaks fast; it does not
  find everything, and it produces false positives. Confirm every hit by reading
  the file. For continuous coverage use a dedicated tool (gitleaks, trufflehog,
  or your host's native secret scanning).

.PARAMETER Path
  Project root. Defaults to the current directory.

.EXAMPLE
  ./secret-scan.ps1
  ./secret-scan.ps1 -Path C:\src\my-app

.OUTPUTS
  Exit code 0 = clean, 1 = findings, 2 = usage error.
#>
param([string]$Path = ".")

$ErrorActionPreference = "SilentlyContinue"
try { Set-Location -Path $Path -ErrorAction Stop } catch { Write-Error "secret-scan: cannot enter '$Path'"; exit 2 }

$script:Findings = 0
$ExcludeDirs = @('node_modules', '.git', 'dist', 'build', 'vendor', '.next', 'target', '__pycache__', '.venv', 'venv', 'coverage')
$ExcludeFile = 'package-lock\.json|yarn\.lock|pnpm-lock\.yaml|\.min\.js$'
$Placeholder = 'example|sample|placeholder|your[-_]|xxx|<.*>|dummy|fake|test_key'

function Section([string]$t) { Write-Host ""; Write-Host $t -ForegroundColor White; Write-Host ("-" * 44) -ForegroundColor DarkGray }
function Bad([string]$m)  { Write-Host $m -ForegroundColor Red;    $script:Findings++ }
function BadLine([string]$m) { Write-Host $m -ForegroundColor Red }
function Warn([string]$m) { Write-Host $m -ForegroundColor Yellow }
function Good([string]$m) { Write-Host $m -ForegroundColor Green }
function Rel([string]$p)  { $p.Replace((Get-Location).Path, '.') }

function Get-Targets {
    Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
        $full = $_.FullName
        $ok = $true
        foreach ($d in $ExcludeDirs) { if ($full -match "[\\/]$([regex]::Escape($d))[\\/]") { $ok = $false; break } }
        $ok -and ($_.Name -notmatch $ExcludeFile)
    }
}

Write-Host " Devleck - Secret & Risk Pattern Scan " -ForegroundColor Black -BackgroundColor Yellow
Write-Host " $((Get-Location).Path)"
$targets = Get-Targets

# --- 1. Tracked secret files -------------------------------------------------
Section "1 . TRACKED SECRET FILES"
$isGit = (Test-Path .git) -and [bool](Get-Command git -ErrorAction SilentlyContinue)
if ($isGit) {
    $tracked = git ls-files 2>$null | Where-Object {
        $_ -match '(^|/)(\.env($|\.)|.*\.pem$|.*\.key$|.*\.p12$|.*\.pfx$|.*\.jks$|id_rsa|id_ed25519|.*service-account.*\.json)' -and
        $_ -notmatch 'example|sample|template|\.d\.ts'
    }
    if ($tracked) { Bad "P0 . secret-shaped files tracked in git:"; $tracked | ForEach-Object { "     $_" } }
    else { Good "ok . no secret-shaped files tracked" }
} else { Warn "-- not a git repository; skipping tracked-file check" }

# --- 2. Git history ----------------------------------------------------------
Section "2 . GIT HISTORY"
if ($isGit) {
    $hist = git log --all --full-history --name-only --pretty=format: -- '*.env' '*.env.*' '*.pem' '*.key' '*.p12' '*.pfx' '*id_rsa*' '*credentials*' 2>$null |
        Where-Object { $_ -and $_ -notmatch 'example|sample|template' } | Sort-Object -Unique
    if ($hist) {
        Bad "P0 . secret-shaped files exist in history (present in every clone):"
        $hist | ForEach-Object { "     $_" }
        Warn "     Remediation order: 1) ROTATE the credential  2) check provider audit"
        Warn "     logs for abuse  3) purge history (git filter-repo / BFG)  4) enable"
        Warn "     secret scanning. Purging without rotating leaves the key live."
    } else { Good "ok . no secret-shaped files in history" }
}

# --- 3. Credential patterns --------------------------------------------------
Section "3 . CREDENTIAL PATTERNS IN SOURCE"
$credPatterns = [ordered]@{
    'AWS access key id'            = 'AKIA[0-9A-Z]{16}'
    'Stripe live secret key'       = 'sk_live_[0-9a-zA-Z]{16,}'
    'Stripe restricted key'        = 'rk_live_[0-9a-zA-Z]{16,}'
    'GitHub token'                 = '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}'
    'Google API key'               = 'AIza[0-9A-Za-z_-]{35}'
    'Slack token'                  = 'xox[baprs]-[0-9A-Za-z-]{10,}'
    'Slack webhook'                = 'hooks\.slack\.com/services/T[A-Za-z0-9]+/B[A-Za-z0-9]+/'
    'Private key block'            = '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'SendGrid key'                 = 'SG\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
    'Twilio account SID'           = 'AC[a-f0-9]{32}'
    'OpenAI / Anthropic key'       = 'sk-proj-[A-Za-z0-9_-]{20,}|sk-ant-[A-Za-z0-9_-]{20,}'
    'npm token'                    = 'npm_[A-Za-z0-9]{36}'
    'JWT with payload'             = 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.'
    'Connection string w/ password'= '(postgres(ql)?|mysql|mongodb(\+srv)?|redis|amqp)://[^:/@\s]+:[^@/\s]{6,}@'
    'Hardcoded password assignment'= '(password|passwd|pwd|secret|api_?key|token)\s*[:=]\s*["''][^"''$\{]{10,}["'']'
}
$credFound = $false
foreach ($name in $credPatterns.Keys) {
    $hits = $targets | Select-String -Pattern $credPatterns[$name] |
        Where-Object { $_.Line -notmatch $Placeholder } | Select-Object -First 5
    if ($hits) {
        Bad "P0 . $name"; $credFound = $true
        $hits | ForEach-Object { "     {0}:{1}: {2}" -f (Rel $_.Path), $_.LineNumber, $_.Line.Trim().Substring(0, [Math]::Min(120, $_.Line.Trim().Length)) }
    }
}
if (-not $credFound) { Good "ok . no credential patterns matched" }

# --- 4. Client-bundle exposure -----------------------------------------------
Section "4 . CLIENT-BUNDLE EXPOSURE"
$pub = $targets | Select-String -Pattern '(NEXT_PUBLIC|VITE|REACT_APP|PUBLIC|NUXT_PUBLIC|EXPO_PUBLIC)_[A-Z0-9_]*(SECRET|PRIVATE|KEY|TOKEN|PASSWORD|CREDENTIAL)' | Select-Object -First 8
if ($pub) {
    Bad "P0 . secret-sounding variable with a PUBLIC prefix - this is compiled into"
    BadLine "     the browser bundle and is readable by anyone:"
    $pub | ForEach-Object { "     {0}:{1}" -f (Rel $_.Path), $_.LineNumber }
} else { Good "ok . no secret-named public-prefixed variables" }

foreach ($d in @('dist', 'build', '.next/static', 'out', 'public')) {
    if (Test-Path $d) {
        $b = Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue |
             Select-String -Pattern 'sk_live_[0-9a-zA-Z]{16,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----' -List | Select-Object -First 3
        if ($b) { Bad "P0 . live-key pattern inside built output ($d):"; $b | ForEach-Object { "     " + (Rel $_.Path) } }
    }
}

# --- 5. Injection sinks ------------------------------------------------------
Section "5 . INJECTION SINKS  (review each - many are legitimate)"
$sinks = [ordered]@{
    'String-built SQL'                    = '(query|execute|exec|raw|prepare)\s*\(\s*["`''][^"`'']*(\$\{|"\s*\+|%s|f["''])'
    'ORM raw escape hatches'              = '\.(raw|extra)\(|whereRaw|FromSqlRaw|\$queryRawUnsafe|sequelize\.query\('
    'Shell execution'                     = 'child_process|execSync|spawn\(|os\.system|subprocess\.(call|run|Popen)|shell_exec|passthru'
    'Dynamic code evaluation'             = '\beval\(|new Function\(|pickle\.loads'
    'Raw HTML sinks'                      = 'dangerouslySetInnerHTML|v-html|\.innerHTML\s*=|document\.write|html_safe|\|\s*safe'
    'Deserialization'                     = 'pickle\.load|yaml\.unsafe_load|ObjectInputStream|unserialize\(|Marshal\.load'
    'Server-side fetch of input URL (SSRF)' = '(fetch|axios|requests\.(get|post)|http\.(get|request)|urlopen|curl_exec)\([^)]*(req\.|request\.|params|query|body)'
    'PHP include/require of a variable path' = '(include|require)(_once)?\s*\(?\s*\$[A-Za-z_]'
    'PHP phpinfo() / diagnostic output'   = '\bphpinfo\s*\('
}
foreach ($name in $sinks.Keys) {
    $hits = $targets | Select-String -Pattern $sinks[$name] | Select-Object -First 5
    if ($hits) { Warn "!  $name"; $hits | ForEach-Object { "     {0}:{1}" -f (Rel $_.Path), $_.LineNumber } }
}

# --- 6. Configuration --------------------------------------------------------
Section "6 . CONFIGURATION"
$cfg = [ordered]@{
    'Debug enabled'                     = '(DEBUG|debug)\s*[:=]\s*(True|true|1)\b'
    'TLS verification disabled'         = 'rejectUnauthorized\s*:\s*false|verify\s*=\s*False|InsecureSkipVerify\s*:\s*true|CURLOPT_SSL_VERIFYPEER\s*,\s*(0|false)'
    'Permissive CORS'                   = 'Access-Control-Allow-Origin[^,)]*\*|origin\s*:\s*(true|"\*")'
    'Weak hashing on secrets'           = '(md5|sha1)\(.*(pass|pwd|secret|token)'
    'Non-crypto randomness for tokens'  = '(Math\.random|random\.random)\(\)[^;]*(token|secret|key|otp|nonce|password)'
    'Remote script piped to a shell'    = 'curl[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b|wget[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b'
    'CI action not pinned to a SHA'     = 'uses:\s*[\w./-]+@(main|master|v?\d+(\.\d+)*)\s*$'
}
foreach ($name in $cfg.Keys) {
    $hits = $targets | Select-String -Pattern $cfg[$name] | Select-Object -First 5
    if ($hits) { Warn "!  $name"; $hits | ForEach-Object { "     {0}:{1}" -f (Rel $_.Path), $_.LineNumber } }
}

# --- 7. Ignore files ---------------------------------------------------------
Section "7 . IGNORE FILES"
if (Test-Path .gitignore) {
    $gi = Get-Content .gitignore -Raw
    foreach ($p in @('.env', '*.pem', '*.key')) {
        if ($gi -notmatch [regex]::Escape($p)) { Warn "!  .gitignore does not cover  $p" }
    }
    if ($gi -match '\.env') { Good "ok . .gitignore covers .env" }
} else { Bad "P0 . no .gitignore at the repository root" }

# --- Summary -----------------------------------------------------------------
Write-Host ""; Write-Host ("-" * 44) -ForegroundColor DarkGray
if ($script:Findings -gt 0) {
    Write-Host "$($script:Findings) high-severity pattern group(s) matched." -ForegroundColor Red
    Warn "Confirm each by reading the file. If a real credential is exposed:"
    Warn "ROTATE IT FIRST, then check for abuse, then purge the history."
    exit 1
} else {
    Good "No high-severity patterns matched."
    Write-Host "This is triage, not assurance. Run a dedicated scanner (gitleaks," -ForegroundColor DarkGray
    Write-Host "trufflehog, or your host's native secret scanning) for real coverage." -ForegroundColor DarkGray
    exit 0
}
