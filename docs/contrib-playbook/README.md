# Agent playbook — ramincsy/dev-lab

Canonical copy of [issue #28](https://github.com/ramincsy/dev-lab/issues/28).

User: **رامین (Ramin)** / GitHub **`ramincsy`**. Prefer reports in **Persian**.

**Two separate tracks — never mix them.**

| Track | Workflow | Cron (UTC) | ≈ Asia/Tehran |
|-------|----------|------------|---------------|
| A Pair | `.github/workflows/pair-daily.yml` | `7 5`, `7 11`, `7 17` | 08:37, 14:37, 20:37 |
| B Contrib | `.github/workflows/contrib-daily.yml` | `37 5` (floor 300), `37 11` (600), `37 17` (900) | 09:07, 15:07, 21:07 |
| Floor check | `.github/workflows/daily-floor.yml` | `11 19` | 22:41 |

Pair and contrib are idempotent. A missed window is retried at the next one; the contrib slices are cumulative, so the Tehran-day total stays 900 rather than 900×3. `workflow_dispatch` on either workflow still accepts an explicit target (contrib default 900). The floor check dispatches both workflows and fails the run when authored commits for the Tehran day are under 450.

PR create/merge (Track A and B) and the floor-check dispatch use `secrets.DEVLAB_PAT` when that secret is non-empty, otherwise `GITHUB_TOKEN`. Git author and committer stay `ramincsy <34828058+ramincsy@users.noreply.github.com>`. CI runs on these PRs (no docs path filter); merge waits until that check passes so the head ref is still there for checkout.

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
