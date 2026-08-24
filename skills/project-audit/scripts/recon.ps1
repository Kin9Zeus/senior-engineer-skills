#Requires -Version 5.1
<#
.SYNOPSIS
  Devleck Senior Engineer Skills - read-only project reconnaissance (Windows).

.DESCRIPTION
  Prints a structured Ground Truth summary. Makes no network calls, installs
  nothing, writes nothing outside the console, and modifies no file.

.PARAMETER Path
  Project root. Defaults to the current directory.

.EXAMPLE
  ./recon.ps1
  ./recon.ps1 -Path C:\src\my-app
#>
param([string]$Path = ".")

$ErrorActionPreference = "SilentlyContinue"
try { Set-Location -Path $Path -ErrorAction Stop } catch { Write-Error "recon: cannot enter '$Path'"; exit 1 }

$Excludes = @('node_modules', '.git', 'dist', 'build', 'vendor', '.next', 'target', '__pycache__', '.venv', 'venv', 'coverage')

function Test-Excluded([string]$p) {
    foreach ($e in $Excludes) { if ($p -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $e + [IO.Path]::DirectorySeparatorChar) -or $p -match "[\\/]$([regex]::Escape($e))[\\/]") { return $true } }
    return $false
}
function Get-ProjectFiles { Get-ChildItem -Recurse -File -Force | Where-Object { -not (Test-Excluded $_.FullName) } }
function Section([string]$t) { Write-Host ""; Write-Host ("-" * 58) -ForegroundColor DarkGray; Write-Host $t -ForegroundColor White }
function Ok([string]$m)   { Write-Host "  [ok]   $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "  [warn] $m" -ForegroundColor Yellow }
function Bad([string]$m)  { Write-Host "  [P0]   $m" -ForegroundColor Red }
function Have([string]$c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }

Write-Host " Devleck - Project Reconnaissance " -ForegroundColor Black -BackgroundColor Yellow
Write-Host " $((Get-Location).Path)"
Write-Host " $([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"

# --- Repository --------------------------------------------------------------
Section "REPOSITORY"
if ((Test-Path .git) -and (Have git)) {
    "branch        : " + (git rev-parse --abbrev-ref HEAD 2>$null)
    "commit        : " + (git rev-parse --short HEAD 2>$null)
    "last commit   : " + (git log -1 --format=%cd --date=short 2>$null)
    "commits       : " + (git rev-list --count HEAD 2>$null)
    "tracked files : " + (@(git ls-files 2>$null).Count)
    "contributors  :"
    git log --format='%an' 2>$null | Group-Object | Sort-Object Count -Descending |
        Select-Object -First 5 | ForEach-Object { "                {0,5}  {1}" -f $_.Count, $_.Name }
    "uncommitted   : " + (@(git status --porcelain 2>$null).Count) + " file(s)"
} else { "not a git repository (or git unavailable)" }

# --- Languages ---------------------------------------------------------------
Section "LANGUAGE MIX (top 12 extensions)"
Get-ProjectFiles | Where-Object { $_.Extension } | Group-Object Extension |
    Sort-Object Count -Descending | Select-Object -First 12 |
    ForEach-Object { "{0,8}  {1}" -f $_.Count, $_.Name }

# --- Stack -------------------------------------------------------------------
Section "STACK DETECTED"
$stack = [ordered]@{
    'package.json' = 'Node / JavaScript / TypeScript'
    'next.config.js' = 'Next.js'; 'next.config.mjs' = 'Next.js'; 'next.config.ts' = 'Next.js'
    'nuxt.config.ts' = 'Nuxt'; 'vite.config.ts' = 'Vite'; 'vite.config.js' = 'Vite'
    'angular.json' = 'Angular'; 'svelte.config.js' = 'Svelte'
    'requirements.txt' = 'Python'; 'pyproject.toml' = 'Python'; 'manage.py' = 'Django'
    'go.mod' = 'Go'; 'Cargo.toml' = 'Rust'
    'composer.json' = 'PHP'; 'artisan' = 'Laravel'
    'Gemfile' = 'Ruby'; 'config/application.rb' = 'Rails'
    'pom.xml' = 'Java / Maven'; 'build.gradle' = 'Java / Gradle'; 'build.gradle.kts' = 'Kotlin / Gradle'
    'pubspec.yaml' = 'Dart / Flutter'; 'Package.swift' = 'Swift'; 'mix.exs' = 'Elixir'
}
foreach ($k in $stack.Keys) { if (Test-Path $k) { "  {0,-22} {1}" -f $k, $stack[$k] } }
if (Get-ChildItem -Filter *.csproj, *.sln -ErrorAction SilentlyContinue) { "  {0,-22} {1}" -f '*.csproj/*.sln', '.NET' }

Write-Host "`n  lockfiles:"
$locks = @('package-lock.json','yarn.lock','pnpm-lock.yaml','bun.lockb','poetry.lock','Pipfile.lock','uv.lock','go.sum','Cargo.lock','Gemfile.lock','composer.lock')
$foundLock = $false
foreach ($l in $locks) { if (Test-Path $l) { Ok $l; $foundLock = $true } }
if ((Test-Path package.json) -and -not $foundLock) { Warn "package.json with NO lockfile - builds are not reproducible" }

if ((Test-Path package.json)) {
    try {
        $pkg = Get-Content package.json -Raw | ConvertFrom-Json
        Write-Host ""
        "  name        : " + $pkg.name
        "  version     : " + $pkg.version
        "  node engine : " + $(if ($pkg.engines.node) { $pkg.engines.node } else { "UNPINNED" })
        "  deps        : {0} prod / {1} dev" -f @($pkg.dependencies.PSObject.Properties).Count, @($pkg.devDependencies.PSObject.Properties).Count
        "  scripts     : " + (@($pkg.scripts.PSObject.Properties.Name) -join ", ")
    } catch {}
}

# --- Delivery ----------------------------------------------------------------
Section "BUILD / DEPLOY / INFRA"
$found = $false
foreach ($f in @('.github/workflows','.gitlab-ci.yml','.circleci','Jenkinsfile','azure-pipelines.yml','bitbucket-pipelines.yml',
                 'Dockerfile','docker-compose.yml','docker-compose.yaml','Procfile','vercel.json','netlify.toml','fly.toml',
                 'render.yaml','app.yaml','serverless.yml','Makefile','Taskfile.yml','justfile',
                 'terraform','infra','infrastructure','k8s','kubernetes','helm','charts','ansible','pulumi','.devcontainer')) {
    if (Test-Path $f) { Ok $f; $found = $true }
}
if (Test-Path .github/workflows) {
    Write-Host "  workflows:"
    Get-ChildItem .github/workflows -File | ForEach-Object { "    " + $_.Name }
}
if (-not $found) { Warn "no CI, container or IaC configuration found - deploys are likely manual" }

# --- State -------------------------------------------------------------------
Section "STATE LAYER"
foreach ($f in @('prisma/schema.prisma','schema.sql','db/schema.rb','drizzle.config.ts','knexfile.js','alembic.ini')) {
    if (Test-Path $f) { Ok $f }
}
$migs = Get-ChildItem -Recurse -Directory -Force |
    Where-Object { $_.Name -in @('migrations','migrate','migration') -and -not (Test-Excluded $_.FullName) } |
    Select-Object -First 5
if ($migs) {
    foreach ($m in $migs) {
        $n = @(Get-ChildItem $m.FullName -File).Count
        "  [ok]   {0,-45} {1} file(s)" -f $m.FullName.Replace((Get-Location).Path, '.'), $n
    }
} else { Warn "no migrations directory found" }

Write-Host "  engines referenced in config:"
$cfg = Get-ProjectFiles | Where-Object { $_.Extension -in '.yml','.yaml','.toml','.json' -or $_.Name -like '*.env.example' }
$engines = $cfg | Select-String -Pattern 'postgres(ql)?|mysql|mariadb|sqlite|mongodb|redis|dynamodb|clickhouse|cassandra|elasticsearch|rabbitmq|kafka' -AllMatches |
    ForEach-Object { $_.Matches.Value.ToLower() } | Sort-Object -Unique | Select-Object -First 12
$engines | ForEach-Object { "    $_" }

# --- Tests -------------------------------------------------------------------
Section "TESTS"
$td = Get-ChildItem -Recurse -Directory -Force |
    Where-Object { $_.Name -in @('test','tests','__tests__','spec','e2e') -and -not (Test-Excluded $_.FullName) } |
    Select-Object -First 8
if ($td) { $td | ForEach-Object { Ok $_.FullName.Replace((Get-Location).Path, '.') } } else { Warn "no test directory found" }
$tf = @(Get-ProjectFiles | Select-String -Pattern '\b(it|test|describe)\(|def test_|func Test[A-Z]|\[Test\]|@Test' -List).Count
"  files containing tests : $tf"
foreach ($f in @('jest.config.js','vitest.config.ts','playwright.config.ts','cypress.config.js','pytest.ini','tox.ini','phpunit.xml','.rspec')) {
    if (Test-Path $f) { Ok $f }
}
if (Test-Path .github/workflows) {
    $ciTests = Get-ChildItem .github/workflows -File | Select-String -Pattern '(npm|yarn|pnpm) (run )?test|pytest|go test|cargo test|mvn test|phpunit|rspec' -List
    if ($ciTests) { "  CI runs tests          : yes" } else { Warn "CI runs tests          : NOT DETECTED" }
}

# --- Quality gates -----------------------------------------------------------
Section "QUALITY GATES"
foreach ($f in @('tsconfig.json','.eslintrc','.eslintrc.js','.eslintrc.json','eslint.config.js','eslint.config.mjs',
                 '.prettierrc','biome.json','ruff.toml','.ruff.toml','mypy.ini','.golangci.yml','.golangci.yaml',
                 '.editorconfig','.pre-commit-config.yaml','lefthook.yml','.husky','sonar-project.properties')) {
    if (Test-Path $f) { Ok $f }
}
if (Test-Path tsconfig.json) {
    if ((Get-Content tsconfig.json -Raw) -match '"strict"\s*:\s*true') { "  TypeScript strict      : true" }
    else { Warn "TypeScript strict      : FALSE or unset" }
}

# --- Risk signals ------------------------------------------------------------
Section "RISK SIGNALS  (indicative only - confirm each by reading the code)"
if ((Test-Path .git) -and (Have git)) {
    $envTracked = git ls-files 2>$null | Where-Object { $_ -match '(^|/)\.env($|\.)' -and $_ -notmatch 'example' }
    if ($envTracked) { Bad ".env file(s) tracked in git:"; $envTracked | Select-Object -First 5 | ForEach-Object { "        $_" } }
    else { Ok "no .env tracked in the working tree" }

    $hist = git log --all --full-history --name-only --pretty=format: -- '*.env' '*.pem' '*.key' '*.p12' '*.pfx' 2>$null |
        Where-Object { $_ -and $_ -notmatch 'example' } | Sort-Object -Unique | Select-Object -First 5
    if ($hist) { Bad "secret-shaped files in git HISTORY (rotate, then purge):"; $hist | ForEach-Object { "        $_" } }
}

$keyPattern = 'sk_live_[0-9a-zA-Z]{10,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[0-9A-Za-z-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----'
$keys = Get-ProjectFiles | Select-String -Pattern $keyPattern -List | Select-Object -First 8
if ($keys) { Bad "live-key patterns found in:"; $keys | ForEach-Object { "        " + $_.Path.Replace((Get-Location).Path, '.') } }
else { Ok "no live-key patterns matched" }

$sqli = Get-ProjectFiles | Select-String -Pattern '(query|execute|exec|raw|prepare)\s*\(\s*["`''][^"`'']*(\$\{|"\s*\+|%s|f["''])' -List | Select-Object -First 8
if ($sqli) { Warn "string-built query candidates:"; $sqli | ForEach-Object { "        " + $_.Path.Replace((Get-Location).Path, '.') } }

$xss = Get-ProjectFiles | Select-String -Pattern 'dangerouslySetInnerHTML|v-html|\.innerHTML\s*=|html_safe|\|\s*safe' -List | Select-Object -First 8
if ($xss) { Warn "raw-HTML sinks:"; $xss | ForEach-Object { "        " + $_.Path.Replace((Get-Location).Path, '.') } }

$cmd = Get-ProjectFiles | Select-String -Pattern 'child_process|execSync|os\.system|subprocess\.(call|run|Popen)|shell_exec' -List | Select-Object -First 5
if ($cmd) { Warn "command-execution sites:"; $cmd | ForEach-Object { "        " + $_.Path.Replace((Get-Location).Path, '.') } }

$all  = @(Get-ProjectFiles | Select-String -Pattern 'TODO|FIXME|HACK|XXX').Count
$crit = @(Get-ProjectFiles | Where-Object { $_.Name -match 'auth|login|payment|billing|admin|permission' } |
          Select-String -Pattern 'TODO|FIXME|HACK|XXX').Count
Write-Host ""
"  debt markers           : $all total, $crit in auth/payment/admin paths"

# --- Third parties -----------------------------------------------------------
Section "THIRD PARTIES  (cross-check every one against the privacy policy)"
$tp = Get-ProjectFiles | Select-String -Pattern 'googletagmanager\.com|google-analytics\.com|gtag\(|connect\.facebook\.net|static\.hotjar\.com|cdn\.segment\.com|api\.mixpanel\.com|posthog|widget\.intercom|clarity\.ms|sentry\.io|fonts\.googleapis\.com|js\.stripe\.com|paypal\.com/sdk|player\.vimeo|youtube\.com/embed|recaptcha' -AllMatches |
    ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | Select-Object -First 20
if ($tp) { $tp | ForEach-Object { "  . $_" } } else { "  none detected in source" }

# --- Public promises ---------------------------------------------------------
Section "PUBLIC PROMISES"
Get-ChildItem -Recurse -File -Force -Depth 4 |
    Where-Object { -not (Test-Excluded $_.FullName) -and $_.Name -match 'privacy|terms|cookie|^robots\.txt$|^sitemap|404|llms\.txt|security\.txt|^README|^LICENSE|^CONTRIBUTING|^SECURITY|^CHANGELOG' } |
    Select-Object -First 16 | ForEach-Object { Ok $_.FullName.Replace((Get-Location).Path, '.') }

Write-Host ""
Write-Host ("-" * 58) -ForegroundColor DarkGray
Write-Host "Read-only reconnaissance complete. Every flag above is a lead, not a" -ForegroundColor DarkGray
Write-Host "finding - confirm each by reading the code before it enters a report." -ForegroundColor DarkGray
