# Patch lifecycle

Patches in this repository are tied to an exact upstream baseline. A patch is not
assumed to be valid merely because a later OmniRoute version has a similar file.

## Current baseline patches

- `codex-nonstream-sse.patch` — marks Codex `/responses` as an upstream-streaming provider so non-stream clients drain terminal SSE instead of waiting for EOF.
- `server-runtime-compat.patch` — preserves Antigravity image-size propagation,
  provider-connection cache invalidation, and safe Codex bulk-import recovery state.
- `etsy-image-artifact-sink.patch` — keeps a private stream consumer alive for one
  explicitly configured API-key/model/tool scope and atomically stores validated
  image bytes without prompts or response payloads.
- `codex-image-free-plan-failover.patch` — recognizes imported Codex free-plan accounts
  and rotates image generation to another eligible account when the hosted image tool is unavailable.

The legacy `quota-ui.patch` and `head-response-guard-packaging.patch` remain as
historical references but are not configured for the v3.8.50 baseline.

All current-baseline patches remain configured in `config/baseline.json` so the verified
baseline stays reproducible.

## Next baseline

Do not copy these patches into a new baseline automatically.

For each patch:

1. inspect the selected immutable upstream release;
2. identify which behavior is already upstream;
3. drop obsolete hunks/features;
4. reimplement only the still-missing behavior against the new source;
5. add focused tests for every retained delta;
6. update `config/baseline.json` only after the new patch set is green.

The HEAD response guard patch is absent from the v3.8.50 configured patch set
because the packaging fix is upstream.

The old Quota UI patch should be replaced by a much smaller semantic extras patch
if any desired UI behavior remains missing. In particular, do not carry the old
hard-coded Gemini CLI plan override forward.

Provider/image extensions should be kept separate from quota UI so upstreaming or
removing one feature does not force unrelated patch churn.

The old host-side compiled image-auth patch is deliberately not represented here:
v3.8.50 has source-level credential refresh and account fallback in
`src/sse/services/imageCredentialRetry.ts`, covered by the release test matrix.
