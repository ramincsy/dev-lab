from __future__ import annotations

import ipaddress
import re
from collections.abc import Mapping
from dataclasses import asdict, dataclass
from typing import Any

_HOSTNAME_RE = re.compile(r"^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$")


@dataclass(frozen=True)
class InventoryRecord:
    hostname: str
    mgmt_ip: str
    role: str
    site: str

    def to_dict(self) -> dict[str, str]:
        return asdict(self)


def _pick(row: Mapping[str, Any], *keys: str) -> str:
    lower = {str(k).strip().lower(): v for k, v in row.items()}
    for key in keys:
        if key in lower and lower[key] is not None:
            return str(lower[key]).strip()
    return ""


def normalize_inventory_row(row: Mapping[str, Any]) -> InventoryRecord:
    hostname = _pick(row, "hostname", "host", "name", "device").lower()
    mgmt_ip = _pick(row, "mgmt_ip", "management_ip", "ip", "mgmt")
    role = _pick(row, "role", "type", "device_role").lower() or "unknown"
    site = _pick(row, "site", "location", "dc").upper() or "UNSPECIFIED"

    label = hostname.split(".")[0]
    if not hostname or not _HOSTNAME_RE.match(label):
        raise ValueError(f"invalid hostname: {hostname!r}")

    try:
        ip = ipaddress.ip_address(mgmt_ip)
    except ValueError as exc:
        raise ValueError(f"invalid management IP: {mgmt_ip!r}") from exc

    return InventoryRecord(
        hostname=hostname,
        mgmt_ip=str(ip),
        role=role,
        site=site,
    )
