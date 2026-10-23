# PHP application-code security

The bug classes that recur in PHP code, each as: **how to find it → the fix →
how to verify**. Grep results are leads; read the code and confirm the input is
reachable and attacker-influenced before calling it a finding.

---

## 1 · SQL injection

```bash
grep -rEn '(mysqli_query|->query|->exec|->prepare)\s*\(\s*["'"'"'][^"'"'"']*(\$|\.\s*\$)' --include=*.php . | grep -v vendor/
grep -rEn 'whereRaw|DB::raw|DB::select\(\s*["'"'"'][^"'"'"']*\$' --include=*.php app routes 2>/dev/null
```

**Fix:** PDO with real prepared statements — set `PDO::ATTR_EMULATE_PREPARES =>
false` and `PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION`; bind every value.
Dynamic identifiers (column, table, `ORDER BY`) come from an **allowlist**, never
from input. ORM raw escape hatches (`whereRaw`, `DB::raw`, `orderByRaw`) take
bindings, not concatenation.

**Verify:** a test sends `' OR '1'='1` and a stacked-query string in each
parameter and expects a validation error or empty result, never a SQL error or
extra rows.

## 2 · Cross-site scripting

**Find:** `echo $_GET`, `<?= $var ?>` without escaping, Blade `{!! !!}`, Twig
`|raw`, `print $_POST[...]`.

**Fix:** escape on output for the context: `htmlspecialchars($s, ENT_QUOTES |
ENT_SUBSTITUTE, 'UTF-8')` for HTML; framework auto-escaping (Blade `{{ }}`, Twig
default) kept on; every `raw`/`{!! !!}` justified and fed sanitised content from a
maintained allowlist sanitiser; a CSP without `unsafe-inline`
(`security-hardening/references/security-headers.md`).

**Verify:** render `"><script>…` in every field and confirm it appears as text.

## 3 · Unsafe deserialization (`unserialize`)

**Find:** `unserialize(` on anything that crosses a trust boundary — cookies,
request params, queue payloads, cache entries other tenants can influence,
uploaded files.

```bash
grep -rEn 'unserialize\s*\(' --include=*.php . | grep -v vendor/
```

**Fix:** use `json_decode` for data interchange. If `unserialize` is unavoidable,
pass `['allowed_classes' => false]` (or an explicit class list) and sign the
payload with an HMAC verified with `hash_equals` **before** parsing. Never let
user input reach file functions with a `phar://` path.

**Verify:** a test passes a serialized object of a disallowed class and expects
rejection with no autoload or side effect.

## 4 · File inclusion and path traversal

**Find:** `include|require` with a variable; `file_get_contents`, `readfile`,
`fopen` with request-derived paths.

```bash
grep -rEn '(include|require)(_once)?\s*\(?\s*\$|(file_get_contents|readfile|fopen|file)\s*\(\s*\$_(GET|POST|REQUEST)' --include=*.php . | grep -v vendor/
```

**Fix:** map user choices to a fixed allowlist (`['home' => 'pages/home.php']`),
never build include paths from input. For file access: `realpath()` the result and
assert it starts with the intended root plus a separator.

**Verify:** request `../../etc/passwd`, `..%2f`, a null byte and an absolute path;
all must be rejected.

## 5 · Command execution

**Find:** `exec shell_exec system passthru popen proc_open pcntl_exec`, backticks,
`mail()` 5th argument, `escapeshellcmd` used as if it were enough.

**Fix:** avoid the shell. Use language-native libraries (image libraries, ZIP
APIs). If you must run a binary: `proc_open` with an **argument array**, fixed
executable path, validated arguments against an allowlist, and `escapeshellarg()`
only as a last line.

**Verify:** a test passes `; id`, `$(id)`, backticks and a newline in each input
and expects no command output, no extra process.

## 6 · Uploads

**Fix, all of:**
- Size limit; extension **allowlist**; content check with `finfo`/`mime_content_type`
  and, for images, re-encode through an image library (strips payloads).
- **Random server-generated filename**; ignore the client's name and extension.
- Store **outside the webroot**, or in a directory where PHP execution is
  disabled (`php-ini-baseline.md`); serve via a controller or a separate
  cookieless origin with `Content-Disposition: attachment` and `nosniff`.
- `move_uploaded_file` only — it verifies the file came from an HTTP upload.

**Verify:** in a test environment upload a harmless text file named `x.php`,
`x.php.jpg` and `x.phtml`; confirm each is rejected or stored inert and never
executed when requested.

## 7 · Authentication, sessions, CSRF

- `password_hash($p, PASSWORD_ARGON2ID)` (or `PASSWORD_BCRYPT` with a current
  cost), `password_verify`, `password_needs_rehash`. Never `md5`/`sha1`/`crypt`
  without a modern algorithm.
- `session_regenerate_id(true)` on login and on privilege change; destroy on logout.
- Compare secrets and tokens with `hash_equals`, never `==`.
- CSRF token on every state-changing request for cookie-authenticated sessions;
  `SameSite` cookies as a second layer.
- Randomness for tokens: `random_bytes()` / `random_int()`; never `rand`,
  `mt_rand`, `uniqid`.

**Verify:** a request without the CSRF token is rejected; two accounts' sessions
cannot read each other's data (`security-hardening` object-level test).

## 8 · Type juggling and loose comparison

`==` between a string and a number or between numeric-looking strings can be
true when you did not intend. Use `===`; use `hash_equals` for secrets; cast and
validate input types at the boundary; prefer `declare(strict_types=1)`.

**Find:** `if ($input == $secret)`, `in_array($x, $list)` without the strict flag,
`switch` on user input, `strcmp` result compared loosely.

## 9 · SSRF and remote fetches

`file_get_contents($url)`, `curl_exec`, image/URL import features, webhook senders.
**Fix:** scheme allowlist (`https`), resolve DNS and reject private, loopback and
link-local ranges (including the cloud metadata address) *after* resolution,
disable redirects or re-validate each hop, set timeouts and size caps.
**Verify:** requests to `http://127.0.0.1`, the metadata IP and a DNS name that
resolves to a private address are refused.

## 10 · Dangerous language features

| Pattern | Risk | Do instead |
|---|---|---|
| `eval`, `create_function`, `assert($string)`, `preg_replace` with `/e` | Code execution | Remove; use callbacks / real parsers |
| `extract($_POST)`, `$$name`, `parse_str($s)` without result array | Variable overwrite / mass assignment | Read named keys explicitly |
| `$_REQUEST` | Mixes sources, bypasses checks | Read from the specific superglobal |
| `phpinfo()` reachable | Reveals paths, modules, environment | Delete; never ship |
| `mail($to, $s, $m, $headers)` with user input in headers | Header injection | Use a mailer library; reject CR/LF |
| `header("Location: " . $_GET['next'])` | Open redirect | Allowlist destinations |
| `error_reporting` shown to users | Information leak | Log, don't display |
| `serialize`d cookies, `__wakeup`/`__destruct` doing real work | Gadget chains | Keep magic methods inert |

## Reporting these

Use the suite's finding shape (title · class · location · confidence · impact ·
reproduce · fix · verify). Each finding needs a **failing regression test**
(PHPUnit / Pest) that passes after the fix.
