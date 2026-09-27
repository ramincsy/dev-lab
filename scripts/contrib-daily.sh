#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?}"
TODAY="$(TZ=Asia/Tehran date +%F)"
TARGET="${TARGET:-900}"
BATCH_SIZE="${BATCH_SIZE:-250}"
AUTHOR_EMAIL="34828058+ramincsy@users.noreply.github.com"
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
echo "## Contrib daily $TODAY" >> "$GITHUB_STEP_SUMMARY"
echo "- already: $already" >> "$GITHUB_STEP_SUMMARY"
echo "- target: $TARGET" >> "$GITHUB_STEP_SUMMARY"
echo "- remaining: $remaining" >> "$GITHUB_STEP_SUMMARY"

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

  start=$(( made + 1 ))
  end=$(( made + this ))
  for i in $(seq "$start" "$end"); do
    echo "entry-$(printf '%04d' "$i") $(date -u +%Y-%m-%dT%H:%M:%SZ) batch-${batch}" >> "$LOG"
    git add "$LOG"
    git commit -m "chore(contrib): ${TODAY} entry $(printf '%04d' "$i")"
  done

  git push -u origin "HEAD:refs/heads/${BRANCH}" --force-with-lease
  pr_url="$(gh pr create --repo "$REPO" --base main --head "$BRANCH" --title "chore(contrib): ${TODAY} batch ${batch} (${this} commits)" --body "Track B batch ${batch} for ${TODAY}: ${this} commits authored as ${AUTHOR_EMAIL}.

Related: #${issue_num}

Merge with **merge commit** only.")"
  pr_num="$(echo "$pr_url" | grep -oE '[0-9]+$')"
  gh pr review "$pr_num" --repo "$REPO" --comment --body "Track B batch ${batch} looks good to merge (merge commit)."
  gh pr merge "$pr_num" --repo "$REPO" --merge --delete-branch
  gh issue comment "$issue_num" --repo "$REPO" --body "Merged batch ${batch}: ${pr_url} (${this} commits)."

  echo "merged batch $batch PR #$pr_num ($this commits)"
  echo "- batch ${batch}: PR #${pr_num} (${this} commits) ${pr_url}" >> "$GITHUB_STEP_SUMMARY"

  git fetch origin main --quiet
  made=$(( made + this ))
  batch=$(( batch + 1 ))
done

gh issue close "$issue_num" --repo "$REPO" --comment "Track B batches complete for ${TODAY} (requested remaining ${remaining})." || true
echo "Track B done. created≈$made commits."
