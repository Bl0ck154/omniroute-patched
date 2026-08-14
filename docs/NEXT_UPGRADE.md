# Next OmniRoute baseline refresh

This document defines the preparation work for the next `omniroute-patched`
baseline. It intentionally separates repository preparation from production
installation.

## Target selection

Use an immutable upstream GitHub release/tag, not a moving `release/*` branch,
unless a temporary preview build is explicitly requested for testing.

The preferred next baseline must:

1. be at least the version in `config/upgrade-policy.json`;
2. expose working Antigravity Gemini 3.7 support in the upstream source;
3. have a fixed upstream commit recorded in `config/baseline.json`;
4. pass the packaged launcher, dashboard, auth guard, and browser smoke tests.

A preview branch can be inspected for compatibility, but it must not silently
replace the production baseline.

## Patch migration rules

### Quota UI

Do not reapply the legacy 3.8.47 `quota-ui.patch` wholesale.

Newer upstream releases already provide substantial quota UX: filtering,
provider ordering, compact/full layouts, expandable provider sections, account
sorting, visibility controls, and improved plan resolution.

When the baseline advances, compare the desired user experience against stock
upstream and carry only still-useful deltas. Candidate extras are:

- explicit manual sorting modes (available / empty / priority / name), if still useful;
- a true list view with compact quota bars, if upstream compact cards are insufficient;
- optional hiding/showing of disabled connections;
- explicit priority display where it improves routing visibility.

Drop the old hard-coded Gemini CLI `free -> pro` plan override. Newer upstream
plan resolution should be the source of truth.

### HEAD response guard packaging patch

`patches/head-response-guard-packaging.patch` exists for the 3.8.47 baseline.
The fix is upstream in newer releases. Remove this patch from the configured
patch list as soon as the baseline advances to a version that contains the
upstream packaging fix.

### Gemini 3.7

Prefer upstream support once it is released and verified. If upstream ships a
stable release before the integration is complete, a small isolated compatibility
patch may be considered, but it must have focused tests for:

- public model discovery;
- tier mapping / upstream model id translation;
- thinking-level translation;
- quota bucket display;
- account-specific provisioning failures.

Do not treat a Google-side `404 Requested entity was not found` as proof that the
router mapping is wrong when the account itself has not yet been provisioned.

## Image provider extensions

Cloudflare Workers AI and AI Horde are useful chat providers upstream but their
image APIs require dedicated adapters. See `docs/IMAGE_ADAPTERS.md`.

These adapters should remain separate from the baseline refresh so they can be
ported or dropped independently if upstream later implements equivalent support.

## Test matrix for the next baseline

Required before publishing a patched release:

- exact upstream version/ref/commit verification;
- source patches apply with zero fuzz;
- targeted lint/type checks for every touched upstream module;
- upstream regression tests related to modified providers/routes;
- complete Next release build;
- CLI release build;
- `npm pack` contains the standalone runtime;
- installation of the real packed artifact into a clean smoke root;
- unauthenticated `/v1/models` returns `401`;
- authenticated quota dashboard returns `200`;
- browser page hydrates with no `pageerror`, `TypeError`, `ReferenceError`, or console error;
- provider-specific image adapter tests when those adapters are enabled.

## Production boundary

Publishing a release is not deployment. No workflow in this repository should
SSH into a VPS or automatically modify a running OmniRoute installation.
Production installation remains a separate explicit action through the local
updater.
