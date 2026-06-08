#!/bin/zsh

set -u

NOTIFY_WRAPPER="/Users/hcy/.codex/hooks/codex-notify-wrapper.sh"
STATE_DIR="$HOME/.codex/hooks/state"
LOG_FILE="$STATE_DIR/reminder-hook.log"

mkdir -p "$STATE_DIR"

hook_json="$(/bin/cat)"
hook_event_name="$(printf '%s' "$hook_json" | /usr/bin/jq -r '.hook_event_name // empty' 2>/dev/null)"

if [[ "$hook_event_name" != "Stop" ]]; then
  printf '%s ignored non-Stop hook event: %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$hook_event_name" >> "$LOG_FILE"
  exit 0
fi

notification_json="$(printf '%s' "$hook_json" | /usr/bin/jq -c '
  {
    type: "agent-turn-complete",
    "thread-id": (.session_id // ""),
    "turn-id": (.turn_id // ""),
    cwd: (.cwd // ""),
    client: "Codex Stop Hook",
    "last-assistant-message": (.last_assistant_message // "")
  }
' 2>/dev/null)"

if [[ -z "$notification_json" ]]; then
  printf '%s failed to build notification from Stop hook input\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
  exit 0
fi

"$NOTIFY_WRAPPER" "$notification_json"
