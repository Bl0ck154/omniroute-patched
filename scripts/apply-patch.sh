#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UPSTREAM=${1:?usage: apply-patch.sh /path/to/OmniRoute}

git -C "$UPSTREAM" diff --quiet

mapfile -t PATCHES < <(
  node -e '
    const config = require(process.argv[1]);
    for (const patch of config.patches || ["patches/quota-ui.patch"]) console.log(patch);
  ' "$ROOT/config/baseline.json"
)

for patch in "${PATCHES[@]}"; do
  git -C "$UPSTREAM" apply --check "$ROOT/$patch"
  git -C "$UPSTREAM" apply "$ROOT/$patch"
  echo "PATCH_APPLIED=$patch"
done

TARGET="$UPSTREAM/src/app/(dashboard)/dashboard/usage/components/ProviderLimits/QuotaCardGrid.tsx"
grep -q 'data-omniroute-quota-ui-patch="source-v1"' "$TARGET"
grep -q 'record.type === "input_text"' "$UPSTREAM/open-sse/utils/responsesInputNormalization.ts"
grep -q '"head-response-guard.cjs"' "$UPSTREAM/scripts/build/pack-artifact-policy.ts"
echo PATCH_SET_APPLIED=1
