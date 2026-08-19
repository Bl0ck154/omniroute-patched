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

[[ ${#PATCHES[@]} -gt 0 ]] || {
  echo "baseline has no configured source patches" >&2
  exit 1
}

for patch in "${PATCHES[@]}"; do
  [[ -f "$ROOT/$patch" ]] || { echo "configured patch missing: $patch" >&2; exit 1; }
  git -C "$UPSTREAM" apply --check "$ROOT/$patch"
  git -C "$UPSTREAM" apply "$ROOT/$patch"
  echo "PATCH_APPLIED=$patch"
done

# Overlay-specific integration guards. A patch is publishable only when the
# dedicated handlers and registry dispatch markers are present after applying
# the complete patch set.
IMAGE_REGISTRY="$UPSTREAM/open-sse/config/imageRegistry.ts"
IMAGE_HANDLER="$UPSTREAM/open-sse/handlers/imageGeneration.ts"
CF_HANDLER="$UPSTREAM/open-sse/handlers/imageGeneration/providers/cloudflareWorkersAi.ts"
HORDE_HANDLER="$UPSTREAM/open-sse/handlers/imageGeneration/providers/aiHorde.ts"

for file in "$IMAGE_REGISTRY" "$IMAGE_HANDLER" "$CF_HANDLER" "$HORDE_HANDLER"; do
  [[ -f "$file" ]] || { echo "overlay integration file missing: $file" >&2; exit 1; }
done

grep -q 'format: "cloudflare-workers-ai-image"' "$IMAGE_REGISTRY"
grep -q 'format: "aihorde-image"' "$IMAGE_REGISTRY"
grep -q 'handleCloudflareWorkersAiImageGeneration' "$IMAGE_HANDLER"
grep -q 'handleAiHordeImageGeneration' "$IMAGE_HANDLER"

# Keep upstream regression guards while these contracts exist. If upstream
# refactors them, migration must update the assertion deliberately rather than
# silently weakening package/runtime safety.
NORMALIZATION="$UPSTREAM/open-sse/utils/responsesInputNormalization.ts"
[[ -f "$NORMALIZATION" ]] || {
  echo "responses normalization contract moved; update compatibility assertion" >&2
  exit 1
}
grep -q 'record.type === "input_text"' "$NORMALIZATION"

PACK_POLICY="$UPSTREAM/scripts/build/pack-artifact-policy.ts"
[[ -f "$PACK_POLICY" ]] || {
  echo "pack artifact policy moved; update packaging assertion" >&2
  exit 1
}
grep -q '"head-response-guard.cjs"' "$PACK_POLICY"

echo PATCH_SET_APPLIED=1
