# OmniRoute Patched — archived

> **Archived on 2026-08-29.** Active development moved to the direct fork: `Bl0ck154/OmniRoute`, branch `production`.
>
> This repository is retained only as historical documentation for the old source-patch overlay and its releases. New custom changes now live as normal commits in the fork. Generic fixes should be developed on focused `fix/*` branches and proposed upstream to `diegosouzapw/OmniRoute`.

## Replacement architecture

- `Bl0ck154/OmniRoute:release/v3.8.51` tracks the upstream release branch.
- `Bl0ck154/OmniRoute:production` is the deployable source of truth for custom changes.
- `.github/workflows/build-custom-release.yml` builds and verifies production artifacts directly from the fork; no patch application layer is involved.
- `ops/omniroute-production-update` performs canary validation, database backup, atomic release switching, health checks, and rollback.
- The former Quota UI and HEAD-response packaging patches were already inactive before this migration and were not carried forward.

## Historical repository

This repository previously provided a version-pinned source-level overlay for OmniRoute. CI cloned an exact upstream ref, applied a configured patch set, built the Linux npm package, ran package/browser smoke tests, and published versioned patched releases.

The final active baseline was upstream `v3.8.50` at commit `5458026c216f77a3da68ea49152dc33470cfe2cb`, patch revision 10. Its active patch set covered Codex non-stream SSE compatibility, server/runtime fixes, the scoped Etsy image artifact sink, and Codex image failover behavior.

Historical releases and commits remain available for rollback/audit purposes. Do not add new fixes here; use the direct fork instead.
