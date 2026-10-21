#!/usr/bin/env bash
# DEVLAB_PAT (a fine-grained PAT) can open and merge pull requests, but
# GraphQL addComment and workflow_dispatch return 403. Retry those calls
# with the Actions GITHUB_TOKEN, which has issues:write and actions:write.

post_issue_comment() {
  local num="$1"
  local body="$2"
  if gh issue comment "$num" --repo "$REPO" --body "$body"; then
    return 0
  fi
  echo "GraphQL addComment failed; posting via REST"
  if gh api --method POST "repos/${REPO}/issues/${num}/comments" -f body="$body" >/dev/null; then
    return 0
  fi
  if [ -n "${GITHUB_TOKEN:-}" ] && [ "${GITHUB_TOKEN}" != "${GH_TOKEN:-}" ]; then
    echo "REST comment with primary token failed; retrying GITHUB_TOKEN"
    if GH_TOKEN="$GITHUB_TOKEN" gh api --method POST "repos/${REPO}/issues/${num}/comments" -f body="$body" >/dev/null; then
      return 0
    fi
  fi
  echo "warning: issue #${num} comment was not posted" >&2
  return 0
}

dispatch_workflow() {
  if gh workflow run "$@"; then
    return 0
  fi
  if [ -n "${GITHUB_TOKEN:-}" ] && [ "${GITHUB_TOKEN}" != "${GH_TOKEN:-}" ]; then
    echo "workflow dispatch with primary token failed; retrying GITHUB_TOKEN"
    GH_TOKEN="$GITHUB_TOKEN" gh workflow run "$@"
    return $?
  fi
  return 1
}
