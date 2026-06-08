# Codex Notify Apple Watch Backup

This repository backs up the Codex hooks that escalate unattended Codex completion events into Apple Reminders, so iPhone and Apple Watch can notify from the Reminders app.

## Files

- `hooks/codex-reminder-hook.sh`: schedules/cancels delayed Reminders entries.
- `hooks/codex-notify-wrapper.sh`: handles Codex legacy notify payloads and adds quota text.
- `hooks/codex-stop-wrapper.sh`: handles Codex `Stop` hook payloads as the reliable completion trigger.
- `hooks.json`: installs the `Stop` and `UserPromptSubmit` hooks.
- `config.toml`: keeps the legacy `notify` chain to the wrapper as a compatibility fallback.

## Current Behavior

- If Codex is truly frontmost when a completion event arrives, no reminder is created.
- If Codex is only visible through Stage Manager but not frontmost, a reminder is scheduled.
- If Codex becomes frontmost within 60 seconds, the pending reminder is cancelled.
- If a new prompt is submitted within 60 seconds, the pending reminder is cancelled.
- If still unattended after 60 seconds, a Reminder is created in the `Codex` reminders list.

## Restore

```sh
mkdir -p ~/.codex/hooks
cp hooks/*.sh ~/.codex/hooks/
chmod +x ~/.codex/hooks/*.sh
cp hooks.json ~/.codex/hooks.json
cp config.toml ~/.codex/config.toml
```

After restoring, restart Codex if the legacy `notify` path does not take effect immediately. The `Stop` hook in `hooks.json` should normally work without relying on that legacy reload.
