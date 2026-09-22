import pytest

from opskit.cidr import cidr_overlap, parse_cidr, summarize_network


def test_parse_and_summary():
    s = summarize_network("192.168.10.0/24")
    assert s.network == "192.168.10.0/24"
    assert s.num_addresses == 256
    assert s.first_usable == "192.168.10.1"
    assert s.last_usable == "192.168.10.254"


def test_overlap_true_false():
    assert cidr_overlap("10.0.0.0/16", "10.0.5.0/24") is True
    assert cidr_overlap("10.0.0.0/24", "10.0.1.0/24") is False


def test_empty_raises():
    with pytest.raises(ValueError):
        parse_cidr("  ")
