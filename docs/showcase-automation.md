# Showcase automation (plan B)

Recommended useful workflows for `*-showcase` repos (Atlas, Taradod, Vision, …):

1. **pages-link-check** — on PR/push and weekly: crawl `docs/index.html` (or Pages root) and fail if internal links/images 404.
2. **html-validate** — optional tidy/validate for static catalogs.
3. **dependabot** — keep Actions versions current.

These create real CI signals when catalogs break — not synthetic commits.
