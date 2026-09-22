from __future__ import annotations

import argparse
import json
import sys

from . import __version__
from .anpr_normalize import normalize_plate
from .cidr import cidr_overlap, summarize_network
from .inventory import normalize_inventory_row


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="opskit",
        description="Network/ops micro-utilities",
    )
    parser.add_argument("--version", action="version", version=f"opskit {__version__}")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_sum = sub.add_parser("cidr-summary", help="Summarize a CIDR network")
    p_sum.add_argument("cidr")

    p_ov = sub.add_parser("cidr-overlap", help="Check whether two CIDRs overlap")
    p_ov.add_argument("a")
    p_ov.add_argument("b")

    sub.add_parser(
        "inventory-normalize",
        help="Normalize one inventory JSON object from stdin",
    )

    p_plate = sub.add_parser("plate-normalize", help="Normalize an ANPR plate string")
    p_plate.add_argument("plate")

    args = parser.parse_args(argv)

    try:
        if args.cmd == "cidr-summary":
            print(json.dumps(summarize_network(args.cidr).__dict__, indent=2))
        elif args.cmd == "cidr-overlap":
            print(json.dumps({"overlap": cidr_overlap(args.a, args.b)}))
        elif args.cmd == "inventory-normalize":
            payload = json.load(sys.stdin)
            print(json.dumps(normalize_inventory_row(payload).to_dict(), indent=2))
        elif args.cmd == "plate-normalize":
            print(normalize_plate(args.plate))
        else:
            parser.error(f"unknown command: {args.cmd}")
            return 2
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
