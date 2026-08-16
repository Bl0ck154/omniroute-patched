# Patch lifecycle

Patches in this repository are tied to an exact upstream baseline. A patch is not
assumed to remain valid merely because a later OmniRoute version has a similar
file or provider.

## Active 3.8.50 migration patches

`config/baseline.json` currently applies exactly two independent source patches:

- `cloudflare-images.patch` — Cloudflare Workers AI image generation through
  OmniRoute's existing OpenAI-compatible image route. The adapter reuses the
  `cloudflare-ai` API token and Account ID connection.
- `aihorde-images.patch` — AI Horde native async image generation, including
  anonymous-key fallback, bounded polling/cancel behavior, explicit model routing,
  and SSRF-safe conversion of remote results to `b64_json`.

Keep these separate. If upstream implements one provider natively, delete that
patch without forcing unrelated churn in the other adapter.

## Retired patches

The migration deliberately removes these old 3.8.47 patch files from the active
tree; their history remains available in Git:

- `quota-ui.patch` — retired because upstream 3.8.50 now provides the important
  quota filtering, sorting, layout, visibility, and expandable-group behavior.
  The old hard-coded Gemini CLI plan override must not return.
- `head-response-guard-packaging.patch` — retired because the packaging fix is
  already present upstream. `scripts/apply-patch.sh` still verifies that upstream
  retains `head-response-guard.cjs` in its packaging policy.

## Porting rule

For every upstream baseline change:

1. inspect the selected immutable upstream release;
2. identify which local behavior is already upstream;
3. delete obsolete patches rather than rebasing them mechanically;
4. port only behavior still missing from upstream;
5. add focused tests for every retained delta;
6. run `git apply --check` for the complete patch sequence;
7. update `config/baseline.json` only after the new patch set is reproducible.

The 3.8.50 migration currently uses a fixed preview commit for compatibility work.
It is not final until an immutable upstream `v3.8.50` tag is published and the
patch sequence is revalidated against that tag commit.
