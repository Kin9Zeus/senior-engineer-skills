#Requires -Version 5.1
<#
.SYNOPSIS
  Devleck Senior Engineer Skills - live web presence check (Windows).

.DESCRIPTION
  Fetches a URL and reports on the crawlable / legible / structured / trusted
  layers. Read-only: a handful of GET and HEAD requests, no crawling, no
  scanning, no load.

  Only run this against a site you own or are authorised to assess.

.PARAMETER Url
  The page to check. https:// is assumed if no scheme is given.

.EXAMPLE
  ./web-check.ps1 https://example.com

.OUTPUTS
  Exit code 0 = no failures, 1 = failures found, 2 = usage error.
#>
param([Parameter(Mandatory = $true, Position = 0)][string]$Url)

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"
if ($Url -notmatch '^https?://') { $Url = "https://$Url" }
try { $uri = [Uri]$Url } catch { Write-Error "Invalid URL"; exit 2 }
$Base = "$($uri.Scheme)://$($uri.Authority)"
$UA = 'Mozilla/5.0 (compatible; DevleckWebCheck/1.0; +https://github.com/Kin9Zeus/senior-engineer-skills)'

$script:Fail = 0; $script:Warn = 0
function Section([string]$t) { Write-Host ""; Write-Host $t -ForegroundColor White; Write-Host ("-" * 46) -ForegroundColor DarkGray }
function Ok([string]$m)   { Write-Host "  [ok]   $m" -ForegroundColor Green }
function Bad([string]$m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:Fail++ }
function Warn2([string]$m){ Write-Host "  [warn] $m" -ForegroundColor Yellow; $script:Warn++ }
function Info([string]$m) { Write-Host "         $m" -ForegroundColor DarkGray }

function Get-Page([string]$u) {
    try { Invoke-WebRequest -Uri $u -UserAgent $UA -MaximumRedirection 5 -TimeoutSec 25 -ErrorAction Stop }
    catch { $_.Exception.Response }
}
function Get-Status([string]$u) {
    try { (Invoke-WebRequest -Uri $u -UserAgent $UA -MaximumRedirection 5 -TimeoutSec 20 -ErrorAction Stop).StatusCode }
    catch { if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 } }
}
function Hdr([object]$r, [string]$n) {
    if ($r.Headers -and $r.Headers[$n]) { ($r.Headers[$n] | Select-Object -First 1) } else { $null }
}
function MetaContent([string]$html, [string]$key) {
    $m = [regex]::Match($html, "<meta[^>]+(?:name|property)\s*=\s*[""']$([regex]::Escape($key))[""'][^>]*>", 'IgnoreCase')
    if (-not $m.Success) { return $null }
    $c = [regex]::Match($m.Value, "content\s*=\s*[""']([^""']*)[""']", 'IgnoreCase')
    if ($c.Success) { $c.Groups[1].Value } else { $null }
}

Write-Host " Devleck - Web Presence Check " -ForegroundColor Black -BackgroundColor Yellow
Write-Host " $Url"

$sw = [Diagnostics.Stopwatch]::StartNew()
$resp = Get-Page $Url
$sw.Stop()
if (-not $resp -or -not $resp.Content) { Write-Error "Could not fetch $Url"; exit 1 }
$html = $resp.Content

# --- 1 Transport -------------------------------------------------------------
Section "1 . TRANSPORT & RESPONSE"
if ($resp.StatusCode -eq 200) { Ok "200 OK" } else { Warn2 "status $($resp.StatusCode)" }
if ($uri.Scheme -eq 'https') { Ok "HTTPS" } else { Bad "not served over HTTPS" }
$sizeKb = [math]::Round($html.Length / 1024, 1)
Info "response in $($sw.ElapsedMilliseconds)ms . HTML ${sizeKb}KB"
if ($sw.ElapsedMilliseconds -gt 1200) { Warn2 "slow response - check server, CDN and render-path queries" }

# --- 2 Security headers ------------------------------------------------------
Section "2 . SECURITY HEADERS"
foreach ($h in @('Strict-Transport-Security', 'X-Content-Type-Options', 'Referrer-Policy')) {
    $v = Hdr $resp $h
    if ($v) { Ok "${h}: $v" } else { Warn2 "$h missing" }
}
$csp = Hdr $resp 'Content-Security-Policy'
if ($csp) {
    if ($csp -match 'unsafe-inline') { Bad "CSP present but contains 'unsafe-inline' - this provides little XSS protection" }
    else { Ok "CSP present without unsafe-inline" }
} else { Warn2 "Content-Security-Policy missing" }
if (-not (Hdr $resp 'X-Frame-Options') -and ($csp -notmatch 'frame-ancestors')) {
    Warn2 "no clickjacking protection (frame-ancestors or X-Frame-Options)"
}
foreach ($h in @('X-Powered-By', 'Server')) {
    $v = Hdr $resp $h
    if ($v -and $v -match '\d+\.\d+') { Warn2 "$h discloses a version: $v" }
}

# --- 3 Crawlability ----------------------------------------------------------
Section "3 . CRAWLABILITY"
$rb = Get-Page "$Base/robots.txt"
if ($rb -and $rb.StatusCode -eq 200) {
    Ok "robots.txt present"
    if ($rb.Content -match '(?im)^\s*Disallow:\s*/\s*$') { Bad "robots.txt contains 'Disallow: /' - THE SITE IS BLOCKED FROM CRAWLING" }
    if ($rb.Content -match '(?im)^\s*Sitemap:') { Ok "robots.txt references a sitemap" } else { Warn2 "robots.txt has no Sitemap: line" }
} else { Warn2 "no robots.txt" }

$sm = Get-Page "$Base/sitemap.xml"
if ($sm -and $sm.StatusCode -eq 200) {
    $n = ([regex]::Matches($sm.Content, '<loc>', 'IgnoreCase')).Count
    Ok "sitemap.xml present ($n <loc> entries)"
} else { Warn2 "no sitemap.xml at the root" }

$nf = Get-Status "$Base/devleck-check-404-$PID"
switch ($nf) {
    { $_ -in 404, 410 } { Ok "missing pages return $nf" }
    200 { Bad "missing page returns 200 - SOFT 404. Every mistyped URL becomes an indexable page" }
    default { Warn2 "missing page returns $nf" }
}
$robotsMeta = MetaContent $html 'robots'
if ($robotsMeta -match 'noindex') { Bad "this page is set to noindex: $robotsMeta" }
elseif ($robotsMeta) { Info "meta robots: $robotsMeta" }
else { Ok "no meta robots restriction" }

# --- 4 On-page metadata ------------------------------------------------------
Section "4 . ON-PAGE METADATA"
$t = [regex]::Match($html, '<title[^>]*>([^<]*)</title>', 'IgnoreCase')
if ($t.Success -and $t.Groups[1].Value.Trim()) {
    $title = $t.Groups[1].Value.Trim(); $L = $title.Length
    if ($L -lt 20)      { Warn2 "title very short ($L chars): $title" }
    elseif ($L -gt 65)  { Warn2 "title will truncate ($L chars): $title" }
    else                { Ok "title ($L chars): $title" }
} else { Bad "no <title>" }

$desc = MetaContent $html 'description'
if ($desc) {
    $L = $desc.Length
    if ($L -lt 70)      { Warn2 "meta description short ($L chars)" }
    elseif ($L -gt 170) { Warn2 "meta description will truncate ($L chars)" }
    else                { Ok "meta description ($L chars)" }
    Info $desc.Substring(0, [Math]::Min(100, $desc.Length))
} else { Bad "no meta description - the engine will write one for you, usually badly" }

$c = [regex]::Match($html, '<link[^>]+rel\s*=\s*["'']canonical["''][^>]*>', 'IgnoreCase')
if ($c.Success) {
    $href = [regex]::Match($c.Value, 'href\s*=\s*["'']([^"'']*)["'']', 'IgnoreCase').Groups[1].Value
    Ok "canonical: $href"
    if ($href -notmatch '^https?://') { Warn2 "canonical is relative - should be absolute" }
    if ($href -eq "$Base/" -and $Url -ne "$Base/" -and $Url -ne $Base) { Bad "canonical points at the homepage from a non-homepage - this de-indexes the page" }
} else { Warn2 "no canonical link" }

$h1 = ([regex]::Matches($html, '<h1[^>]*>', 'IgnoreCase')).Count
switch ($h1) {
    1 { Ok "exactly one <h1>" }
    0 { Bad "no <h1>" }
    default { Warn2 "$h1 <h1> elements - there should be exactly one" }
}
$lang = [regex]::Match($html, '<html[^>]+lang\s*=\s*["'']([^"'']*)["'']', 'IgnoreCase')
if ($lang.Success) { Ok "html lang=""$($lang.Groups[1].Value)""" } else { Warn2 "no lang attribute on <html>" }

# --- 5 Social ----------------------------------------------------------------
Section "5 . SOCIAL SHARING"
foreach ($p in @('og:title', 'og:description', 'og:url', 'og:type')) {
    if (MetaContent $html $p) { Ok $p } else { Warn2 "$p missing" }
}
$ogi = MetaContent $html 'og:image'
if ($ogi) {
    if ($ogi -match '^https?://') {
        $ic = Get-Status $ogi
        if ($ic -eq 200) { Ok "og:image reachable" } else { Bad "og:image returns $ic - the share preview will be blank" }
    } else { Bad "og:image is a relative URL - it will be ignored. Must be absolute" }
    if (-not (MetaContent $html 'og:image:width')) { Warn2 "og:image:width/height not declared (target 1200x630)" }
} else { Bad "og:image missing - shared links will look broken" }
if (MetaContent $html 'twitter:card') { Ok "twitter:card" } else { Warn2 "twitter:card missing" }

# --- 6 Structured data -------------------------------------------------------
Section "6 . STRUCTURED DATA"
$blocks = [regex]::Matches($html, '<script[^>]*application/ld\+json[^>]*>(.*?)</script>', 'IgnoreCase, Singleline')
if ($blocks.Count -gt 0) {
    Ok "$($blocks.Count) JSON-LD block(s)"
    $bad = 0; $i = 0
    foreach ($b in $blocks) {
        $i++
        try { $b.Groups[1].Value | ConvertFrom-Json | Out-Null }
        catch { Bad "JSON-LD block $i is not valid JSON"; $bad++ }
    }
    if ($bad -eq 0) { Ok "all JSON-LD blocks parse as valid JSON" }
    $types = [regex]::Matches($html, '"@type"\s*:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    Info "types: $($types -join ', ')"
    if ($types -notcontains 'Organization') { Warn2 "no Organization schema" }
    if ($types -notcontains 'WebSite')      { Warn2 "no WebSite schema" }
    if ($types -match 'LocalBusiness|Store|Restaurant|ProfessionalService|Dentist|LawFirm') { Ok "LocalBusiness-family schema present" }
    else { Info "no LocalBusiness schema - required for map/local-pack results if there is a physical location" }
} else { Warn2 "no JSON-LD structured data" }

# --- 7 Images and a11y signals ----------------------------------------------
Section "7 . IMAGES & ACCESSIBILITY SIGNALS"
$imgs = [regex]::Matches($html, '<img[^>]*>', 'IgnoreCase')
if ($imgs.Count -gt 0) {
    $noAlt = ($imgs | Where-Object { $_.Value -notmatch 'alt\s*=' }).Count
    $noDim = ($imgs | Where-Object { $_.Value -notmatch 'width\s*=' }).Count
    if ($noAlt -eq 0) { Ok "$($imgs.Count) <img>, all have an alt attribute" }
    else { Bad "$noAlt of $($imgs.Count) <img> have no alt - screen readers will announce the filename" }
    if ($noDim -eq 0) { Ok "all <img> declare width" }
    else { Warn2 "$noDim of $($imgs.Count) <img> lack width/height - causes layout shift (CLS)" }
    if ($html -match 'loading\s*=\s*["'']lazy') { Info "lazy loading in use - verify the LCP/hero image is NOT lazy-loaded" }
} else { Info "no <img> tags in the server response (may be client-rendered)" }

if ($html -match '<(main|nav|header|footer|article|section)\b') { Ok "semantic landmarks present" } else { Warn2 "no semantic landmark elements" }
if ($html -match 'skip[- ]?to[- ]?(main|content)') { Ok "skip link present" } else { Warn2 "no skip-to-content link" }
$vp = MetaContent $html 'viewport'
if ($vp) {
    if ($vp -match 'user-scalable\s*=\s*no|maximum-scale\s*=\s*1') { Bad "viewport blocks zoom - a WCAG failure: $vp" }
    else { Ok "viewport: $vp" }
} else { Warn2 "no viewport meta - the page will not be mobile-responsive" }

# --- 8 Trust surface ---------------------------------------------------------
Section "8 . TRUST SURFACE"
$probes = @(
    @{ Path = '/privacy';                    Label = 'Privacy policy';   Severe = $true  },
    @{ Path = '/terms';                      Label = 'Terms of service'; Severe = $false },
    @{ Path = '/contact';                    Label = 'Contact page';     Severe = $false },
    @{ Path = '/faq';                        Label = 'FAQ page';         Severe = $false },
    @{ Path = '/.well-known/security.txt';   Label = 'security.txt';     Severe = $false }
)
foreach ($p in $probes) {
    $s = Get-Status "$Base$($p.Path)"
    if ($s -eq 200) { Ok "$($p.Label)  ($($p.Path))" }
    elseif ($p.Severe) { Bad "$($p.Label) not found at $($p.Path) ($s)" }
    else { Warn2 "$($p.Label) not found at $($p.Path) ($s)" }
}
if ($html -match 'cookie') { Info "the word 'cookie' appears - verify the banner GATES scripts before consent, and that rejecting is as easy as accepting" }
$tp = [regex]::Matches($html, 'googletagmanager|google-analytics|gtag\(|connect\.facebook\.net|hotjar|segment\.com|mixpanel|posthog|clarity\.ms|intercom') |
      ForEach-Object { $_.Value } | Sort-Object -Unique
foreach ($t in $tp) { Info "third party: $t  -> must appear in the privacy policy" }

# --- Summary -----------------------------------------------------------------
Write-Host ""; Write-Host ("-" * 46) -ForegroundColor DarkGray
Write-Host " $($script:Fail) failing" -ForegroundColor Red -NoNewline
Write-Host " . " -NoNewline
Write-Host "$($script:Warn) warnings" -ForegroundColor Yellow
Write-Host "This checks one URL. A full audit checks every template, confirms each" -ForegroundColor DarkGray
Write-Host "finding by hand, and includes accessibility and performance testing that" -ForegroundColor DarkGray
Write-Host "no HTTP check can perform." -ForegroundColor DarkGray
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
