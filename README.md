# OmniRoute Patched

Version-pinned, source-level customization of OmniRoute.

This repository does **not** patch minified Next.js/Turbopack chunks. It applies
the configured patch set to an exact upstream OmniRoute commit, builds the complete
Linux npm release in GitHub Actions, tests the real packaged launcher, and
publishes a versioned artifact.

## Update contract

When a new upstream version appears, CI attempts to apply the source patch and
build a candidate. It never deploys to production automatically.

- Clean patch + green tests: a verified GitHub Release is published.
- Patch conflict or failed test: no release is published and the VPS is not touched.
- Production installation is performed only through the VPS updater after an
  explicit request such as: `онови OmniRoute з нашого репо`.

## Repository layout

- `patches/quota-ui.patch` — canonical Quota UI source patch.
- `.github/workflows/build-release.yml` — manual/versioned release builder.
- `.github/workflows/watch-upstream.yml` — detects new upstream versions and
  opens an issue; it does not deploy.
- `tests/packaged-smoke.mjs` — auth, API guard, SSR, hydration, and console smoke.
- `installer/omniroute-patched-update` — fail-closed VPS installer/rollback tool.
- `docs/OPERATIONS.md` — agent runbook.

## Supported baseline

The current patch set is pinned to upstream `release/v3.8.47` commit
`38d6cd9955d55548dd1f85fff3ab2b477537659d`. A release artifact is valid only
for the exact upstream version, ref, commit, and patch hashes recorded in its manifest.

## What happens on the next update

GitHub checks the newest npm version daily and tries to build it with this
source patch. A green build creates a private verified release, but never
touches the VPS. When the user asks to update, the agent downloads that release
and runs the server updater. If the patch no longer applies or the UI test
fails, CI opens an issue and production remains on the current working version.
