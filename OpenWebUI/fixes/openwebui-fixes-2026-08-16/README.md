# OpenWebUI Open WebUI Fixes — 2026-08-16

Validated against:

- Open WebUI: v0.11.0
- Container image: ghcr.io/open-webui/open-webui:v0.11.0
- Host project: OpenWebUI / validation-host
- Validation date: 2026-08-16

This archive contains two independently validated fixes.

## 1. Frontend setDefaults() race fix

### Symptom

A model configured with Web Search in `defaultFeatureIds` could intermittently open a new chat with:

    features.web_search = false

even though Web Search was intended to default ON.

### Root cause

`Chat.svelte` uses a `settingDefaults` guard around `setDefaults()`.

Concurrent calls could occur while chat/model initialization was resetting feature state. A second `setDefaults()` call encountered the guard and returned immediately, so the defaults it was supposed to restore were silently dropped.

### Fix

The compiled frontend bundle is changed so that:

- a concurrent `setDefaults()` call marks one pending rerun;
- the active call completes normally;
- the pending call is then executed once.

This coalesces concurrent calls without forcing Web Search ON globally.

### Regression validation

Validated behavior:

- New chat: Web Search defaults ON.
- Manual per-chat Web Search OFF: backend receives `features.web_search = false`.
- When OFF, `search_web` is absent from the backend tool surface.
- Reopening a new chat restores the configured default ON state.

The patched frontend file was byte-for-byte reconstructed from the original using only the three intended substitutions.

Patched SHA-256:

    718ba26af670720e83446d2a3b154ac76aaea450de79266a1d221f38491ca47b

## 2. SafeWebBaseLoader datetime preservation fix

### Symptom

GitHub release pages visibly rendered dates such as:

    27 Jul 09:30

while the HTML contained the authoritative machine-readable value:

    datetime="2026-07-27T09:30:15Z"

Open WebUI's extraction path used BeautifulSoup `get_text()`, which discarded HTML attributes. The model therefore received the day/month/time but not the year and could hallucinate a year from prior knowledge.

Observed failure:

- release: v0.11.0
- extracted visible date: 27 Jul 09:30
- model incorrectly answered: July 27, 2024

Raw GitHub HTML contained:

    2026-07-27T09:30:15Z

### Root cause

`SafeWebBaseLoader` converted the BeautifulSoup document directly with:

    soup.get_text(...)

This strips `datetime=` attributes from elements such as `<relative-time>` and `<time>`.

### Fix

A helper named `_text_with_datetimes()` appends the value of any `datetime` attribute to the element's text before normal text extraction.

Example extracted form:

    27 Jul 09:30 [2026-07-27T09:30:15Z]

Both synchronous and asynchronous document extraction paths use the helper.

### Regression validation

Repeated mixed KB + public-web tests correctly returned:

- validation-host: internal-ip
- Open WebUI release: v0.11.0
- release date: July 27, 2026

Python syntax validation also passed with `python -m py_compile`.

## Archive contents

    frontend/BLLL3FN7.js.original
    frontend/BLLL3FN7.js.patched
    backend/utils.py.original
    backend/utils.py.patched
    openwebui-openwebui-fixes.diff
    SOURCE_SHA256SUMS

Install and rollback scripts are included separately.

## Important compatibility note

These files are version-specific.

Do not blindly copy the patched compiled JavaScript or backend Python file onto a different Open WebUI release. Prefer applying the logical source changes to the matching upstream version, then rebuild/retest.

Always make backups before applying any patch.

## Why these fixes may benefit other users

The frontend race is a general concurrency/state-initialization issue and is not specific to OpenWebUI.

The datetime extraction issue is also general: any website that exposes a precise date/time in an HTML `datetime` attribute while displaying abbreviated text can lose information through plain `get_text()` extraction.

