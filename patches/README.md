# Patch lifecycle

Patches in this repository are tied to an exact upstream baseline. A patch is not
assumed to be valid merely because a later OmniRoute version has a similar file.

## Current baseline patches

- `quota-ui.patch` — legacy Quota UI customization for the 3.8.47 baseline.
- `head-response-guard-packaging.patch` — legacy 3.8.47 packaging fix.
- `codex-nonstream-sse.patch` — marks Codex `/responses` as an upstream-streaming provider so non-stream clients drain terminal SSE instead of waiting for EOF.

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

The HEAD response guard patch should disappear on newer upstream releases where
that packaging fix is already present.

The old Quota UI patch should be replaced by a much smaller semantic extras patch
if any desired UI behavior remains missing. In particular, do not carry the old
hard-coded Gemini CLI plan override forward.

Provider/image extensions should be kept separate from quota UI so upstreaming or
removing one feature does not force unrelated patch churn.
