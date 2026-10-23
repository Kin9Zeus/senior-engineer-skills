# Devleck Senior Engineer Skills - read-only PHP inventory and risk-pattern scan.
#
# 1. Finds every place a PHP version is declared (composer, Docker, CI, version
#    files, platform config).
# 2. If a `php` binary is on PATH, reports its version and the ini values that
#    matter, and compares the version with the fixed releases listed below.
# 3. Searches application code for PHP-specific dangerous patterns.
#
# Makes no network calls and modifies nothing. Triage aid, not a scanner:
#   * The CLI binary is NOT necessarily the PHP that serves your web traffic.
#   * Distribution packages may carry the fix under an older version number.
#   * Everything it reports is a lead, not a finding - confirm by reading the code.
#
# Fixed releases are from the October 2026 PHP security release (CVE-2026-109618
# and CVE-2026-109619) as reported by CISA / Tenable - VERIFY against the official
# PHP advisory and update the table when newer releases ship.
#
# Usage:  .\php-check.ps1 [-Path .]
# Exit:   0 clean | 1 findings | 2 usage error
#
# Requires PowerShell 5.1+.

param([string]$Path = '.')

$ErrorActionPreference = 'SilentlyContinue'
if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Host "php-check: cannot enter '$Path'" -ForegroundColor Red
    exit 2
}
Set-Location -LiteralPath $Path

$Fixed = @{ '8.5' = 12; '8.4' = 27; '8.3' = 36; '8.2' = 35 }
$script:Findings = 0
$Excl = '\\(node_modules|\.git|vendor|storage|cache|dist|build)(\\|$)'

function Sec([string]$t) { Write-Host ""; Write-Host $t -ForegroundColor White; Write-Host "------------------------------------------" -ForegroundColor DarkGray }
function Red([string]$t)  { Write-Host $t -ForegroundColor Red }
function Ylw([string]$t)  { Write-Host $t -ForegroundColor Yellow }
function Grn([string]$t)  { Write-Host $t -ForegroundColor Green }

function Assess([string]$v) {
    $parts = $v.Split('.')
    $mm = "$($parts[0]).$($parts[1])"
    $patch = 0
    if ($parts.Count -ge 3) { [int]::TryParse(($parts[2] -replace '[^0-9].*$', ''), [ref]$patch) | Out-Null }
    if ($Fixed.ContainsKey($mm)) {
        if ($patch -lt $Fixed[$mm]) { Red "P0 - PHP $v is below fixed $mm.$($Fixed[$mm])"; $script:Findings++; return }
        Grn "ok - PHP $v is at or above the listed fixed level for its branch (still verify distro/runtime)"; return
    }
    if ($mm -in @('8.1', '8.0', '7.4')) { Ylw "P0? - PHP $mm has no official fixed release; needs a vendor-fixed build or the published backport, or an upgrade"; $script:Findings++; return }
    if ($parts[0] -in @('7', '5', '4')) { Red "P0 - PHP $mm is end-of-life with no fix from the project - migrate or isolate"; $script:Findings++; return }
    Ylw "? - unrecognised branch '$mm' - check the current advisory"
}

Write-Host ""
Write-Host " Devleck - PHP Inventory & Risk Scan" -ForegroundColor White
Write-Host " $((Get-Location).Path)"

# 1. Declared versions
Sec "1 - DECLARED PHP VERSIONS (what the repo says - not necessarily what runs)"
$found = $false
if (Test-Path composer.json) { Select-String -Path composer.json -Pattern '"php"\s*:' | ForEach-Object { Write-Host "  composer.json: $($_.Line.Trim())" }; $found = $true }
foreach ($f in '.php-version', '.tool-versions', 'runtime.txt') {
    if (Test-Path $f) { Select-String -Path $f -Pattern 'php' | ForEach-Object { Write-Host "  ${f}: $($_.Line.Trim())" }; $found = $true }
}
$dk = Get-ChildItem -Recurse -File -Depth 4 -Include 'Dockerfile*', 'docker-compose*.y*ml', '*.dockerfile' | Where-Object { $_.FullName -notmatch $Excl }
foreach ($f in $dk) {
    Select-String -Path $f.FullName -Pattern '^\s*(FROM|image:).*php|serversideup|wordpress' | Select-Object -First 4 | ForEach-Object { Write-Host "  $($f.Name): $($_.Line.Trim())"; $found = $true }
}
if (-not $found) { Ylw "no PHP version declarations found (not a PHP project, or declared elsewhere)" }
Ylw "Floating tags (php:8.3-apache) hide the real build - resolve the digest you deploy."
if ($dk -and (Select-String -Path $dk.FullName -Pattern 'FROM\s+php:[0-9.]+-apache' -Quiet)) {
    Ylw "!  *-apache images run mod_php - the SAPI reported at highest risk. Prefer php-fpm + nginx."
    $script:Findings++
}

# 2. php binary on PATH
Sec "2 - php BINARY ON PATH (CLI - may differ from the web-serving runtime)"
$php = Get-Command php -ErrorAction SilentlyContinue
if ($php) {
    $v = & php -r 'echo PHP_VERSION;' 2>$null
    $sapi = & php -r 'echo PHP_SAPI;' 2>$null
    Write-Host "  version: $v   sapi: $sapi"
    Assess $v
    Write-Host ""
    foreach ($k in 'session.upload_progress.enabled', 'memory_limit', 'display_errors', 'expose_php', 'allow_url_include', 'allow_url_fopen', 'file_uploads', 'post_max_size', 'upload_max_filesize', 'max_file_uploads', 'disable_functions', 'open_basedir', 'session.use_strict_mode', 'session.cookie_httponly', 'session.cookie_secure') {
        $val = & php -r "echo ini_get('$k') === false ? '(unset)' : (ini_get('$k') === '' ? '(empty)' : ini_get('$k'));" 2>$null
        '  {0,-34} {1}' -f $k, $val
    }
    Ylw "These are CLI values. Read the web SAPI's values from a request-time context you control."
} else {
    Ylw "no php binary on PATH - version not assessed (check the running container/host instead)"
}

# 3. Code patterns
Sec "3 - PHP RISK PATTERNS  (review each - many are legitimate)"
$phpFiles = Get-ChildItem -Recurse -File -Include *.php, *.phtml, *.inc | Where-Object { $_.FullName -notmatch $Excl }
function PScan([string]$label, [string]$regex) {
    if (-not $phpFiles) { return }
    $hits = $phpFiles | Select-String -Pattern $regex | Select-Object -First 5
    if ($hits) {
        Ylw "!  $label"
        $hits | ForEach-Object { $l = "$($_.Path):$($_.LineNumber): $($_.Line.Trim())"; "     " + $l.Substring(0, [Math]::Min(160, $l.Length)) }
    }
}
PScan 'unserialize() - deserialization of possibly untrusted data' 'unserialize\s*\('
PScan 'include/require with a variable path'                       '(include|require)(_once)?\s*\(?\s*\$'
PScan 'eval / assert-with-string / create_function'                '\b(eval|create_function)\s*\(|assert\s*\(\s*\$'
PScan 'command execution functions'                                '\b(exec|shell_exec|system|passthru|popen|proc_open|pcntl_exec)\s*\('
PScan 'phpinfo() present'                                          '\bphpinfo\s*\('
PScan 'request data in file functions'                             '(file_get_contents|readfile|fopen|file|unlink|copy)\s*\(\s*\$_(GET|POST|REQUEST|COOKIE)'
PScan 'extract() on request data / variable-variables'             'extract\s*\(\s*\$_(GET|POST|REQUEST)|\$\$[A-Za-z_]'
PScan 'string-built SQL'                                           '(mysqli_query|->query|->exec|DB::select|whereRaw|DB::raw)\s*\([^)]*(\$_(GET|POST|REQUEST)|"[^"]*\$[A-Za-z_]|\.\s*\$)'
PScan 'weak hashing of secrets'                                    '\b(md5|sha1)\s*\([^)]*(pass|pwd|secret|token)'
PScan 'non-crypto randomness for tokens'                           '\b(rand|mt_rand|uniqid|lcg_value)\s*\([^)]*\)[^;]*(token|secret|key|nonce|otp|password)'
PScan 'TLS verification disabled'                                  'CURLOPT_SSL_VERIFY(PEER|HOST)\s*,\s*(0|false)'
PScan 'unvalidated redirect'                                       'header\s*\(\s*["'']Location:[^)]*\$_(GET|POST|REQUEST)'

# 4. Configuration
Sec "4 - CONFIGURATION"
if ((Test-Path .env) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    git ls-files --error-unmatch .env 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Red "P0 - .env is tracked in git"; $script:Findings++ }
}
foreach ($pf in '.env.production', '.env.prod') {
    if ((Test-Path $pf) -and (Select-String -Path $pf -Pattern 'APP_DEBUG\s*=\s*true' -Quiet)) { Red "P0 - APP_DEBUG=true in $pf"; $script:Findings++ }
}
if ((Test-Path composer.json) -and -not (Test-Path composer.lock)) { Ylw "!  composer.json without composer.lock - builds are not reproducible" }
foreach ($p in 'phpinfo.php', 'info.php', 'test.php', 'adminer.php') {
    if ((Test-Path $p) -or (Test-Path "public/$p")) { Red "P1 - $p present in the tree (dev/diagnostic script)"; $script:Findings++ }
}
if ((Test-Path wp-config.php) -or (Test-Path public/wp-config.php) -or (Test-Path wp-content)) {
    Ylw "!  WordPress detected - confirm DISALLOW_FILE_EDIT, plugin hygiene and no inactive plugins (references/php-ecosystem.md)"
}
Ylw "Run 'composer audit' yourself - it contacts the package index, so this script does not."

Write-Host ""
Write-Host "------------------------------------------" -ForegroundColor DarkGray
if ($script:Findings -gt 0) {
    Red "$($script:Findings) high-severity item(s). Confirm each; patching is the only complete fix"
    Red "for the runtime flaws. If exposed and unpatched, assume compromise: rotate and hunt."
    exit 1
}
Grn "No high-severity PHP items matched."
Write-Host "This is triage, not assurance. Verify the SERVING runtime, and run composer audit." -ForegroundColor DarkGray
exit 0
