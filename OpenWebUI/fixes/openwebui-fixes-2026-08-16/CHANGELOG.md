# Changelog

## OpenWebUI Open WebUI Fixes — 2026-08-16

Validated against Open WebUI v0.11.0.

## Fixed

### Chat feature default initialization race

Fixed a race condition in `Chat.svelte` where concurrent `setDefaults()` calls could silently drop model default features.

Before:

- A second initialization call returned immediately when initialization was already active.
- `defaultFeatureIds` could fail to apply.

After:

- Concurrent calls queue a pending execution.
- The active initialization completes.
- One pending execution runs afterward.

Validated:

- New chats restore configured Web Search defaults.
- Manual Web Search disable remains respected.

### Web datetime preservation

Fixed extraction of machine-readable timestamps from HTML elements containing `datetime` attributes.

Example:

Before:

    27 Jul 09:30

After:

    27 Jul 09:30 [2026-07-27T09:30:15Z]

This prevents loss of authoritative date information during web extraction.

