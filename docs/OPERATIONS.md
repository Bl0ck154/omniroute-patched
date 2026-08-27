# Operations runbook

## Two separate operations

Repository preparation and production deployment are different tasks.

### Build execution policy

Full OmniRoute build/test/package jobs are resource-heavy and must **not** run on the production VPS.
For this public repository, use the standard GitHub-hosted runner in the manual
`Build patched OmniRoute release` workflow for full Next builds, CLI builds,
`npm pack`, Playwright/browser smoke tests, and release artifact generation.

The production VPS may be used only for lightweight inspection and for installing,
verifying, or rolling back an already-built release. Do not clone upstream and run
`npm ci`, `npm run build`, `npm run build:cli`, Playwright installation, or the full
release test matrix on production unless an explicit emergency/debug request says
to do so.

Do not avoid GitHub Actions merely to conserve Actions minutes for this repository:
it is public and the release workflow uses a standard GitHub-hosted runner. This
rule does not automatically apply to private repositories or larger runners.

### Prepare/update the patched repository

1. Read `config/upgrade-policy.json` and the current `config/baseline.json`.
2. Select a published upstream GitHub release/tag that satisfies the required capabilities.
3. Record the exact upstream commit before publishing anything.
4. Compare current upstream behavior with each local patch; drop behavior that is already upstream.
5. Port only still-useful deltas in a branch. Never patch compiled Next.js chunks.
6. Run public-repository hygiene checks before applying/building patches.
7. Run the full packaged release test matrix on the standard GitHub-hosted Actions runner.
8. Publish a verified GitHub Release only if every gate passes.
9. Stop there unless production deployment was separately and explicitly requested.

### Deploy an already-prepared release

A normal explicit deployment request can be phrased as:

> Онови OmniRoute з нашого репо.

Then:

1. Read the currently installed OmniRoute version and build manifest.
2. Select the exact matching verified release from `Bl0ck154/omniroute-patched`.
3. Download the `.tgz`, manifest, and checksums from GitHub.
4. Upload them to a root-only temporary directory on the VPS.
5. Run `/usr/local/sbin/omniroute-patched-update install ...`.
6. Verify the production dashboard, `/v1/models` API-key guard, service state,
   and runtime logs.
7. Keep the previous release available for rollback until the new version is accepted.

For the v3.8.50 migration, disable the legacy `45-image-auth-guard.conf` drop-in
only after confirming the packaged source contains `imageCredentialRetry` and its
account-fallback tests passed. Keep the drop-in and patcher in the upgrade backup;
they remain required if rolling the package back to v3.8.47.

A GitHub Release is not deployment. Repository workflows must not SSH to or
silently modify production.

## Required release gates

- Public-repository hygiene scan passes.
- Exact upstream ref and commit recorded.
- Source patches apply with no fuzz or rejected hunks.
- Every configured patch file exists.
- Targeted lint/type checks pass for touched upstream code.
- Large upstream integration files that are not lint-clean at the pinned tag are
  validated by focused regression tests and the full release build; lint remains
  mandatory for standalone modules introduced or directly owned by this overlay.
- Existing compatibility assertions remain valid or are deliberately migrated.
- Official Next release build succeeds.
- CLI release build succeeds.
- `npm pack` contains the standalone `dist` application.
- The real packed artifact installs into a clean smoke root.
- Packaged `bin/omniroute.mjs` starts, not only `next start`.
- Unauthenticated `/v1/models` returns `401`.
- Authenticated `/dashboard/quota` returns `200`.
- Browser hydration succeeds with no `pageerror`, console error, `TypeError`, or `ReferenceError`.
- Legacy Quota UI marker assertions are required only while that patch is configured.
- Provider/image adapter tests pass when those optional adapters are enabled.

## Database safety

The package release and `DATA_DIR` are separate. Before a production switch,
the updater creates a local database backup. Canary uses an isolated temporary
`DATA_DIR`; it never opens the production SQLite database concurrently.
Only active database files directly under `DATA_DIR` are copied. Existing
backup histories are deliberately excluded to avoid recursive duplication and
disk exhaustion.

If a release introduces an irreversible database migration, installation must
stop for an explicit compatibility decision. Package rollback and database
rollback are not the same operation.

## Rollback

`omniroute-patched-update rollback` switches `/opt/omniroute-current` to the
previous package and restarts the user service. Database restoration is not
automatic because it can discard writes made after the upgrade; migration
compatibility must be evaluated separately.
