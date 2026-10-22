#!/usr/bin/env bash
# Map a scheduled run to the Tehran day its cron slot was meant for.
#
# GitHub often starts a cron 3–6h late. Tehran midnight is 20:30 UTC, so a
# late evening slot used to roll onto the next Tehran date. Scheduled runs
# pin the day (and commit timestamps) to the slot's intended UTC instant.
# workflow_dispatch keeps wall-clock "now".

resolve_tehran_slot() {
  local now_epoch="${NOW_EPOCH:-$(date -u +%s)}"
  local min hour utc_day intended
  if [ "${EVENT_NAME:-}" = "schedule" ] && [ -n "${CRON_SCHEDULE:-}" ]; then
    read -r min hour _ <<< "${CRON_SCHEDULE}"
    utc_day="$(date -u -d "@${now_epoch}" +%F)"
    intended="$(date -u -d "${utc_day} ${hour}:${min}:00 UTC" +%s)"
    # The run slipped past UTC midnight: the slot belongs to yesterday UTC.
    if [ "$intended" -gt $((now_epoch + 7200)) ]; then
      utc_day="$(date -u -d "${utc_day} - 1 day" +%F)"
      intended="$(date -u -d "${utc_day} ${hour}:${min}:00 UTC" +%s)"
    fi
  else
    intended="$now_epoch"
  fi
  # Globals for the caller (contrib-daily.sh / pair-daily.sh).
  # shellcheck disable=SC2034
  SLOT_EPOCH="$intended"
  # shellcheck disable=SC2034
  TEHRAN_DAY="$(TZ=Asia/Tehran date -d "@${intended}" +%F)"
}

# ISO-8601 timestamp `offset` seconds after the slot, in Asia/Tehran.
# Git accepts this as GIT_AUTHOR_DATE / GIT_COMMITTER_DATE.
author_date_at() {
  local offset="${1:-0}"
  TZ=Asia/Tehran date -d "@$((SLOT_EPOCH + offset))" '+%Y-%m-%dT%H:%M:%S%z'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  fail=0
  expect() {
    local name="$1" got="$2" want="$3"
    if [ "$got" = "$want" ]; then
      echo "ok  $name"
    else
      echo "FAIL $name: got=$got want=$want" >&2
      fail=1
    fi
  }
  # 11:37 UTC on time → 15:07 Tehran the same calendar day.
  out="$(NOW_EPOCH="$(date -u -d '2026-10-21 11:37:00 UTC' +%s)" EVENT_NAME=schedule CRON_SCHEDULE='37 11 * * *' bash -c 'source "$1"; resolve_tehran_slot; printf "%s %s" "$TEHRAN_DAY" "$(author_date_at 0)"' _ "$0")"
  expect "on-time 11:37" "$out" "2026-10-21 2026-10-21T15:07:00+0330"

  # Same slot, started 6h late, still before Tehran midnight (20:30 UTC).
  out="$(NOW_EPOCH="$(date -u -d '2026-10-21 17:37:00 UTC' +%s)" EVENT_NAME=schedule CRON_SCHEDULE='37 11 * * *' bash -c 'source "$1"; resolve_tehran_slot; printf "%s" "$TEHRAN_DAY"' _ "$0")"
  expect "6h-late 11:37" "$out" "2026-10-21"

  # 14:37 UTC slot starts at 20:40 UTC (00:10 next Tehran day) → still Oct 21.
  out="$(NOW_EPOCH="$(date -u -d '2026-10-21 20:40:00 UTC' +%s)" EVENT_NAME=schedule CRON_SCHEDULE='37 14 * * *' bash -c 'source "$1"; resolve_tehran_slot; printf "%s %s" "$TEHRAN_DAY" "$(author_date_at 0)"' _ "$0")"
  expect "late 14:37 same UTC day" "$out" "2026-10-21 2026-10-21T18:07:00+0330"

  # Slot delayed past UTC midnight.
  out="$(NOW_EPOCH="$(date -u -d '2026-10-22 00:21:00 UTC' +%s)" EVENT_NAME=schedule CRON_SCHEDULE='37 14 * * *' bash -c 'source "$1"; resolve_tehran_slot; printf "%s" "$TEHRAN_DAY"' _ "$0")"
  expect "late past UTC midnight" "$out" "2026-10-21"

  # Manual dispatch uses wall clock, including just after Tehran midnight.
  out="$(NOW_EPOCH="$(date -u -d '2026-10-21 20:40:00 UTC' +%s)" EVENT_NAME=workflow_dispatch CRON_SCHEDULE='' bash -c 'source "$1"; resolve_tehran_slot; printf "%s" "$TEHRAN_DAY"' _ "$0")"
  expect "manual after midnight" "$out" "2026-10-22"

  # 01:37 UTC is 05:07 Tehran the same calendar day.
  out="$(NOW_EPOCH="$(date -u -d '2026-10-22 01:37:00 UTC' +%s)" EVENT_NAME=schedule CRON_SCHEDULE='37 1 * * *' bash -c 'source "$1"; resolve_tehran_slot; printf "%s %s" "$TEHRAN_DAY" "$(author_date_at 90)"' _ "$0")"
  expect "01:37 plus 90s" "$out" "2026-10-22 2026-10-22T05:08:30+0330"

  exit "$fail"
fi
