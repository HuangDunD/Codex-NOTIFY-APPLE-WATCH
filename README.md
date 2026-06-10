# Codex Notify Apple Watch Backup

This repository backs up the Codex hooks that escalate unattended Codex completion events into Apple Reminders, so iPhone and Apple Watch can notify from the Reminders app.

## Files

- `hooks/codex-reminder-hook.sh`: schedules/cancels delayed Reminders entries.
- `hooks/codex-notify-wrapper.sh`: handles Codex legacy notify payloads and adds quota text.
- `hooks/codex-stop-wrapper.sh`: handles Codex `Stop` hook payloads as the reliable completion trigger.
- `hooks.json`: installs the `Stop` and `UserPromptSubmit` hooks.

The committed hook files use `$HOME` so the repository does not expose a local macOS username.

## Current Behavior

- If Codex is truly frontmost when a completion event arrives, no reminder is created.
- If Codex is only visible through Stage Manager but not frontmost, a reminder is scheduled.
- If Codex becomes frontmost within 60 seconds, the pending reminder is cancelled.
- If a new prompt is submitted within 60 seconds, the pending reminder is cancelled.
- If still unattended after 60 seconds, a Reminder is created in the `Codex` reminders list.
- When a background completion is scheduled, the hook sets Codex's Dock badge to `1`.
- The Dock badge is cleared when Codex becomes frontmost or a new prompt is submitted. It can remain after the 60-second Reminder is created, so the Dock still shows an unread completion until Codex is opened.

## Restore

```sh
mkdir -p ~/.codex/hooks
cp hooks/*.sh ~/.codex/hooks/
chmod +x ~/.codex/hooks/*.sh
cp hooks.json ~/.codex/hooks.json
```

The `Stop` hook in `hooks.json` is the primary completion trigger. Do not add a custom `notify = ...` line unless you intentionally want to override Codex's native notification path; overriding `notify` can interfere with native Dock badge behavior.
