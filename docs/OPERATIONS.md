# Operations runbook

## User request

The normal user-facing request is:

> Онови OmniRoute з нашого репо.

## Agent workflow

1. Read the currently installed OmniRoute version and build manifest.
2. Find an exact matching verified release in `Bl0ck154/omniroute-patched`.
3. If no release exists, dispatch `build-release.yml` for the target version.
4. If the source patch conflicts or tests fail, stop. Adapt the TSX patch in a
   branch, review the diff, and rerun CI. Never patch compiled chunks.
5. Download the `.tgz`, manifest, and checksums through authenticated GitHub CLI.
6. Upload them to a root-only temporary directory on the VPS.
7. Run `/usr/local/sbin/omniroute-patched-update install ...`.
8. Verify the production dashboard, `/v1/models` API-key guard, service state,
   and runtime logs. Keep the previous release until the user confirms the UI.

## Required CI gates

- Exact upstream tag and commit recorded.
- Source patch applies with no fuzz or rejected hunks.
- Targeted ESLint passes.
- Official release build succeeds.
- `npm pack` contains the standalone `dist` application.
- Packaged `bin/omniroute.mjs` starts, not only `next start`.
- Unauthenticated `/v1/models` returns `401`.
- Authenticated `/dashboard/quota` returns `200`.
- Browser hydration renders `Quota UI patch` with mocked provider/quota data.
- No browser `pageerror`, console error, `TypeError`, or `ReferenceError`.

## Database safety

The package release and `DATA_DIR` are separate. Before a production switch,
the updater creates a local database backup. Canary uses an isolated temporary
`DATA_DIR`; it never opens the production SQLite database concurrently.

If a release introduces an irreversible database migration, automatic install
must stop and require an explicit maintenance-window decision.

## Rollback

`omniroute-patched-update rollback` switches `/opt/omniroute-current` to the
previous version and restarts the user service. Database restoration is not
automatic because it can discard writes made after the upgrade; migration
compatibility must be evaluated separately.

