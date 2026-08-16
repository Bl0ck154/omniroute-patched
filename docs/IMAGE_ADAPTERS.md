# Image-generation overlay adapters

This document records the image-generation extensions carried by the 3.8.50
migration for providers OmniRoute already supports for chat but does not yet
expose through its OpenAI-compatible image route.

Both adapters integrate with the existing public entry point:

```text
POST /v1/images/generations
```

They remain separate source patches so either can be dropped independently when
upstream gains equivalent support.

## Common integration contract

The adapters:

- use OmniRoute's existing image model parsing and route;
- reuse provider credential selection and per-connection proxy selection at the
  route layer;
- preserve request cancellation with `AbortSignal` where upstream calls allow it;
- normalize success to OmniRoute's OpenAI-compatible image response;
- sanitize upstream errors before they are returned/logged;
- expose image models through `open-sse/config/imageRegistry.ts`;
- include focused non-live unit tests in CI;
- are verified again after packing by searching the compiled `dist` artifact for
  their format markers.

## Cloudflare Workers AI images

Implemented by `patches/cloudflare-images.patch`.

### Connection reuse

The image provider uses the same `cloudflare-ai` provider id and `cf` alias as the
chat provider. It reuses:

- API token from the selected connection;
- Account ID from `providerSpecificData.accountId`, top-level credential metadata,
  or the existing `CLOUDFLARE_ACCOUNT_ID` fallback.

### Initial image models

The preview patch registers:

- `@cf/black-forest-labs/flux-1-schnell`;
- `@cf/bytedance/stable-diffusion-xl-lightning`.

The dedicated handler calls the account-scoped Workers AI `/ai/run/{model}`
endpoint. Because individual Workers AI image models have different parameter
contracts, the initial adapter deliberately translates only a narrow verified
subset:

- `prompt`;
- optional `steps` clamped to the supported small range used by the initial
  models;
- optional deterministic `seed`;
- `n` implemented as bounded repeated executions rather than assuming an
  unsupported provider-side batch field.

OpenAI `size`/`quality` are not blindly forwarded. Model-specific dimensions can
be added later only with explicit tests.

The response parser accepts the Workers AI JSON image envelope and raw image
bytes, then normalizes results to `b64_json`.

## AI Horde images

Implemented by `patches/aihorde-images.patch`.

AI Horde image generation uses the native asynchronous Horde API rather than the
OpenAI-compatible text facade.

### Authentication and model selection

- a configured AI Horde API key is preferred;
- without a configured key, the adapter uses Horde's anonymous key path;
- `aihorde/auto` omits a model list and lets the Horde scheduler choose an
  available worker/model;
- an explicit `aihorde/<model name>` route pins that model without requiring the
  dynamic worker roster to be hard-coded into the image registry.

### Job lifecycle

The adapter:

1. submits to the native async generation endpoint;
2. validates the returned generation id;
3. polls the lightweight check endpoint at a bounded interval;
4. stops on completion, timeout, or request cancellation;
5. performs a final status fetch for generation results;
6. sends a best-effort cancel request after timeout/abort/error once a job id
   exists.

Defaults are intentionally bounded: one-to-four images, a finite overall timeout,
and a poll interval no faster than one second.

### Result normalization

Horde R2 image URLs can be returned directly for ordinary URL responses. For
`response_format=b64_json`, the adapter downloads the result through OmniRoute's
existing bounded SSRF/DNS-rebinding-safe remote image fetcher, then returns base64.
Data-URI results are normalized without an additional remote fetch.

## Current unit coverage

### Cloudflare

- Account ID resolution from provider-specific connection data;
- narrow request translation and step/seed bounding;
- Workers AI REST envelope image extraction.

### AI Horde

- dimension normalization to Horde-friendly multiples;
- bounded `n` and step values;
- scheduler-driven `auto` mode without a pinned model;
- explicit model pinning;
- seed preservation.

The release pipeline also validates the compiled artifact and packaged launcher.
Live external image calls are intentionally not run in CI so builds do not spend
provider quota or depend on volunteer capacity/network availability.

## Follow-up tests

Useful future hardening once the baseline is final:

- mocked Cloudflare 4xx/5xx and raw-binary responses;
- Cloudflare abort behavior;
- mocked AI Horde queued -> running -> complete lifecycle;
- AI Horde terminal failure, malformed job id, timeout and abort;
- proof that a poll failure never resubmits the generation job;
- route-level credential fallback tests for both providers.

## Upstream-first rule

Before rebasing either patch to a future OmniRoute version, inspect that upstream
release. If equivalent native image support exists, remove the local patch and
keep only regression coverage or genuinely missing compatibility behavior.
