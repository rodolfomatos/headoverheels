"""Tests for the staleness gate.

The gate exists because of claim C-002 in `aes/graph/tooling-integrity.yaml`: the
skill's version reported "No STALE GMIF shadows" after iterating zero files. So
the test that matters most here is the first one -- a gate that examines nothing
must fail, not pass.
"""

from __future__ import annotations

import datetime as dt
import importlib.util
import pathlib
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def load(name: str, path: pathlib.Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


staleness = load("gmif_staleness", ROOT / "scripts" / "gmif_staleness.py")

TODAY = dt.date(2026, 10, 3)


def write_shadow(directory: pathlib.Path, name: str, days_old: int,
                 **extra: str) -> pathlib.Path:
    verified = TODAY - dt.timedelta(days=days_old)
    body = (f"---\n"
            f"epistemic_state: SUPPORTED\n"
            f"last_verified: {verified.isoformat()}\n"
            f"access_count: 3\n"
            f"score: 0.9\n")
    for key, value in extra.items():
        body += f"{key}: {value}\n"
    body += "---\n\nThe claim.\n"
    path = directory / name
    path.write_text(body, encoding="utf-8")
    return path


# --- the vacuity guard -------------------------------------------------------

def test_an_empty_directory_fails(tmp_path):
    """The defect this gate was written to correct.

    The skill's version iterated zero files and printed a clean bill. Zero
    documents has to be a FAILURE, or the gate cannot tell "nothing is stale"
    from "I read nothing".
    """
    empty = tmp_path / "shadow"
    empty.mkdir()

    result = staleness.audit(TODAY, empty)

    assert result["verdict"] == "FAIL"
    assert result["examined"] == 0


def test_a_missing_directory_fails_too(tmp_path):
    result = staleness.audit(TODAY, tmp_path / "does-not-exist")

    assert result["verdict"] == "FAIL"
    assert result["examined"] == 0


# --- staleness ---------------------------------------------------------------

def test_a_recent_claim_passes(tmp_path):
    shadow = tmp_path / "shadow"
    shadow.mkdir()
    write_shadow(shadow, "SD-CI-001-fresh.md", 3)

    assert staleness.audit(TODAY, shadow)["verdict"] == "PASS"


def test_an_aged_claim_passes_but_is_reported(tmp_path):
    shadow = tmp_path / "shadow"
    shadow.mkdir()
    write_shadow(shadow, "SD-CI-002-aging.md", 45)

    result = staleness.audit(TODAY, shadow)

    assert result["verdict"] == "PASS"
    assert [r["name"] for r in result["aging"]] == ["SD-CI-002-aging.md"]


def test_a_stale_claim_fails(tmp_path):
    shadow = tmp_path / "shadow"
    shadow.mkdir()
    write_shadow(shadow, "SD-CI-003-stale.md", 200)

    result = staleness.audit(TODAY, shadow)

    assert result["verdict"] == "FAIL"
    assert [r["name"] for r in result["stale"]] == ["SD-CI-003-stale.md"]


def test_staleness_can_be_acknowledged_with_a_reason(tmp_path):
    """Acknowledging is a decision with a name on it, not a silent skip."""
    shadow = tmp_path / "shadow"
    shadow.mkdir()
    write_shadow(shadow, "SD-CI-004-old.md", 400,
                staleness_acknowledged="true",
                staleness_reason="the code it measured is now deleted")

    result = staleness.audit(TODAY, shadow)

    assert result["verdict"] == "PASS"
    assert [r["name"] for r in result["acknowledged"]] == ["SD-CI-004-old.md"]


def test_acknowledging_without_a_reason_is_not_acknowledging(tmp_path):
    shadow = tmp_path / "shadow"
    shadow.mkdir()
    write_shadow(shadow, "SD-CI-005-bare.md", 400, staleness_acknowledged="true")

    result = staleness.audit(TODAY, shadow)

    assert result["verdict"] == "FAIL"
    assert "staleness_reason" in result["malformed"][0][1]


# --- completeness ------------------------------------------------------------

def test_a_document_missing_its_fields_fails(tmp_path):
    """A document the gate cannot date is not a document it has checked."""
    shadow = tmp_path / "shadow"
    shadow.mkdir()
    (shadow / "SD-CI-006-no-date.md").write_text(
        "---\nepistemic_state: SUPPORTED\n---\n\nUndated.\n", encoding="utf-8")

    result = staleness.audit(TODAY, shadow)

    assert result["verdict"] == "FAIL"
    assert "last_verified" in result["malformed"][0][1]


def test_index_is_not_mistaken_for_a_claim(tmp_path):
    shadow = tmp_path / "shadow"
    shadow.mkdir()
    write_shadow(shadow, "SD-CI-007-real.md", 2)
    (shadow / "INDEX.md").write_text("# Index\n", encoding="utf-8")

    result = staleness.audit(TODAY, shadow)

    assert result["examined"] == 1


def test_the_real_shadow_directory_is_not_vacuous():
    """The installed gate must not be passing for the reason C-002 describes."""
    result = staleness.audit(dt.date.today())

    assert result["examined"] > 0, (
        "the installed gate examined nothing -- that is the C-002 defect")
    assert result["verdict"] == "PASS", result.get("stale")


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))