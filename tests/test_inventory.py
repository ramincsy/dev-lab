import pytest

from opskit.inventory import normalize_inventory_row


def test_normalize_aliases():
    rec = normalize_inventory_row(
        {"Host": "Core-SW1", "IP": "10.1.1.10", "Type": "Core", "Location": "tbz-dc1"}
    )
    assert rec.hostname == "core-sw1"
    assert rec.mgmt_ip == "10.1.1.10"
    assert rec.role == "core"
    assert rec.site == "TBZ-DC1"


def test_bad_ip():
    with pytest.raises(ValueError):
        normalize_inventory_row({"hostname": "sw1", "ip": "999.1.1.1"})
