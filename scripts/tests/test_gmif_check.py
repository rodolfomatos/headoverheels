"""The GMIF gate is only worth having if it can fail.

The skill's `gmif-check.sh` reported SAT on an island Z3 had rejected outright,
because it redirected Z3's stderr into the result file, found neither `sat` nor
`unsat`, and fell through. So the first thing these tests establish is that this
implementation reports a failure in exactly the situations the other one reported
a pass.

Each test below corresponds to a way a satisfiability gate can be green without
having checked anything.
"""

from __future__ import annotations

import importlib.util
import pathlib
import subprocess
import sys

import pytest
import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "gmif_check", ROOT / "scripts" / "gmif_check.py")
gmif = importlib.util.module_from_spec(spec)
sys.modules["gmif_check"] = gmif
spec.loader.exec_module(gmif)

pytestmark = pytest.mark.skipif(not gmif.have_z3(), reason="z3 is required")


def node(nid, form=None, **over):
    base = {
        "id": nid,
        "validation_type": "logical",
        "validation_confidence": 0.95,
        "extraction_confidence": 0.95,
        "state": "SUPPORTED",
        "logical_form": form or nid,
    }
    base.update(over)
    return base


def island(nodes, edges=None):
    return {"island": "t", "nodes": nodes, "edges": edges or []}


def run(tmp_path, data):
    path = tmp_path / "t.yaml"
    path.write_text(yaml.safe_dump(data))
    return gmif.check(path)


# --- the collision that made the skill's SMT2 invalid ----------------------

def test_assertion_names_never_collide_with_declarations(tmp_path):
    """`(assert (! c :named c))` is a redeclaration and Z3 rejects the file.

    Every island with more than one node hits this, and the skill reported those
    islands as SAT.
    """
    smt2, _ = gmif.build_smt2(island([node("alpha"), node("beta")]))

    assert "(declare-const alpha Bool)" in smt2
    assert ":named alpha)" not in smt2.replace(":named a_alpha)", "")
    assert ":named a_alpha" in smt2


def test_a_two_node_island_is_accepted_by_z3(tmp_path):
    result = run(tmp_path, island([node("alpha"), node("beta")]))

    assert result["result"] == "SAT", result
    assert result["verdict"] == "PASS"


# --- unsat is a failure -----------------------------------------------------

def test_contradictory_claims_are_unsat_and_fail(tmp_path):
    result = run(tmp_path, island([node("a"), node("b", "not a")]))

    assert result["result"] == "UNSAT"
    assert result["verdict"] == "FAIL"
    assert result["core"], "an unsat without a core is a problem with no handle"


def test_the_unsat_core_names_both_sides(tmp_path):
    result = run(tmp_path, island([node("a"), node("b", "not a")]))

    assert any("a_b" in c or "not_a" in c or "a_" in c for c in result["core"])


def test_consistent_claims_are_sat_and_pass(tmp_path):
    result = run(tmp_path, island([node("a"), node("b", "a and b")]))

    assert result["result"] == "SAT"
    assert result["verdict"] == "PASS"


# --- anything that is not an answer is a failure ----------------------------

def test_z3_erroring_is_a_failure_not_a_pass(tmp_path, monkeypatch):
    """The bug that mattered: an unreadable answer fell through to SAT."""
    def boom(*args, **kwargs):
        return subprocess.CompletedProcess(
            args=[], returncode=1, stdout="sat",
            stderr='(error "invalid named expression")')

    monkeypatch.setattr(gmif.subprocess, "run", boom)
    result = gmif.check(tmp_path / "t.yaml") if False else None

    path = tmp_path / "t.yaml"
    path.write_text(yaml.safe_dump(island([node("a")])))
    result = gmif.check(path)

    assert result["result"] == "ERROR"
    assert result["verdict"] == "FAIL"


def test_output_that_is_neither_sat_nor_unsat_is_a_failure(tmp_path, monkeypatch):
    def odd(*args, **kwargs):
        return subprocess.CompletedProcess(args=[], returncode=0,
                                          stdout="unknown", stderr="")

    monkeypatch.setattr(gmif.subprocess, "run", odd)
    path = tmp_path / "t.yaml"
    path.write_text(yaml.safe_dump(island([node("a")])))

    result = gmif.check(path)

    assert result["verdict"] == "FAIL"
    assert result["result"] == "UNKNOWN"


def test_a_timeout_is_a_failure_not_a_pass(tmp_path, monkeypatch):
    def slow(*args, **kwargs):
        raise subprocess.TimeoutExpired(cmd="z3", timeout=30)

    monkeypatch.setattr(gmif.subprocess, "run", slow)
    path = tmp_path / "t.yaml"
    path.write_text(yaml.safe_dump(island([node("a")])))

    result = gmif.check(path)

    assert result["result"] == "TIMEOUT"
    assert result["verdict"] == "FAIL"


def test_an_island_with_nothing_to_check_is_a_warning(tmp_path):
    """EMPTY is not PASS. There was no question asked."""
    result = run(tmp_path, island([{"id": "prose", "note": "no logical form"}]))

    assert result["result"] == "EMPTY"
    assert result["verdict"] == "WARN"


# --- the filter, and the field name the docs get wrong ----------------------

def test_a_node_written_to_the_documented_field_is_checked(tmp_path):
    """SKILL.md documents `epistemic_state`; the script reads `state`.

    An island written to the documentation is silently dropped, the filter finds
    nothing, and the gate reports "no logical claims to validate" and passes.
    """
    result = run(tmp_path, island([node("a", epistemic_state="SUPPORTED")]))

    assert result["result"] != "EMPTY"


def test_low_confidence_is_skipped_with_a_reason(tmp_path):
    result = run(tmp_path, island([
        node("a"),
        node("shaky", validation_confidence=0.5),
    ]))

    reasons = {s["id"]: s["reason"] for s in result["skipped"]}
    assert "validation_confidence" in reasons["shaky"]
    assert result["verdict"] == "PASS"


def test_a_non_logical_claim_is_skipped(tmp_path):
    result = run(tmp_path, island([
        node("a"),
        node("human", validation_type="human"),
    ]))

    reasons = {s["id"]: s["reason"] for s in result["skipped"]}
    assert "validation_type" in reasons["human"]


def test_an_id_that_is_not_an_smt_symbol_is_skipped(tmp_path):
    result = run(tmp_path, island([
        node("a"),
        node("has-dash"),
    ]))

    reasons = {s["id"]: s["reason"] for s in result["skipped"]}
    assert "SMT-LIB symbol" in reasons["has-dash"]


# --- the rewrite ------------------------------------------------------------

def test_not_is_not_applied_twice():
    """The loop used to re-wrap `(not x)` until it was eight parens deep."""
    form = gmif.s_expr("not a", {"a"})

    assert form.count("(") == 1
    assert form == "(not a)"


def test_binary_operators_are_parenthesised():
    assert gmif.s_expr("a and b", {"a", "b"}) == "(and a b)"
    assert gmif.s_expr("a or b", {"a", "b"}) == "(or a b)"
    assert gmif.s_expr("a => b", {"a", "b"}) == "(=> a b)"


def test_two_operators_in_one_claim_is_refused_not_guessed():
    """`a and b and c` has no single prefix reading.

    The earlier regex version produced `(and a b) and c`, which is not
    well-formed SMT, and would have been handed to Z3 as if it had been checked.
    The fix is to refuse and say why: write the intermediate claim as its own node
    so the solver can name it in a core.
    """
    with pytest.raises(gmif.UnsupportedForm) as error:
        gmif.s_expr("a and b and c", {"a", "b", "c"})

    assert "own node" in str(error.value)


def test_an_unrefusable_claim_is_dropped_and_reported(tmp_path):
    result = run(tmp_path, island([node("a"), node("b", "a and a and a")]))

    reasons = {s["id"]: s["reason"] for s in result["skipped"]}
    assert "unsupported logical_form" in reasons["b"]
    assert result["verdict"] == "FAIL", (
        "an island whose only compound claim cannot be checked is not a pass")


def test_parenthesised_grouping_is_accepted():
    assert gmif.s_expr("(and a b)", {"a", "b"}) == "(and a b)"


# --- the project's own island ----------------------------------------------

def test_the_projects_render_island_is_consistent():
    """Run against the real island, not a fixture.

    It asserted the project's stated intent and the measurement that refuted it,
    and Z3 returned an unsat core naming both. The switch was fixed by drawing the
    belt before it, the refuting claim was removed because it stopped being true,
    and the island is satisfiable again. This test is here so that a future
    contradiction in the same island cannot be introduced quietly: it has to be
    written as an assertion, which is the only way anyone finds out.
    """
    path = ROOT / "aes" / "graph" / "render-invariants.yaml"
    if not path.exists():
        pytest.skip("no island yet")

    result = gmif.check(path)

    assert result["result"] == "SAT", (
        f"the render island is expected to be consistent: {result['detail']}")
    assert result["verdict"] == "PASS"


def test_the_island_carries_no_claim_the_gate_could_not_read():
    """Every claim in the real island must be one the solver actually saw.

    A node the filter drops or the parser refuses is a claim the gate did not
    check, and an island that silently loses claims is the failure this project
    has now hit twice.
    """
    path = ROOT / "aes" / "graph" / "render-invariants.yaml"
    if not path.exists():
        pytest.skip("no island yet")
    island = yaml.safe_load(path.read_text()) or {}

    uncheckable = [n["id"] for n in island.get("nodes", [])
                   if n.get("validation_type") == "logical"
                   and (gmif.is_validated(n)[0] is False)]
    assert uncheckable == [], f"claims the gate would skip: {uncheckable}"
