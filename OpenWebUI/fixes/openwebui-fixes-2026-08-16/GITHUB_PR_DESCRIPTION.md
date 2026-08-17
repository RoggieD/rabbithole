# Fix: prevent dropped model default features during Chat initialization

## Summary

This patch fixes a race condition in `Chat.svelte` where concurrent `setDefaults()` calls could cause configured model default features to be skipped.

## Problem

`setDefaults()` used a boolean lock:

    if (settingDefaults) return;

When initialization triggered multiple calls close together, later calls exited without applying defaults.

This could result in:

- `defaultFeatureIds` not being applied
- Web Search defaults not restoring on new chats
- inconsistent feature state between sessions

## Solution

The patch changes the lock behavior:

- concurrent calls set a pending execution flag
- the active initialization completes
- one pending execution runs afterward

This preserves existing behavior while preventing dropped initialization work.

## Validation

Tested behavior:

- New chat applies configured Web Search defaults.
- User manually disabling Web Search remains respected.
- Backend tool exposure matches the selected state.

## Additional related fix

A separate backend extraction fix preserves HTML `datetime` attributes during web extraction.

This prevents abbreviated visible dates from replacing authoritative machine-readable timestamps.

Example:

Before:

    27 Jul 09:30

After:

    27 Jul 09:30 [2026-07-27T09:30:15Z]

## Compatibility

Validated with:

- Open WebUI v0.11.0
