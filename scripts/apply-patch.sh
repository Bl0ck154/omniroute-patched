#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UPSTREAM=${1:?usage: apply-patch.sh /path/to/OmniRoute}

git -C "$UPSTREAM" diff --quiet
git -C "$UPSTREAM" apply --check "$ROOT/patches/quota-ui.patch"
git -C "$UPSTREAM" apply "$ROOT/patches/quota-ui.patch"

TARGET="$UPSTREAM/src/app/(dashboard)/dashboard/usage/components/ProviderLimits/QuotaCardGrid.tsx"
grep -q 'data-omniroute-quota-ui-patch="source-v1"' "$TARGET"
echo PATCH_APPLIED=1

