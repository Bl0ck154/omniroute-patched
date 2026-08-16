# OmniRoute 3.8.50 migration and finalization

This document tracks the current migration from the old 3.8.47 overlay to the
3.8.50 line. Repository preparation and production installation remain separate
operations.

## Current preview pin

Compatibility work is pinned to:

- upstream version: `3.8.50`;
- upstream ref: `release/v3.8.50`;
- upstream commit: `6d9336088c48fe7d9c858afb4e95ff28932c047a`.

This commit contains the required Antigravity Gemini 3.7 work, but the ref is a
moving release branch. It is suitable for preparing and testing the overlay, not
for declaring a final production baseline.

## What changed from 3.8.47

### Quota UI patch retired

Do not reapply the legacy `quota-ui.patch`.

Upstream 3.8.50 now covers the important quota UX that the local patch originally
added or motivated: filtering, deterministic provider ordering, smart account
sorting, compact/full layouts, expandable provider groups, quota visibility,
status summaries, tier/provider/environment filters, and reset-credit handling.

The old hard-coded Gemini CLI `free -> pro` override is permanently dropped.

### HEAD response guard patch retired

`head-response-guard.cjs` is already retained by the upstream packaging policy,
so the 3.8.47 packaging patch is no longer configured. The build still verifies
the upstream packaging contract fail-closed.

### Gemini 3.7 uses upstream

The selected upstream source contains Antigravity Gemini 3.7 support and live
authenticated Antigravity chat-model discovery. No local Gemini 3.7 patch is
carried.

### New image overlay patches

Two features remain local because upstream does not expose them through the image
route in this baseline:

- `patches/cloudflare-images.patch`;
- `patches/aihorde-images.patch`.

They are isolated from each other and from quota UI so either can be removed when
upstream gains equivalent support.

## Finalization trigger

When upstream publishes the immutable `v3.8.50` release/tag:

1. resolve the exact tag commit;
2. compare it with the current preview commit;
3. change `config/baseline.json` from `release/v3.8.50` to the immutable tag and
   exact tag commit;
4. apply both image patches with `git apply --check` in configured order;
5. adapt only conflicts caused by final upstream changes;
6. rerun the focused image-adapter tests and existing upstream regression guard;
7. run the full Next + CLI build;
8. `npm pack` and install the actual artifact into the smoke root;
9. verify both overlay markers exist in packed `dist`;
10. run launcher/auth/quota/browser smoke with no page/runtime errors;
11. publish `v3.8.50-overlay.<revision>` only after every gate is green;
12. merge the migration PR only after the immutable baseline is recorded.

No VPS deployment belongs to this checklist.

## Future baseline rule

After 3.8.50 is finalized, future compatibility builds should continue to:

- use immutable upstream releases for publishable artifacts;
- require released Antigravity Gemini 3.7-or-newer capability;
- prefer upstream implementations over local patches;
- keep provider-specific image adapters isolated;
- fail before expensive build/browser work when source patches or focused unit
  tests fail.

## Required release gates

- public-repository hygiene scan;
- exact upstream version/ref/commit verification;
- every configured source patch exists;
- complete patch sequence passes `git apply --check` before mutation;
- Cloudflare Workers AI adapter unit tests;
- AI Horde adapter unit tests;
- lint for both local handler modules and tests;
- GPT-5.6 Responses normalization regression guard;
- complete Next release build;
- CLI release build;
- `npm pack` contains standalone `dist` runtime;
- packed artifact installs into a clean smoke root;
- `cloudflare-workers-ai-image` marker present in packed `dist`;
- `aihorde-image` marker present in packed `dist`;
- unauthenticated `/v1/models` returns `401`;
- authenticated quota dashboard returns `200`;
- stock upstream quota UI hydrates and exposes the Full/Compact layout control;
- no browser `pageerror`, console error, `TypeError`, `ReferenceError`, or internal
  server error in smoke logs.

## Production boundary

A verified GitHub Release is still not deployment. Repository workflows do not
SSH to the VPS and do not modify a running OmniRoute installation. Production
installation remains a separate explicit request through the local updater.
