# dev-lab · opskit

Small, tested Python utilities for **network ops and ANPR pipelines** — CIDR helpers, inventory normalization, and plate string cleanup.

This repository is a real engineering lab (code + tests + CI). It is **not** a contribution-farming or GitHub Achievements toolkit.

<div dir="rtl" lang="fa" align="right">

### فارسی
ابزارک‌های کوچک برای شبکه و ANPR: خلاصه CIDR، نرمال‌سازی موجودی تجهیزات، و یکدست‌سازی پلاک. ریپو برای کار واقعی با تست و CI است — نه ساخت فعالیت مصنوعی.

</div>

## Install (editable)

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## CLI

```bash
python -m opskit cidr-summary 10.20.0.0/23
python -m opskit cidr-overlap 10.0.0.0/16 10.0.5.0/24
echo '{"hostname":"edge-fw1","ip":"10.9.1.1","role":"firewall","site":"ank"}' | python -m opskit inventory-normalize
python -m opskit plate-normalize "۱۲ ب-۳۴۵ ۶۷"
```

## Develop

```bash
ruff check src tests
pytest -q
```

## CI

GitHub Actions runs **ruff + pytest** on every push/PR to `main`. A weekly health workflow re-runs the same checks (no filler commits).

## Roadmap (showcase automation)

Sibling catalog repos can adopt a shared link-check workflow; see `docs/showcase-automation.md`.
