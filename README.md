# dev-lab

`dev-lab` is a local scaffold for the `ramincsy/dev-lab` repository. It consolidates practical contribution playbooks, review helpers, and GitHub Actions templates from two existing repositories without cloning their histories.

This is a reference pack, not a turnkey automation service. Files copied from upstream retain their original context and may require path, permission, dependency, and repository-name changes before use. The workflow files are `.example` templates and have been converted to manual `workflow_dispatch` triggers; no schedule is active here.

## Contents

- `docs/` — contribution, collaboration, review, and source README material from `Gthub-Achievements` and `Auto`.
- - `scripts/` — selected local Node.js and Python helpers. Scripts that mass-generate contributions, branches, or pull requests were intentionally omitted.
  - - `workflows/` — manual-only workflow examples, prefixed by source (`gthub-` or `auto-`). Review permissions, tokens, and every write operation before enabling one.
    - - `projects/` — small source metadata such as the Gthub Achievements `package.json` and Auto's Python requirements.
      - - `MOVE_NOTICE.md` — banner snippets for pointing the source repositori## Provenance
        -
        - The pack was fetched from the `main` branches of:
        -
        - - <https://github.com/ramincsy/Gthub-Achievements>
          - - <https://github.com/ramincsy/Auto>
            -
            - The source repositories were accessed through raw GitHub files and repository HTML listings. No Git history was cloned and nothing was pushed to GitHub.
            -
            - ## Status
            -
            - Scaffold only. The contents are intentionally not wired into a root build, package manager, or active Actions directory. Integrate pieces deliberately, update paths and tests, and document any behavioral changes in the eventual monorepo.
            - es at this monorepo.
        - - `MANIFEST.txt` — the complete list of scaffold files and provenance notes.
         
          - ## Operating principles
         
          - - Prefer meaningful, reviewable work over activity volume.
            - - Treat automation as opt-in and auditable; do not run workflows or scripts merely to manufacture commits, pull requests, reviews, or badges.
              - - Keep tokens in GitHub Secrets or the local environment; never add credentials to this scaffold.
                - - Use dry runs, least-privilege permissions, and human review before any write or merge operation.
                  - - Check upstream documentation and repository policy before adapting a template.
                   
                    - 
