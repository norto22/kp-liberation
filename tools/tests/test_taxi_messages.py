"""Check taxi feedback resources without claiming to render Arma's UI."""

import re
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

FRAMEWORK = Path(__file__).resolve().parents[2] / "Missionframework"
STRING_ID = re.compile(r"\bSTR_TAXI_[A-Z0-9_]*[A-Z0-9]\b")


def test_taxi_feedback_keys_are_unique_and_have_fallback_text() -> None:
    keys = [
        key
        for key in ET.parse(FRAMEWORK / "stringtable.xml").iter("Key")
        if key.attrib["ID"].startswith("STR_TAXI_")
    ]
    counts = Counter(key.attrib["ID"] for key in keys)
    assert keys
    assert all(count == 1 for count in counts.values()), counts
    for key in keys:
        text = key.findtext("Original")
        assert text and text.strip(), key.attrib["ID"]


def test_every_referenced_taxi_message_is_localized() -> None:
    defined = {key.attrib["ID"] for key in ET.parse(FRAMEWORK / "stringtable.xml").iter("Key")}
    missing = {}
    for pattern in ("*.sqf", "*.hpp"):
        for source in FRAMEWORK.rglob(pattern):
            references = set(STRING_ID.findall(source.read_text(encoding="utf-8-sig")))
            if references - defined:
                missing[str(source.relative_to(FRAMEWORK))] = sorted(references - defined)
    assert not missing, missing
