# OmniRoute Patched

Version-pinned, source-level customization and release hardening for OmniRoute.

This is a **public** overlay repository. It does not vendor OmniRoute and it does
not patch minified Next.js/Turbopack chunks. CI clones an exact upstream ref,
applies the configured source patches, builds the complete Linux npm package,
installs the packed artifact, runs package/browser smoke tests, and publishes a
versioned GitHub Release.

## Safety contract

A successful GitHub Actions build **never deploys to production**.

- Clean patch + green tests: a verified **public GitHub Release** may be published.
- Patch conflict or failed test: no release is published and production is untouched.
- Production installation is a separate, explicit operation through the VPS updater.
- Runtime credentials, `.env` files, SSH keys, provider tokens, host-specific secrets,
  and private deployment data must never be committed to this repository.

## Current baseline

The supported patch set is pinned to upstream tag `v3.8.50`, exact commit
`5458026c216f77a3da68ea49152dc33470cfe2cb`.

The legacy 3.8.47 Quota UI and HEAD-response packaging patches are no longer applied.
OmniRoute v3.8.50 already contains the packaging guard and substantially improved
quota UX, including deterministic provider ordering, expandable provider sections,
compact layout support, account sorting, and quota visibility controls.

The remaining source patch is `patches/codex-nonstream-sse.patch`: stock v3.8.50
still does not mark the Codex Responses upstream as force-streaming, so this overlay
keeps the SSE-to-JSON bridge correct for callers using `stream:false`.

## Upgrade policy

Stable upgrades use a published upstream tag resolved to an exact commit SHA. The
exact commit pin is authoritative even if GitHub's release object is not marked
immutable. Required provider capabilities must be present in upstream before the
baseline moves.

Planned optional extensions are documented in
[`docs/IMAGE_ADAPTERS.md`](docs/IMAGE_ADAPTERS.md), including Cloudflare Workers AI
and AI Horde image-generation support for OmniRoute's OpenAI-compatible image API.

## Repository layout

- `config/baseline.json` — exact currently supported upstream source and patch set.
- `config/upgrade-policy.json` — readiness requirements for future baselines.
- `patches/codex-nonstream-sse.patch` — Codex `stream:false` compatibility fix.
- `patches/quota-ui.patch` — retained legacy reference; not configured for v3.8.50.
- `patches/head-response-guard-packaging.patch` — retained legacy reference; not configured for v3.8.50.
- `.github/workflows/build-release.yml` — manual/versioned release builder.
- `.github/workflows/watch-upstream.yml` — stable-upstream readiness watcher.
- `tests/packaged-smoke.mjs` — auth, API guard, SSR, hydration, and console smoke.
- `installer/omniroute-patched-update` — explicit fail-closed installer/rollback tool.
- `docs/OPERATIONS.md` — release/deployment runbook.
- `SECURITY.md` — public-repository secret and infrastructure hygiene rules.

## Release flow

1. Select a published upstream tag and resolve it to an exact commit that meets `config/upgrade-policy.json`.
2. Port only patches/features still missing upstream.
3. Build and test the real packed npm artifact.
4. Publish a verified patched release only after all gates pass.
5. Deploy only after a separate explicit production request.
