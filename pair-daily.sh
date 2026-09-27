#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?}"
TODAY="$(TZ=Asia/Tehran date +%F)"
CO_TRAILER="Co-authored-by: backrebital-lgtm <329678572+backrebital-lgtm@users.noreply.github.com>"
SUMMARY=()

git config user.name "${GIT_AUTHOR_NAME}"
git config user.email "${GIT_AUTHOR_EMAIL}"

echo "Track A date (Tehran): $TODAY"
echo "## Pair daily $TODAY" >> "$GITHUB_STEP_SUMMARY"

for NN in 01 02 03 04 05 06 07 08 09 10; do
  FILE="docs/pair-log/${TODAY}-${NN}.md"
  BRANCH="pair/${TODAY}-${NN}"
  TITLE="docs: pair log ${TODAY} slot ${NN}"

  git fetch origin main --quiet
  git checkout -B main origin/main --quiet

  if git cat-file -e "origin/main:${FILE}" 2>/dev/null; then
    msg="skip ${NN}: file already on main"
    echo "$msg"
    SUMMARY+=("- $msg")
    continue
  fi

  existing_pr="$(gh pr list --repo "$REPO" --state all --head "$BRANCH" --json number,state --jq '.[0].number // empty' || true)"
  if [ -n "$existing_pr" ]; then
    state="$(gh pr view "$existing_pr" --repo "$REPO" --json state,mergedAt --jq '[.state,.mergedAt]|@tsv')"
    msg="skip ${NN}: PR #$existing_pr exists ($state)"
    echo "$msg"
    SUMMARY+=("- $msg")
    if gh pr view "$existing_pr" --repo "$REPO" --json state --jq .state | grep -qi open; then
      gh pr merge "$existing_pr" --repo "$REPO" --merge --delete-branch || true
      SUMMARY+=("  - attempted merge of #$existing_pr")
    fi
    continue
  fi

  git checkout -B "$BRANCH" origin/main
  mkdir -p docs/pair-log
  cat > "$FILE" << MD
# Pair log — ${TODAY} slot ${NN}

Short pairing note for \`opskit\` docs/CI hygiene.

- Verified slot isolation under \`docs/pair-log/\` only.
- Kept the change narrowly scoped for a clean merge-commit history.
- Timestamp (Tehran): $(TZ=Asia/Tehran date -Iseconds)
MD

  git add "$FILE"
  git commit -m "${TITLE}" -m "Track A pair slot for ${TODAY}." -m "${CO_TRAILER}"
  git push -u origin "HEAD:refs/heads/${BRANCH}" --force-with-lease

  pr_url="$(gh pr create --repo "$REPO" --base main --head "$BRANCH" --title "$TITLE" --body "Track A (Pair Extraordinaire) slot ${NN} for ${TODAY}.

Merge with **Create a merge commit** only (this workflow uses \`gh pr merge --merge\`).

${CO_TRAILER}")"

  pr_num="$(echo "$pr_url" | grep -oE '[0-9]+$')"
  gh pr merge "$pr_num" --repo "$REPO" --merge --delete-branch
  msg="merged slot ${NN}: PR #${pr_num} $pr_url"
  echo "$msg"
  SUMMARY+=("- $msg")
done

{
  echo ""
  echo "### Results"
  printf '%s\n' "${SUMMARY[@]}"
} >> "$GITHUB_STEP_SUMMARY"

echo "Track A done."
