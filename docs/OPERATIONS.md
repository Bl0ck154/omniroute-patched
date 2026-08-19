# Operations runbook

## Two separate operations

Repository preparation and production deployment are different tasks.

### Prepare/update the overlay repository

1. Read `config/upgrade-policy.json` and `config/baseline.json`.
2. For publishable releases, select an immutable upstream GitHub release/tag that
   satisfies the required capabilities.
3. Record the exact upstream commit before publishing anything.
4. Compare current upstream behavior with each local patch; delete behavior that
   is already upstream instead of carrying stale patches forward.
5. Port only still-useful deltas in a branch. Never patch compiled Next.js chunks.
6. Run the public-repository hygiene scan.
7. Apply the complete configured patch sequence with `git apply --check` before
   each patch is applied.
8. Run focused overlay lint/unit tests before Chromium and full build work.
9. Run the complete packaged release test matrix.
10. Publish a verified public GitHub Release only if every gate passes.
11. Stop there unless production deployment was separately and explicitly requested.

The current 3.8.50 migration is pinned to a fixed commit on a moving `release/*`
branch for compatibility work. Do not treat that preview pin as a final deployable
baseline. Re-pin to the immutable `v3.8.50` tag commit and rerun all gates first.

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

A GitHub Release is not deployment. Repository workflows must not SSH to or
silently modify production.

## Required release gates

- Public-repository hygiene scan passes.
- Exact upstream ref and commit recorded.
- Every configured patch file exists.
- Source patches apply in configured order with no rejected hunks.
- Post-apply integration guards find both configured image handlers and registry markers.
- Targeted lint passes for local overlay handlers/tests.
- Cloudflare Workers AI image adapter unit tests pass.
- AI Horde image adapter unit tests pass.
- Existing Responses normalization compatibility assertion remains valid.
- Upstream packaging policy still includes `head-response-guard.cjs`.
- Official Next release build succeeds.
- CLI release build succeeds.
- `npm pack` contains the standalone `dist` application.
- The real packed artifact installs into a clean smoke root.
- Packed `dist` contains `cloudflare-workers-ai-image`.
- Packed `dist` contains `aihorde-image`.
- Packaged `bin/omniroute.mjs` starts, not only `next start`.
- Unauthenticated `/v1/models` returns `401`.
- Authenticated `/dashboard/quota` returns `200`.
- Stock upstream quota UI hydrates and exposes its Full/Compact layout control.
- Browser hydration succeeds with no `pageerror`, console error, `TypeError`,
  `ReferenceError`, or internal server error.

The legacy Quota UI DOM marker is no longer a release gate. That patch is retired
on the 3.8.50 migration.

## Release naming and manifests

- Historical schema-1 releases keep their `v<version>-quota-ui.<revision>` identity.
- New schema-2 releases use `v<version>-overlay.<revision>`.
- Schema-2 manifests list every source patch and SHA-256 and identify the overlay
  as `omniroute-patched`.
- The VPS updater accepts both schemas so historical releases remain usable for
  rollback/recovery, while schema-2 packages are checked for both image-adapter
  markers before canary startup.

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
