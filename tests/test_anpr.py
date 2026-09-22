import pytest

from opskit.anpr_normalize import normalize_plate


def test_normalize_spaces_and_digits():
    assert normalize_plate("۱۲ب ۳۴۵-۶۷") == "12B34567"


def test_too_short():
    with pytest.raises(ValueError):
        normalize_plate("ab")
