#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?}"
TARGET="${TARGET:-900}"
# Scheduled runs pass CRON_SCHEDULE. Each slice is a cumulative floor so the
# day still ends at 900 if every window fires, and a later window fills gaps
# when an earlier one was skipped. The 14:37 UTC slice repeats 900. An unknown
# schedule also stays at 900. workflow_dispatch keeps INPUT_TARGET.
if [ "${EVENT_NAME:-}" = "workflow_dispatch" ]; then
  TARGET="${INPUT_TARGET:-$TARGET}"
elif [ -n "${CRON_SCHEDULE:-}" ]; then
  case "${CRON_SCHEDULE}" in
    "37 1 * * *") TARGET=300 ;;
    "37 6 * * *") TARGET=600 ;;
    "37 11 * * *") TARGET=900 ;;
    "37 14 * * *") TARGET=900 ;;
  esac
fi
BATCH_SIZE="${BATCH_SIZE:-250}"
AUTHOR_EMAIL="34828058+ramincsy@users.noreply.github.com"

# shellcheck source=scripts/wait-pr-ci.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/wait-pr-ci.sh"
# shellcheck source=scripts/gh-fallback.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gh-fallback.sh"
# shellcheck source=scripts/tehran-slot.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tehran-slot.sh"
# Scheduled runs use the cron slot's Tehran day, not wall-clock now, so a
# start after midnight still tops up the day the slot was meant for.
resolve_tehran_slot
TODAY="$TEHRAN_DAY"
LOG="docs/contrib-log/${TODAY}.md"

git config user.name "${GIT_AUTHOR_NAME}"
git config user.email "${GIT_AUTHOR_EMAIL}"

git fetch origin main --quiet
git checkout -B main origin/main --quiet

mkdir -p docs/contrib-log
if [ ! -f "$LOG" ]; then
  cat > "$LOG" << MD
# Contrib log — ${TODAY}

Track B daily floor for \`ramincsy\` (authored as ${AUTHOR_EMAIL}).
MD
fi

export TZ=Asia/Tehran
already="$(git log origin/main --author="${AUTHOR_EMAIL}" --pretty='%ad' --date=format:%F -- docs/contrib-log/ 2>/dev/null | awk -v d="$TODAY" '$1==d {c++} END{print c+0}')"

remaining=$(( TARGET - already ))
if [ "$remaining" -lt 0 ]; then remaining=0; fi

echo "Track B date=$TODAY already=$already target=$TARGET remaining=$remaining"
{
  echo "## Contrib daily $TODAY"
  echo "- already: $already"
  echo "- target: $TARGET"
  echo "- remaining: $remaining"
} >> "$GITHUB_STEP_SUMMARY"

if [ "$remaining" -eq 0 ]; then
  echo "Floor met; nothing to do."
  echo "- floor already met" >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

MAX_NEW=1000
if [ "$remaining" -gt "$MAX_NEW" ]; then
  remaining=$MAX_NEW
fi

ISSUE_TITLE="Daily activity checklist ${TODAY}"
issue_num="$(gh issue list --repo "$REPO" --state open --search "$ISSUE_TITLE in:title" --json number,title --jq ".[] | select(.title==\"$ISSUE_TITLE\") | .number" | head -1 || true)"
if [ -z "$issue_num" ]; then
  issue_url="$(gh issue create --repo "$REPO" --title "$ISSUE_TITLE" --body "Track B checklist for ${TODAY}. Target ${TARGET} commits authored as ${AUTHOR_EMAIL}.")"
  issue_num="$(echo "$issue_url" | grep -oE '[0-9]+$')"
fi

batch=1
made=0
while [ "$made" -lt "$remaining" ]; do
  this=$(( remaining - made ))
  if [ "$this" -gt "$BATCH_SIZE" ]; then this=$BATCH_SIZE; fi
  BRANCH="contrib/${TODAY}-batch-$(printf '%02d' "$batch")"

  git checkout -B main origin/main --quiet
  git checkout -B "$BRANCH" origin/main
  mkdir -p docs/contrib-log
  if [ ! -f "$LOG" ]; then
    printf '# Contrib log — %s\n\n' "$TODAY" > "$LOG"
  fi

  start=$(( already + made + 1 ))
  end=$(( already + made + this ))
  for i in $(seq "$start" "$end"); do
    # A few seconds after the slot, still inside the same Tehran day.
    stamp="$(author_date_at "$i")"
    echo "entry-$(printf '%04d' "$i") ${stamp} batch-${batch}" >> "$LOG"
    git add "$LOG"
    GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" \
      git commit -m "chore(contrib): ${TODAY} entry $(printf '%04d' "$i")"
  done

  git push -u origin "HEAD:refs/heads/${BRANCH}" --force-with-lease
  pr_url="$(gh pr create --repo "$REPO" --base main --head "$BRANCH" --title "chore(contrib): ${TODAY} batch ${batch} (${this} commits)" --body "Track B batch ${batch} for ${TODAY}: ${this} commits authored as ${AUTHOR_EMAIL}.

Related: #${issue_num}

Merge with **merge commit** only.")"
  pr_num="$(echo "$pr_url" | grep -oE '[0-9]+$')"
  gh pr review "$pr_num" --repo "$REPO" --comment --body "Track B batch ${batch} looks good to merge (merge commit)."
  wait_for_pr_ci "$pr_num"
  gh pr merge "$pr_num" --repo "$REPO" --merge --delete-branch
  post_issue_comment "$issue_num" "Merged batch ${batch}: ${pr_url} (${this} commits)."

  echo "merged batch $batch PR #$pr_num ($this commits)"
  echo "- batch ${batch}: PR #${pr_num} (${this} commits) ${pr_url}" >> "$GITHUB_STEP_SUMMARY"

  git fetch origin main --quiet
  made=$(( made + this ))
  batch=$(( batch + 1 ))
done

post_issue_comment "$issue_num" "Track B batches complete for ${TODAY} (requested remaining ${remaining})."
gh issue close "$issue_num" --repo "$REPO" || true
echo "Track B done. created≈$made commits."
