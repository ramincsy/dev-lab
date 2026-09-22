"""opskit — network inventory, CIDR checks, and ANPR plate normalization."""

from .anpr_normalize import normalize_plate
from .cidr import cidr_overlap, parse_cidr, summarize_network
from .inventory import InventoryRecord, normalize_inventory_row

__version__ = "0.1.0"

__all__ = [
    "__version__",
    "parse_cidr",
    "summarize_network",
    "cidr_overlap",
    "InventoryRecord",
    "normalize_inventory_row",
    "normalize_plate",
]
