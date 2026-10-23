# Devleck Senior Engineer Skills - secret rotation inventory (names only).
#
# Lists the environment-variable NAMES a repository reads or defines, grouped by
# how sensitive the name sounds, so you can build a rotation worksheet fast after
# a provider breach or a leak. It NEVER prints a value, makes no network calls
# and modifies nothing.
#
# It cannot see secrets that live only in a provider dashboard, a CI variable
# store or a developer's shell - ask the user for those. Everything it lists is a
# lead for a worksheet, not a finding.
#
# Usage:  .\rotation-inventory.ps1 [-Path .]
# Exit:   0 no secret-named variables found | 1 some found | 2 usage error
#
# Requires PowerShell 5.1+.

param([string]$Path = '.')

$ErrorActionPreference = 'SilentlyContinue'
if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Host "rotation-inventory: cannot enter '$Path'" -ForegroundColor Red
    exit 2
}
Set-Location -LiteralPath $Path

$ExcludeDirs = '\\(node_modules|\.git|dist|build|vendor|\.next|target|coverage|__pycache__|\.venv|venv)(\\|$)'
$Sens = '(SECRET|PASSWORD|PASSWD|TOKEN|PRIVATE|CREDENTIAL|API_?KEY|ACCESS_?KEY|SIGNING|ENCRYPTION|SALT|DSN|WEBHOOK|CLIENT_SECRET|APP_KEY|MASTER_KEY|DATABASE_URL|REDIS_URL|MONGO(DB)?_URI|AMQP_URL|CONN(ECTION)?_?STRING)'

$rows = New-Object System.Collections.Generic.List[object]

Write-Host ""
Write-Host " Devleck - Rotation Inventory (names only)" -ForegroundColor White
Write-Host " $((Get-Location).Path)"

# 1. Names DEFINED in env-style files (left side only; the value is never read into output)
$envFiles = Get-ChildItem -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch $ExcludeDirs } |
    Where-Object { $_.Name -match '^\.env($|\.)|\.env$|^docker-compose.*\.ya?ml$|^(railway\.(json|toml)|app\.json|fly\.toml|render\.yaml|vercel\.json)$' }
foreach ($f in $envFiles) {
    foreach ($line in (Get-Content -LiteralPath $f.FullName)) {
        if ($line -match '^\s*(export\s+)?([A-Z][A-Z0-9_]{2,})\s*[=:]') {
            $rows.Add([pscustomobject]@{ Name = $Matches[2]; Where = $f.Name })
        }
    }
}

# 2. Names READ by code
$codeExt = '\.(js|ts|tsx|jsx|mjs|py|php|rb|go|java|cs|rs)$'
$codePat = 'process\.env\.([A-Z][A-Z0-9_]+)|process\.env\[["'']([A-Z][A-Z0-9_]+)|os\.environ(?:\.get)?[\(\[]["'']([A-Z][A-Z0-9_]+)|getenv\(["'']([A-Z][A-Z0-9_]+)|\$_ENV\[["'']([A-Z][A-Z0-9_]+)|\$_SERVER\[["'']([A-Z][A-Z0-9_]+)|\benv\(["'']([A-Z][A-Z0-9_]+)|ENV\[["'']([A-Z][A-Z0-9_]+)|GetEnvironmentVariable\(["'']([A-Z][A-Z0-9_]+)'
$codeFiles = Get-ChildItem -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch $ExcludeDirs -and $_.Name -match $codeExt }
foreach ($f in $codeFiles) {
    foreach ($m in (Select-String -LiteralPath $f.FullName -Pattern $codePat -AllMatches)) {
        foreach ($mm in $m.Matches) {
            $n = ($mm.Groups | Select-Object -Skip 1 | Where-Object { $_.Success } | Select-Object -First 1).Value
            if ($n -and $n -notmatch '^(NODE_ENV)$') { $rows.Add([pscustomobject]@{ Name = $n; Where = '(read in code)' }) }
        }
    }
}

# 3. GitHub Actions secrets
if (Test-Path '.github/workflows') {
    foreach ($m in (Select-String -Path '.github/workflows/*' -Pattern 'secrets\.([A-Za-z0-9_]+)' -AllMatches)) {
        foreach ($mm in $m.Matches) { $rows.Add([pscustomobject]@{ Name = $mm.Groups[1].Value; Where = '(GitHub Actions secret)' }) }
    }
}

if ($rows.Count -eq 0) {
    Write-Host "No environment variable names found in this tree." -ForegroundColor Green
    Write-Host "That does not mean there are no secrets - check the provider dashboard and CI." -ForegroundColor Yellow
    exit 0
}

$names = $rows | Select-Object -ExpandProperty Name -Unique | Sort-Object
$hi    = @($names | Where-Object { $_ -match $Sens })
$other = @($names | Where-Object { $_ -notmatch $Sens })

Write-Host ""
Write-Host "HIGH SENSITIVITY - rotate (and prove the old value dead)" -ForegroundColor White
if ($hi.Count) {
    foreach ($n in $hi) {
        $w = ($rows | Where-Object { $_.Name -eq $n } | Select-Object -ExpandProperty Where -Unique | Select-Object -First 3) -join ' '
        '  {0,-34} {1}' -f $n, $w
    }
} else { Write-Host "none matched the sensitive-name pattern" -ForegroundColor Green }

Write-Host ""
Write-Host "OTHER VARIABLES - review; a harmless-sounding name can hold a secret" -ForegroundColor White
if ($other.Count) { Write-Host ("  " + ($other -join ' ')) } else { Write-Host "  none" }

Write-Host ""
Write-Host "Names only. Not covered: provider dashboards, CI variable stores, laptops," -ForegroundColor Yellow
Write-Host "preview/staging copies, secrets baked into images. Ask the user for those." -ForegroundColor Yellow
Write-Host "Next: templates/rotation-tracker.md - one row per name, ordered by blast radius." -ForegroundColor Yellow

if ($hi.Count) { exit 1 } else { exit 0 }
