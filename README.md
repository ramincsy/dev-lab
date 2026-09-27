# Agent playbook — ramincsy/dev-lab

Canonical copy of [issue #28](https://github.com/ramincsy/dev-lab/issues/28).

User: **رامین (Ramin)** / GitHub **`ramincsy`**. Prefer reports in **Persian**.

**Two separate tracks — never mix them.**

| Track | Workflow | Cron (UTC) | ≈ Asia/Tehran |
|-------|----------|------------|---------------|
| A Pair | `.github/workflows/pair-daily.yml` | `54 5 * * *` | 09:24 |
| B Contrib | `.github/workflows/contrib-daily.yml` | `12 7 * * *` | 10:42 |

Runs with the built-in `GITHUB_TOKEN` (no extra secret). Commits set author to `ramincsy <34828058+ramincsy@users.noreply.github.com>`.

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

Keep `CI`, `Daily`, and `Weekly health` enabled.
