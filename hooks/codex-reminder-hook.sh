#!/bin/zsh

set -u

STATE_DIR="$HOME/.codex/hooks/state"
LOG_FILE="$STATE_DIR/reminder-hook.log"
DELAY_SECONDS=60
SCRIPT_PATH="${0:A}"
REMINDER_LIST="Codex"

mkdir -p "$STATE_DIR"

log_message() {
  printf '%s %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

pending_file() {
  printf '%s/%s.pending\n' "$STATE_DIR" "$1"
}

body_file() {
  printf '%s/%s.body\n' "$STATE_DIR" "$1"
}

frontmost_file() {
  printf '%s/%s.frontmost\n' "$STATE_DIR" "$1"
}

is_codex_frontmost() {
  local bundle_id
  bundle_id="$(/usr/bin/osascript -e 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true' 2>/dev/null)"
  [[ "$bundle_id" == "com.openai.codex" ]] && printf '1\n' || printf '0\n'
}

cancel_kind() {
  /bin/rm -f "$(pending_file "$1")"
  /bin/rm -f "$(body_file "$1")"
  /bin/rm -f "$(frontmost_file "$1")"
}

create_reminder() {
  local kind="$1"
  local extra_body="${2:-}"
  local title body

  if [[ "$kind" == "approval" ]]; then
    title="Codex 等待审批"
    body="一分钟内未处理，请返回 Codex 审批。"
  else
    title="Codex 任务已完成"
    body="一分钟内未查看，请返回 Codex 查看结果。"
    if [[ "$extra_body" =~ '5小时已用 '[0-9.]+%'（剩余 '([0-9.]+)%'）；每周已用 '[0-9.]+%'（剩余 '([0-9.]+)%'）' ]]; then
      title="Codex 完成｜5h剩${match[1]}%｜周剩${match[2]}%"
    fi
  fi

  if [[ -n "$extra_body" ]]; then
    body="$body"$'\n'"$extra_body"
  fi

  /usr/bin/osascript - "$REMINDER_LIST" "$title" "$body" <<'APPLESCRIPT'
on run argv
  set reminderListName to item 1 of argv
  set reminderTitle to item 2 of argv
  set reminderBody to item 3 of argv
  tell application "Reminders"
    set alertTime to (current date) + 5
    set reminderList to list reminderListName
    make new reminder at reminderList with properties {name:reminderTitle, body:reminderBody, completed:false, due date:alertTime, remind me date:alertTime}
  end tell
end run
APPLESCRIPT
}

run_worker() {
  local kind="$1"
  local token="$2"
  local file
  local elapsed=0
  file="$(pending_file "$kind")"

  while (( elapsed < DELAY_SECONDS )); do
    [[ -f "$file" ]] || exit 0
    [[ "$(<"$file")" == "$token" ]] || exit 0

    if [[ "$kind" == "completion" ]] &&
       [[ -f "$(frontmost_file "$kind")" ]] &&
       [[ "$(<"$(frontmost_file "$kind")")" == "0" ]] &&
       [[ "$(is_codex_frontmost)" == "1" ]]; then
      log_message "cancelled completion reminder: Codex became frontmost"
      cancel_kind "$kind"
      exit 0
    fi

    /bin/sleep 2
    (( elapsed += 2 ))
  done

  [[ -f "$file" ]] || exit 0
  [[ "$(<"$file")" == "$token" ]] || exit 0

  local extra_body=""
  [[ -f "$(body_file "$kind")" ]] && extra_body="$(<"$(body_file "$kind")")"

  if create_reminder "$kind" "$extra_body" >> "$LOG_FILE" 2>&1; then
    log_message "created $kind reminder"
  else
    log_message "failed to create $kind reminder"
  fi
  cancel_kind "$kind"
}

schedule_kind() {
  local kind="$1"
  local extra_body="${2:-}"
  local token

  if [[ "$kind" == "completion" ]] && [[ "$(is_codex_frontmost)" == "1" ]]; then
    log_message "skipped completion reminder: Codex already frontmost"
    cancel_kind "$kind"
    exit 0
  fi

  token="$$-$(/bin/date +%s)-$RANDOM"
  printf '%s\n' "$token" > "$(pending_file "$kind")"
  printf '%s\n' "$(is_codex_frontmost)" > "$(frontmost_file "$kind")"
  if [[ -n "$extra_body" ]]; then
    printf '%s\n' "$extra_body" > "$(body_file "$kind")"
  else
    /bin/rm -f "$(body_file "$kind")"
  fi
  /usr/bin/nohup "$SCRIPT_PATH" worker "$kind" "$token" >> "$LOG_FILE" 2>&1 &
}

case "${1:-}" in
  schedule-approval)
    schedule_kind approval
    ;;
  schedule-completion)
    cancel_kind approval
    schedule_kind completion "${2:-}"
    ;;
  cancel-approval)
    cancel_kind approval
    ;;
  cancel-all)
    cancel_kind approval
    cancel_kind completion
    ;;
  worker)
    run_worker "${2:?missing reminder kind}" "${3:?missing token}"
    ;;
  *)
    log_message "unknown action: ${1:-empty}"
    exit 2
    ;;
esac
