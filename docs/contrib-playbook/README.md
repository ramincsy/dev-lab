# Agent playbook — ramincsy/dev-lab

Canonical copy of [issue #28](https://github.com/ramincsy/dev-lab/issues/28).

User: **رامین (Ramin)** / GitHub **`ramincsy`**. Prefer reports in **Persian**.

**Two separate tracks — never mix them.**

| Track | Workflow | Cron (UTC) | ≈ Asia/Tehran |
|-------|----------|------------|---------------|
| A Pair | `.github/workflows/pair-daily.yml` | `7 1`, `7 6`, `7 11`, `7 14` | 04:37, 09:37, 14:37, 17:37 |
| B Contrib | `.github/workflows/contrib-daily.yml` | `37 1` (floor 300), `37 6` (600), `37 11` (900), `37 14` (900) | 05:07, 10:07, 15:07, 18:07 |
| Floor check | `.github/workflows/daily-floor.yml` | `31 15` | 19:01 |

Pair and contrib are idempotent. A missed window is retried at the next one; the contrib slices are cumulative, so the Tehran-day total stays 900 rather than 900×4. The 14:37 UTC contrib slice repeats target 900 and only fills a gap. Pair's fourth slice only opens slots whose files are not already on main, so the day stays at 10 PRs. `workflow_dispatch` on either workflow still accepts an explicit target (contrib default 900) and uses wall-clock "now". The floor check dispatches both workflows and fails the run when authored commits for the Tehran day are under 450.

Scheduled runs do not use the clock at job start. They take the Tehran day from the cron slot (`github.event.schedule`): the intended UTC time on the UTC date of the run, or the previous UTC date when that instant is still more than two hours in the future (the job slipped past UTC midnight). Author date and committer date are that instant, a few seconds later per entry, written as `Asia/Tehran` `+0330`. GitHub then counts the commits on the intended day even if the runner starts after Tehran midnight (20:30 UTC).

PR create/merge (Track A and B) and the floor-check dispatch try `secrets.DEVLAB_PAT` when that secret is non-empty, otherwise `GITHUB_TOKEN`. Issue comments and workflow dispatch retry with `GITHUB_TOKEN` when the fine-grained PAT returns 403. Git author and committer stay `ramincsy <34828058+ramincsy@users.noreply.github.com>`. CI runs on these PRs; merge waits until that check passes. A floor run that starts after Tehran midnight (before 12:00) audits the previous day and does not dispatch, so the catch-up is not authored onto the new day.

## Track A — Pair Extraordinaire

- 10 PRs/day under `docs/pair-log/` on branches `pair/YYYY-MM-DD-NN`
- Exact trailer: `Co-authored-by: backrebital-lgtm <329678572+backrebital-lgtm@users.noreply.github.com>`
- Merge with **merge commit** only
- Stop when Pair Extraordinaire reaches ×4

## Track B — Contribution floor (≥900/day)

- Branches `contrib/YYYY-MM-DD-batch-N`, files under `docs/contrib-log/`
- Author email must be `34828058+ramincsy@users.noreply.github.com`
- Soft cap ~1000 new commits/day; merge commit only
- Do not touch `docs/pair-log/`

## Track C — Existing health Actions

Keep `CI`, `Daily` (`19 8 * * *`), and `Weekly health` enabled.
