#!/usr/bin/env bash
# Devleck Senior Engineer Skills — live web presence check.
#
# Fetches a URL and reports on the crawlable / legible / structured / trusted
# layers. Read-only: a handful of GET and HEAD requests, no crawling, no
# scanning, no load.
#
# Only run this against a site you own or are authorised to assess.
#
# Usage:  ./web-check.sh https://example.com
# Deps:   curl (required), python3 (optional, for JSON-LD parsing)

set -uo pipefail

URL="${1:-}"
[ -z "$URL" ] && { echo "usage: $0 <url>" >&2; exit 2; }
case "$URL" in http://*|https://*) ;; *) URL="https://$URL" ;; esac
BASE="$(printf '%s' "$URL" | sed -E 's#(https?://[^/]+).*#\1#')"

UA='Mozilla/5.0 (compatible; DevleckWebCheck/1.0; +https://github.com/Kin9Zeus/senior-engineer-skills)'
CURL=(curl -sS --max-time 25 --compressed -A "$UA")

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; WARN=$((WARN+1)); }
info() { printf '    \033[2m%s\033[0m\n' "$*"; }
sec()  { printf '\n\033[1m%s\033[0m\n\033[2m%s\033[0m\n' "$1" "──────────────────────────────────────────────"; }
FAIL=0; WARN=0

printf '\033[1m Devleck · Web Presence Check \033[0m\n %s\n' "$URL"

HTML="$(mktemp)"; HDRS="$(mktemp)"
trap 'rm -f "$HTML" "$HDRS"' EXIT

CODE="$("${CURL[@]}" -o "$HTML" -D "$HDRS" -w '%{http_code}' -L "$URL" 2>/dev/null)"
[ -s "$HTML" ] || { echo "Could not fetch $URL (status $CODE)"; exit 1; }

meta() { grep -oiE "<meta[^>]+(name|property)=[\"']$1[\"'][^>]*>" "$HTML" | head -1 \
         | grep -oiE 'content=["'"'"'][^"'"'"']*' | sed -E 's/^content=["'"'"']//' ; }
hdr()  { grep -i "^$1:" "$HDRS" | tail -1 | cut -d' ' -f2- | tr -d '\r'; }

# ── 1 · Transport and response ────────────────────────────────────────────────
sec "1 · TRANSPORT & RESPONSE"
FINAL="$("${CURL[@]}" -o /dev/null -w '%{url_effective}' -L "$URL")"
HOPS="$("${CURL[@]}" -o /dev/null -w '%{num_redirects}' -L "$URL")"
[ "$CODE" = "200" ] && ok "200 OK" || warn "final status $CODE"
[ "$FINAL" != "$URL" ] && info "redirects to $FINAL"
[ "$HOPS" -le 1 ] && ok "$HOPS redirect hop(s)" || warn "$HOPS redirect hops — each is a round trip; collapse the chain"
case "$FINAL" in https://*) ok "HTTPS" ;; *) bad "not served over HTTPS" ;; esac

TTFB="$("${CURL[@]}" -o /dev/null -w '%{time_starttransfer}' "$FINAL")"
TOTAL="$("${CURL[@]}" -o /dev/null -w '%{time_total}' "$FINAL")"
SIZE="$(wc -c < "$HTML" | tr -d ' ')"
if [ "$SIZE" -ge 1024 ]; then HSIZE="$(( SIZE / 1024 ))KB"; else HSIZE="${SIZE}B"; fi
info "TTFB ${TTFB}s · total ${TOTAL}s · HTML ${HSIZE}  (timings from separate requests)"
awk -v t="$TTFB" 'BEGIN{ exit !(t > 0.8) }' && warn "TTFB above 0.8s — server, CDN or a query in the render path" || ok "TTFB within budget"

# ── 2 · Security headers ──────────────────────────────────────────────────────
sec "2 · SECURITY HEADERS"
check_hdr() { v="$(hdr "$1")"; [ -n "$v" ] && ok "$1: $(printf '%.68s' "$v")" || warn "$1 missing"; }
check_hdr "strict-transport-security"
check_hdr "x-content-type-options"
check_hdr "referrer-policy"
CSP="$(hdr content-security-policy)"
if [ -n "$CSP" ]; then
  case "$CSP" in
    *unsafe-inline*) bad "CSP present but contains 'unsafe-inline' — this provides little XSS protection" ;;
    *) ok "CSP present without unsafe-inline" ;;
  esac
else
  warn "Content-Security-Policy missing"
fi
[ -n "$(hdr x-frame-options)" ] || case "$CSP" in *frame-ancestors*) ;; *) warn "no clickjacking protection (frame-ancestors or X-Frame-Options)" ;; esac
for h in x-powered-by server; do
  v="$(hdr "$h")"
  case "$v" in
    *[0-9].[0-9]*) warn "$h discloses a version: $v" ;;
  esac
done

# ── 3 · Crawlability ──────────────────────────────────────────────────────────
sec "3 · CRAWLABILITY"
RB="$("${CURL[@]}" -w '\n%{http_code}' "$BASE/robots.txt" 2>/dev/null)"
RBC="$(printf '%s' "$RB" | tail -1)"; RBB="$(printf '%s' "$RB" | sed '$d')"
if [ "$RBC" = "200" ]; then
  ok "robots.txt present"
  printf '%s' "$RBB" | grep -qiE '^\s*Disallow:\s*/\s*$' && bad "robots.txt contains 'Disallow: /' — THE SITE IS BLOCKED FROM CRAWLING"
  printf '%s' "$RBB" | grep -qi '^\s*Sitemap:' && ok "robots.txt references a sitemap" || warn "robots.txt has no Sitemap: line"
else
  warn "no robots.txt (status $RBC)"
fi

SMC="$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$BASE/sitemap.xml")"
if [ "$SMC" = "200" ]; then
  N="$("${CURL[@]}" "$BASE/sitemap.xml" | grep -c '<loc>' || true)"
  ok "sitemap.xml present (${N} <loc> entries)"
else
  warn "no sitemap.xml at the root (status $SMC)"
fi

NF="$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$BASE/devleck-check-404-$$")"
case "$NF" in
  404|410) ok "missing pages return $NF" ;;
  200)     bad "missing page returns 200 — SOFT 404. Every mistyped URL becomes an indexable page" ;;
  30*)     warn "missing page redirects ($NF) — a 404 should 404, not redirect to the homepage" ;;
  *)       warn "missing page returns $NF" ;;
esac

R="$(meta robots)"
case "$R" in *noindex*) bad "this page is set to noindex: $R" ;; "") ok "no meta robots restriction" ;; *) info "meta robots: $R" ;; esac

# ── 4 · On-page metadata ──────────────────────────────────────────────────────
sec "4 · ON-PAGE METADATA"
TITLE="$(grep -oiE '<title[^>]*>[^<]*' "$HTML" | head -1 | sed -E 's/<title[^>]*>//')"
if [ -n "$TITLE" ]; then
  L=${#TITLE}
  if [ "$L" -lt 20 ]; then warn "title very short (${L} chars): $TITLE"
  elif [ "$L" -gt 65 ]; then warn "title will truncate (${L} chars): $TITLE"
  else ok "title (${L} chars): $TITLE"; fi
else bad "no <title>"; fi

DESC="$(meta description)"
if [ -n "$DESC" ]; then
  L=${#DESC}
  if [ "$L" -lt 70 ]; then warn "meta description short (${L} chars)"
  elif [ "$L" -gt 170 ]; then warn "meta description will truncate (${L} chars)"
  else ok "meta description (${L} chars)"; fi
  info "$(printf '%.100s' "$DESC")"
else bad "no meta description — the engine will write one for you, usually badly"; fi

CANON="$(grep -oiE '<link[^>]+rel=["'"'"']canonical["'"'"'][^>]*>' "$HTML" | grep -oiE 'href=["'"'"'][^"'"'"']*' | sed -E 's/^href=["'"'"']//')"
if [ -n "$CANON" ]; then
  ok "canonical: $CANON"
  case "$CANON" in http*) ;; *) warn "canonical is relative — should be absolute" ;; esac
  [ "$CANON" = "$BASE/" ] && [ "$FINAL" != "$BASE/" ] && bad "canonical points at the homepage from a non-homepage — this de-indexes the page"
else warn "no canonical link"; fi

H1S="$(grep -oiE '<h1[^>]*>' "$HTML" | wc -l | tr -d ' ')"
case "$H1S" in
  1) ok "exactly one <h1>" ;;
  0) bad "no <h1>" ;;
  *) warn "$H1S <h1> elements — there should be exactly one" ;;
esac

LANG="$(grep -oiE '<html[^>]+lang=["'"'"'][^"'"'"']*' "$HTML" | head -1 | sed -E 's/.*lang=["'"'"']//')"
[ -n "$LANG" ] && ok "html lang=\"$LANG\"" || warn "no lang attribute on <html>"

# ── 5 · Social sharing ────────────────────────────────────────────────────────
sec "5 · SOCIAL SHARING"
for p in og:title og:description og:url og:type; do
  v="$(meta "$p")"; [ -n "$v" ] && ok "$p" || warn "$p missing"
done
OGI="$(meta og:image)"
if [ -n "$OGI" ]; then
  case "$OGI" in
    http*) IC="$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$OGI")"
           IS="$("${CURL[@]}" -o /dev/null -w '%{size_download}' "$OGI")"
           if [ "$IC" = "200" ]; then ok "og:image reachable ($(( IS / 1024 ))KB)"
           else bad "og:image returns $IC — the share preview will be blank"; fi ;;
    *) bad "og:image is a relative URL — it will be ignored. Must be absolute" ;;
  esac
  [ -n "$(meta og:image:width)" ] || warn "og:image:width/height not declared (target 1200x630)"
else bad "og:image missing — shared links will look broken"; fi
[ -n "$(meta twitter:card)" ] && ok "twitter:card" || warn "twitter:card missing"

# ── 6 · Structured data ───────────────────────────────────────────────────────
sec "6 · STRUCTURED DATA"
LD="$(grep -c 'application/ld+json' "$HTML" || true)"
if [ "$LD" -gt 0 ]; then
  ok "$LD JSON-LD block(s)"
  TYPES="$(grep -oE '"@type"\s*:\s*"[^"]+"' "$HTML" | sed -E 's/.*"([^"]+)"$/\1/' | sort -u | tr '\n' ' ')"
  info "types: ${TYPES:-none parsed}"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$HTML" <<'PY' 2>/dev/null
import json, re, sys
html = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = re.findall(r'<script[^>]*application/ld\+json[^>]*>(.*?)</script>', html, re.S | re.I)
bad = 0
for i, b in enumerate(blocks, 1):
    try: json.loads(b)
    except Exception as e:
        print(f"    \033[31m✗\033[0m JSON-LD block {i} is not valid JSON: {e}"); bad += 1
if blocks and not bad:
    print("  \033[32m✓\033[0m all JSON-LD blocks parse as valid JSON")
PY
  fi
  case "$TYPES" in *Organization*) ;; *) warn "no Organization schema" ;; esac
  case "$TYPES" in *WebSite*) ;; *) warn "no WebSite schema" ;; esac
  case "$TYPES" in *LocalBusiness*|*Store*|*Restaurant*|*ProfessionalService*|*Dentist*|*LawFirm*)
      ok "LocalBusiness-family schema present" ;;
    *)  info "no LocalBusiness schema — required for map/local-pack results if there is a physical location" ;;
  esac
else
  warn "no JSON-LD structured data"
fi

# ── 7 · Images & accessibility signals ────────────────────────────────────────
sec "7 · IMAGES & ACCESSIBILITY SIGNALS"
IMGS="$(grep -oiE '<img[^>]*>' "$HTML")"
NIMG="$(printf '%s' "$IMGS" | grep -c '<img' || true)"
if [ "$NIMG" -gt 0 ]; then
  NOALT="$(printf '%s\n' "$IMGS" | grep -vi 'alt=' | wc -l | tr -d ' ')"
  NODIM="$(printf '%s\n' "$IMGS" | grep -vi 'width=' | wc -l | tr -d ' ')"
  [ "$NOALT" -eq 0 ] && ok "$NIMG <img>, all have an alt attribute" \
                     || bad "$NOALT of $NIMG <img> have no alt — screen readers will announce the filename"
  [ "$NODIM" -eq 0 ] && ok "all <img> declare width" \
                     || warn "$NODIM of $NIMG <img> lack width/height — causes layout shift (CLS)"
  printf '%s\n' "$IMGS" | grep -qi 'loading="lazy"' && info "lazy loading in use — verify the LCP/hero image is NOT lazy-loaded"
else info "no <img> tags in the server response (may be client-rendered)"; fi

grep -qiE '<(main|nav|header|footer|article|section)\b' "$HTML" && ok "semantic landmarks present" || warn "no semantic landmark elements"
grep -qiE 'skip[- ]?to[- ]?(main|content)' "$HTML" && ok "skip link present" || warn "no skip-to-content link"
grep -qiE '<html[^>]+lang=' "$HTML" || true
VP="$(meta viewport)"
if [ -n "$VP" ]; then
  case "$VP" in
    *user-scalable=no*|*maximum-scale=1*) bad "viewport blocks zoom — a WCAG failure: $VP" ;;
    *) ok "viewport: $VP" ;;
  esac
else warn "no viewport meta — the page will not be mobile-responsive"; fi

# ── 8 · Trust surface ─────────────────────────────────────────────────────────
sec "8 · TRUST SURFACE"
probe() { # <path> <label> <severity>
  c="$("${CURL[@]}" -o /dev/null -w '%{http_code}' -L "$BASE$1")"
  if [ "$c" = "200" ]; then ok "$2  ($1)"; else
    if [ "$3" = "bad" ]; then bad "$2 not found at $1 ($c)"; else warn "$2 not found at $1 ($c)"; fi
  fi
}
probe "/privacy"                      "Privacy policy"      bad
probe "/terms"                        "Terms of service"    warn
probe "/contact"                      "Contact page"        warn
probe "/faq"                          "FAQ page"            warn
probe "/.well-known/security.txt"     "security.txt"        warn

grep -qiE 'cookie' "$HTML" && info "the word 'cookie' appears — verify the banner GATES scripts before consent, and that rejecting is as easy as accepting"
grep -oiE 'googletagmanager|google-analytics|gtag\(|connect\.facebook\.net|hotjar|segment\.com|mixpanel|posthog|clarity\.ms|intercom' "$HTML" \
  | sort -u | while read -r t; do info "third party: $t  → must appear in the privacy policy"; done

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n\033[2m%s\033[0m\n' "──────────────────────────────────────────────"
printf ' \033[31m%s failing\033[0m · \033[33m%s warnings\033[0m\n' "$FAIL" "$WARN"
printf '\033[2mThis checks one URL. A full audit checks every template, confirms each\nfinding by hand, and includes accessibility and performance testing that\nno HTTP check can perform.\033[0m\n'
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
