# Codex Notify Apple Watch Backup

This repository backs up the Codex hooks that escalate unattended Codex completion events into Apple Reminders, so iPhone and Apple Watch can notify from the Reminders app.

## Files

- `hooks/codex-reminder-hook.sh`: schedules/cancels delayed Reminders entries.
- `hooks/codex-notify-wrapper.sh`: handles Codex legacy notify payloads and adds quota text.
- `hooks/codex-stop-wrapper.sh`: handles Codex `Stop` hook payloads as the reliable completion trigger.
- `hooks.json`: installs the `Stop` and `UserPromptSubmit` hooks.
- `config.example.toml`: optional legacy `notify` fallback template. Do not commit your real `~/.codex/config.toml`; it can contain local paths and project names.

The committed hook files use `$HOME` so the repository does not expose a local macOS username.

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
```

The `Stop` hook in `hooks.json` should normally work without relying on the legacy `notify` setting. If you also want the legacy notify fallback, copy the single `notify = ...` line from `config.example.toml` into your existing `~/.codex/config.toml` and replace `YOUR_USER`.
