#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "PUBLIC_HYGIENE_ERROR: $*" >&2
  exit 1
}

# Secret-bearing filenames should never be tracked in this public overlay.
while IFS= read -r -d '' path; do
  base=${path##*/}
  case "$base" in
    .env|.env.*|credentials.json|secrets.json|id_rsa*|id_ed25519*|*.pem|*.ppk)
      [[ "$base" == ".env.example" ]] || fail "secret-like tracked filename: $path"
      ;;
  esac
done < <(git ls-files -z)

# Scan only tracked text files. Synthetic CI values should avoid these real-world
# token/key signatures entirely.
if git grep -nIE \
  -e '-----BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY-----|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,}' \
  -- ':!scripts/check-public-hygiene.sh' >/tmp/omniroute-public-hygiene-secrets.txt 2>/dev/null; then
  cat /tmp/omniroute-public-hygiene-secrets.txt >&2
  fail "possible credential material found"
fi

# Public infrastructure addresses do not belong in the repository. Loopback,
# RFC1918/link-local, unspecified, and RFC5737 documentation ranges are allowed.
node <<'NODE'
const { execFileSync } = require('node:child_process');

const files = execFileSync('git', ['ls-files', '-z']).toString('utf8').split('\0').filter(Boolean);
const ipv4 = /\b(?:\d{1,3}\.){3}\d{1,3}\b/g;
const allowed = ([a, b, c, d]) => {
  if ([a, b, c, d].some((n) => n < 0 || n > 255)) return true; // not a valid IPv4 literal
  if (a === 0 || a === 10 || a === 127) return true;
  if (a === 169 && b === 254) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a === 192 && b === 0 && c === 2) return true; // TEST-NET-1
  if (a === 198 && b === 51 && c === 100) return true; // TEST-NET-2
  if (a === 203 && b === 0 && c === 113) return true; // TEST-NET-3
  if (a >= 224) return true; // multicast/reserved, not a routable host target
  return false;
};

const findings = [];
for (const file of files) {
  if (file === 'scripts/check-public-hygiene.sh') continue;
  let text;
  try {
    text = execFileSync('git', ['show', `:${file}`], {
      encoding: 'utf8',
      maxBuffer: 16 * 1024 * 1024,
    });
  } catch {
    continue;
  }
  for (const match of text.matchAll(ipv4)) {
    const parts = match[0].split('.').map(Number);
    if (!allowed(parts)) findings.push(`${file}: public IPv4 literal ${match[0]}`);
  }
}

if (findings.length) {
  console.error(findings.join('\n'));
  process.exit(1);
}
NODE

echo "PUBLIC_HYGIENE_OK=1"
