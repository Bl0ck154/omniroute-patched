# Planned image-generation adapters

This document defines the intended shape of optional image-generation extensions
for providers that OmniRoute already knows as LLM providers but does not yet
expose through its OpenAI-compatible image API.

The adapters are intentionally documented before implementation so the next
baseline refresh can keep provider work isolated from quota-UI work.

## Common contract

Both adapters should integrate with OmniRoute's existing image route rather than
creating a second public API surface.

Expected public entry point:

```text
POST /v1/images/generations
```

The adapter layer should:

- parse `provider/model` consistently with existing image providers;
- reuse OmniRoute credential selection and per-connection proxy handling;
- preserve request cancellation via `AbortSignal`;
- normalize successful results to the existing OpenAI-compatible image response;
- normalize upstream errors without leaking secrets or raw credentials;
- participate in provider/account fallback where the upstream architecture allows it;
- expose provider/model capability metadata so image models are discoverable;
- have unit tests that do not call paid/live APIs in CI.

## Cloudflare Workers AI images

Cloudflare Workers AI uses an account-scoped endpoint rather than the ordinary
OpenAI chat-compatible endpoint used by the existing `cloudflare-ai` provider.
The image adapter therefore needs a dedicated request builder.

Planned responsibilities:

1. Reuse the existing Cloudflare account id and API token connection data.
2. Map an OmniRoute image model id to the Workers AI model endpoint.
3. Translate supported OpenAI image parameters to Cloudflare request fields.
4. Handle binary and/or encoded image responses according to the selected model.
5. Return standard OmniRoute/OpenAI image output (`url` or `b64_json` according to
   the route's existing contract).
6. Preserve Cloudflare errors and rate-limit metadata in sanitized form.

Keep the initial implementation small: support a verified text-to-image model
first, then add model-specific options only when they are backed by tests.

## AI Horde images

AI Horde image generation is asynchronous. It cannot be implemented as a normal
single-request OpenAI-compatible executor.

The adapter needs an explicit job lifecycle:

1. submit a generation job;
2. receive and validate the job id;
3. poll status at a bounded interval;
4. stop on success, failure, timeout, or request cancellation;
5. fetch/normalize the final image result;
6. cleanly report queue/capacity failures.

Requirements:

- support the documented anonymous key path as well as a real user key;
- use a bounded overall deadline and bounded poll count;
- never busy-loop;
- propagate `AbortSignal` to polling;
- avoid retrying a submitted job in a way that creates duplicate generations;
- distinguish queue delay from terminal generation failure;
- keep Kudos/account metadata out of logs unless sanitized.

## Tests to add with implementation

### Cloudflare

- request URL/account/model mapping;
- auth header construction without secret snapshots;
- request field translation;
- binary/base64 response normalization;
- upstream 4xx/5xx normalization;
- cancellation path.

### AI Horde

- anonymous and authenticated submission;
- queued -> running -> completed polling sequence;
- terminal failure;
- timeout;
- abort during polling;
- malformed/missing job id;
- no duplicate submit on poll failure;
- image result normalization.

## Upstream-first rule

Before implementing or porting either adapter, inspect the selected upstream
release. If OmniRoute has gained equivalent image support, prefer upstream and
add only regression coverage or missing compatibility fixes here.
