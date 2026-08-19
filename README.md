# OmniRoute Patched

Version-pinned, source-level customization and release hardening for OmniRoute.

This is a **public** overlay repository. It does not vendor OmniRoute and it does
not patch minified Next.js/Turbopack chunks. CI clones an exact upstream ref,
applies the configured source patches, builds the complete Linux npm package,
installs the packed artifact, runs package/browser smoke tests, and can publish a
versioned public GitHub Release.

## Safety contract

A successful GitHub Actions build **never deploys to production**.

- Clean patch + green tests: a verified public GitHub Release may be published.
- Patch conflict or failed test: no release is published and production is untouched.
- Production installation is a separate, explicit operation through the VPS updater.
- Runtime credentials, `.env` files, SSH keys, provider tokens, host-specific secrets,
  and private deployment data must never be committed to this repository.

## Current migration baseline

The migration branch is pinned to upstream `release/v3.8.50` commit
`6d9336088c48fe7d9c858afb4e95ff28932c047a`, whose package version is `3.8.50`.

This is a **preview pin**, not an immutable production release. The migration PR
must remain a candidate until upstream publishes an immutable `v3.8.50` release/tag.
At that point the baseline is re-pinned to the tag commit, the patch set is
re-applied, and every release gate is rerun before the migration is eligible for
`main` or production use.

Upstream 3.8.50 already contains the quota UX that motivated the old local patch,
including rich filters, provider/account ordering, compact/full layouts,
expandable provider groups, quota visibility controls, and reset-credit handling.
The old 3.8.47 `quota-ui.patch` is therefore retired instead of being rebased.
The old HEAD-response packaging fix is also retired because that fix is upstream.

## Active overlay features

The 3.8.50 migration carries two isolated source patches:

- `patches/cloudflare-images.patch` — adds Cloudflare Workers AI text-to-image
  models to OmniRoute's existing `/v1/images/generations` API. It reuses the
  existing `cloudflare-ai` API token + Account ID connection.
- `patches/aihorde-images.patch` — adds native asynchronous AI Horde image
  generation with anonymous-key fallback, bounded polling/cancellation, explicit
  model routing, and SSRF-safe `b64_json` result fetching.

Both adapters use OmniRoute's existing image route and credential-selection layer;
no second public image API is introduced.

## Gemini 3.7

Gemini 3.7 is no longer a local patch target. The selected upstream 3.8.50 source
contains Antigravity Gemini 3.7 support and live authenticated Antigravity model
discovery, so future account-available chat models are not limited to a static
local catalog.

## Repository layout

- `config/baseline.json` — exact upstream source pin and active patch set.
- `config/upgrade-policy.json` — minimum readiness requirements for future baselines.
- `patches/cloudflare-images.patch` — Cloudflare Workers AI image adapter.
- `patches/aihorde-images.patch` — AI Horde native async image adapter.
- `patches/README.md` — patch lifecycle and retired-patch notes.
- `.github/workflows/build-release.yml` — manual/versioned overlay release builder.
- `.github/workflows/watch-upstream.yml` — stable-upstream readiness watcher.
- `tests/packaged-smoke.mjs` — auth, API guard, quota SSR/hydration, and console smoke.
- `installer/omniroute-patched-update` — explicit fail-closed installer/rollback tool.
- `docs/OPERATIONS.md` — release/deployment runbook.
- `docs/NEXT_UPGRADE.md` — migration/finalization checklist.
- `docs/IMAGE_ADAPTERS.md` — image-adapter contracts and implementation status.
- `SECURITY.md` — public-repository secret and infrastructure hygiene rules.

## Release flow

1. Pin an exact upstream ref/commit and apply every configured source patch with
   `git apply --check` before modification.
2. Run overlay unit/lint checks before expensive browser/build work.
3. Build and install the real packed npm artifact.
4. Verify overlay markers, launcher/auth behavior, quota SSR/hydration, and browser logs.
5. Publish `v<upstream>-overlay.<revision>` only after all gates pass.
6. Deploy only after a separate explicit production request.

For the current 3.8.50 migration, step 5 is intentionally blocked as a production
milestone until the official immutable upstream tag exists and the baseline is
re-pinned to it.
