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

The currently supported patch set remains pinned to upstream `release/v3.8.47`
commit `38d6cd9955d55548dd1f85fff3ab2b477537659d`.

That baseline is intentionally left intact while the next upstream target is still
moving. The old `head-response-guard-packaging.patch` is required by this baseline,
but is already upstream in newer OmniRoute versions and must be dropped when the
baseline advances.

## Next upgrade policy

The next baseline refresh is tracked in [`docs/NEXT_UPGRADE.md`](docs/NEXT_UPGRADE.md).
The repository should not jump to a moving preview branch just to be newer. The
preferred target is an immutable upstream release/tag that satisfies the required
capabilities, including working Antigravity Gemini 3.7 support.

The old large Quota UI patch will not be blindly rebased. Newer OmniRoute versions
already implement much of the desired quota UX, so only still-useful deltas should
be carried forward as a small semantic patch.

Planned optional extensions are documented in
[`docs/IMAGE_ADAPTERS.md`](docs/IMAGE_ADAPTERS.md), including Cloudflare Workers AI
and AI Horde image-generation support for OmniRoute's OpenAI-compatible image API.

## Repository layout

- `config/baseline.json` — exact currently supported upstream source and patch set.
- `config/upgrade-policy.json` — readiness requirements for the next baseline.
- `patches/quota-ui.patch` — current legacy Quota UI patch for the 3.8.47 baseline.
- `patches/head-response-guard-packaging.patch` — legacy 3.8.47 packaging fix.
- `.github/workflows/build-release.yml` — manual/versioned release builder.
- `.github/workflows/watch-upstream.yml` — stable-upstream readiness watcher.
- `tests/packaged-smoke.mjs` — auth, API guard, SSR, hydration, and console smoke.
- `installer/omniroute-patched-update` — explicit fail-closed installer/rollback tool.
- `docs/OPERATIONS.md` — release/deployment runbook.
- `SECURITY.md` — public-repository secret and infrastructure hygiene rules.

## Release flow

1. Select an immutable upstream tag/commit that meets `config/upgrade-policy.json`.
2. Port only the patches/features still missing upstream.
3. Build and test the real packed npm artifact.
4. Publish a verified release only after all gates pass.
5. Deploy only after a separate explicit production request.
