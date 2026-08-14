#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UPSTREAM=${1:?usage: apply-patch.sh /path/to/OmniRoute}

# The overlay is public; fail before release work if tracked repository content
# contains secret-like material or a real public infrastructure IPv4 literal.
bash "$ROOT/scripts/check-public-hygiene.sh"

git -C "$UPSTREAM" diff --quiet

mapfile -t PATCHES < <(
  node -e '
    const config = require(process.argv[1]);
    for (const patch of config.patches || []) console.log(patch);
  ' "$ROOT/config/baseline.json"
)

for patch in "${PATCHES[@]}"; do
  [[ -f "$ROOT/$patch" ]] || { echo "configured patch missing: $patch" >&2; exit 1; }
  git -C "$UPSTREAM" apply --check "$ROOT/$patch"
  git -C "$UPSTREAM" apply "$ROOT/$patch"
  echo "PATCH_APPLIED=$patch"
done

has_patch() {
  local wanted=$1 patch
  for patch in "${PATCHES[@]}"; do
    [[ "$patch" == "$wanted" ]] && return 0
  done
  return 1
}

# Legacy assertions are conditional so the next baseline can remove obsolete
# patches instead of carrying their markers forever.
if has_patch "patches/quota-ui.patch"; then
  TARGET="$UPSTREAM/src/app/(dashboard)/dashboard/usage/components/ProviderLimits/QuotaCardGrid.tsx"
  grep -q 'data-omniroute-quota-ui-patch="source-v1"' "$TARGET"
fi

# Keep this upstream regression guard while the file/contract exists. If a future
# upstream refactors the normalization module, the baseline migration must replace
# this assertion deliberately rather than silently weakening it.
NORMALIZATION="$UPSTREAM/open-sse/utils/responsesInputNormalization.ts"
[[ -f "$NORMALIZATION" ]] || {
  echo "responses normalization contract moved; update compatibility assertion" >&2
  exit 1
}
grep -q 'record.type === "input_text"' "$NORMALIZATION"

# The 3.8.47 overlay patches this packaging rule; newer upstream releases already
# contain it. Either way, every publishable artifact must retain the sidecar.
PACK_POLICY="$UPSTREAM/scripts/build/pack-artifact-policy.ts"
[[ -f "$PACK_POLICY" ]] || {
  echo "pack artifact policy moved; update packaging assertion" >&2
  exit 1
}
grep -q '"head-response-guard.cjs"' "$PACK_POLICY"

echo PATCH_SET_APPLIED=1
