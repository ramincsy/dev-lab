#!/usr/bin/env bash
# Wait until pull_request CI has finished successfully.
# Merge deletes the head ref; if that happens before the runner checks out,
# the job fails with zero useful signal. Call this before `gh pr merge`.

wait_for_pr_ci() {
  local pr_num="$1"
  local attempt rollup
  local pause="${CI_REGISTER_SLEEP:-5}"
  for attempt in $(seq 1 60); do
    rollup="$(gh pr view "$pr_num" --repo "$REPO" --json statusCheckRollup --jq 'if .statusCheckRollup == null then 0 else (.statusCheckRollup | length) end')"
    case "$rollup" in
      ''|*[!0-9]*) rollup=0 ;;
    esac
    if [ "$rollup" -ge 1 ]; then
      gh pr checks "$pr_num" --repo "$REPO" --watch --fail-fast --interval 10
      return
    fi
    echo "waiting for CI to register on PR #${pr_num} (${attempt}/60)"
    sleep "$pause"
  done
  echo "CI did not register for PR #${pr_num}" >&2
  return 1
}
