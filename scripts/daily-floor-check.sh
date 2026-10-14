#!/usr/bin/env bash
# End-of-day floor. When today's authored commits are far below normal,
# dispatch the existing daily workflows and exit non-zero so GitHub emails
# the owner. Author identity is left to those workflows.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?}"
AUTHOR_EMAIL="${AUTHOR_EMAIL:-34828058+ramincsy@users.noreply.github.com}"
MIN_OK="${MIN_OK:-450}"
CATCHUP_TARGET="${CATCHUP_TARGET:-900}"
export TZ=Asia/Tehran
TODAY="${TODAY_OVERRIDE:-$(date +%F)}"

git fetch origin main --quiet
count="$(git log origin/main --author="${AUTHOR_EMAIL}" --pretty='%ad' --date=format:%F | awk -v d="$TODAY" '$1==d {c++} END{print c+0}')"

echo "Tehran date=$TODAY authored=$count far-below-threshold=$MIN_OK"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## Daily floor ${TODAY}"
    echo "- authored commits: ${count}"
    echo "- far-below threshold: ${MIN_OK}"
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$count" -ge "$MIN_OK" ]; then
  echo "Floor ok."
  exit 0
fi

echo "Far below normal (${count} < ${MIN_OK}). Dispatching catch-up."
if [ "${DRY_RUN:-}" = "1" ]; then
  echo "DRY_RUN: would dispatch contrib-daily.yml target=${CATCHUP_TARGET} and pair-daily.yml"
  dispatch_note="dry-run"
else
  set +e
  gh workflow run contrib-daily.yml --repo "$REPO" --ref main -f "target=${CATCHUP_TARGET}"
  contrib_rc=$?
  gh workflow run pair-daily.yml --repo "$REPO" --ref main
  pair_rc=$?
  set -e
  if [ "$contrib_rc" -ne 0 ] || [ "$pair_rc" -ne 0 ]; then
    echo "::error::Catch-up dispatch failed (contrib=${contrib_rc}, pair=${pair_rc}) and Tehran ${TODAY} has only ${count} authored commits."
    exit 1
  fi
  dispatch_note="dispatched"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "- catch-up ${dispatch_note} (contrib target ${CATCHUP_TARGET}, pair daily)" >> "$GITHUB_STEP_SUMMARY"
fi

echo "::error::Tehran ${TODAY} has ${count} authored commits, far below ${MIN_OK}. Catch-up workflows were ${dispatch_note}."
exit 1
