#!/bin/zsh

set -u

REMINDER_HOOK="$HOME/.codex/hooks/codex-reminder-hook.sh"
LOG_FILE="$HOME/.codex/hooks/state/reminder-hook.log"

printf '%s received Codex notification: %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"

notification_json="${1:-}"
thread_id="$(printf '%s' "$notification_json" | /usr/bin/jq -r '."thread-id" // empty' 2>/dev/null)"
notification_cwd="$(printf '%s' "$notification_json" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null)"
usage_text=""

case "$notification_cwd" in
  "$HOME/.codex/memories"|"$HOME/.codex/memories/"*)
    printf '%s ignored internal Codex completion: cwd=%s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$notification_cwd" >> "$LOG_FILE"
    exit 0
    ;;
esac

if [[ -n "$thread_id" ]]; then
  rollout_file="$(/usr/bin/find "$HOME/.codex/sessions" "$HOME/.codex/archived_sessions" \
    -type f -name "*-$thread_id.jsonl" -print 2>/dev/null | /usr/bin/head -n 1)"

  if [[ -n "$rollout_file" ]]; then
    latest_usage="$(/usr/bin/grep '"type":"token_count"' "$rollout_file" 2>/dev/null | /usr/bin/tail -n 1)"
    if [[ -n "$latest_usage" ]]; then
      usage_text="$(printf '%s' "$latest_usage" | /usr/bin/jq -r '
        .payload.rate_limits as $r |
        if ($r.primary.used_percent != null and $r.secondary.used_percent != null) then
          "Codex 额度：" +
          "5小时已用 " + ($r.primary.used_percent | tostring) + "%（剩余 " + ((100 - $r.primary.used_percent) | tostring) + "%）；" +
          "每周已用 " + ($r.secondary.used_percent | tostring) + "%（剩余 " + ((100 - $r.secondary.used_percent) | tostring) + "%）"
        else empty end
      ' 2>/dev/null)"
    fi
  fi
fi

[[ -z "$usage_text" ]] && usage_text="Codex 额度：暂时无法读取"
printf '%s completion usage snapshot: %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$usage_text" >> "$LOG_FILE"
"$REMINDER_HOOK" schedule-completion "$usage_text"
