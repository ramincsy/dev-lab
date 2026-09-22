from __future__ import annotations

import re

_STRIP_RE = re.compile(r"[\s\-_.]+")
_DIGIT_MAP = str.maketrans("۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩", "01234567890123456789")
# Common Iranian plate letters → Latin (approx) for cross-system matching
_LETTER_MAP = str.maketrans(
    {
        "ب": "B",
        "ج": "J",
        "د": "D",
        "س": "S",
        "ص": "S",
        "ط": "T",
        "ق": "Q",
        "ل": "L",
        "م": "M",
        "ن": "N",
        "و": "V",
        "ه": "H",
        "ی": "Y",
        "ي": "Y",
        "ک": "K",
        "گ": "G",
    }
)


def normalize_plate(raw: str) -> str:
    """Normalize a plate string for ANPR matching (not a legal validator)."""
    if raw is None:
        raise ValueError("plate is empty")
    text = str(raw).strip().translate(_DIGIT_MAP).translate(_LETTER_MAP)
    text = _STRIP_RE.sub("", text).upper()
    if len(text) < 5 or len(text) > 12:
        raise ValueError(f"plate length out of range after normalize: {text!r}")
    if not re.fullmatch(r"[A-Z0-9]+", text):
        raise ValueError(f"plate has invalid characters: {text!r}")
    return text
