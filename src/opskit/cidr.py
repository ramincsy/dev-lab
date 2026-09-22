from __future__ import annotations

import ipaddress
from dataclasses import dataclass


@dataclass(frozen=True)
class NetworkSummary:
    network: str
    version: int
    num_addresses: int
    netmask: str
    broadcast: str | None
    first_usable: str | None
    last_usable: str | None


def parse_cidr(value: str) -> ipaddress.IPv4Network | ipaddress.IPv6Network:
    text = (value or "").strip()
    if not text:
        raise ValueError("CIDR value is empty")
    return ipaddress.ip_network(text, strict=False)


def summarize_network(value: str) -> NetworkSummary:
    net = parse_cidr(value)
    hosts = list(net.hosts())
    first = str(hosts[0]) if hosts else None
    last = str(hosts[-1]) if hosts else None
    broadcast = str(net.broadcast_address) if net.version == 4 else None
    return NetworkSummary(
        network=str(net),
        version=net.version,
        num_addresses=net.num_addresses,
        netmask=str(net.netmask),
        broadcast=broadcast,
        first_usable=first,
        last_usable=last,
    )


def cidr_overlap(a: str, b: str) -> bool:
    left = parse_cidr(a)
    right = parse_cidr(b)
    if left.version != right.version:
        return False
    return left.overlaps(right)
