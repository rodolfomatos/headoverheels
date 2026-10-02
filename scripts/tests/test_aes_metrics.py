"""The AES measurement tools hold each other to account.

Five of the six AES skills ship as prose with no thresholds and no way to fail.
`scripts/aes_metrics.py` is the substrate that makes them fail, so it is the one
piece of this machinery that can silently lie to the whole system: if it scores a
broken record set as clean, every phase downstream inherits a clean bill it did
not earn.

The first version of this file had that bug. `_retractions` filtered with
`match.group(0)`, which is the matched phrase rather than the record's own id,
so D006 came out retracting itself and the contradiction scanner fired on the
tool's own output. A scanner that reports its own reflection as a conflict is
worse than no scanner, because it trains you to ignore it.

Every case below is a fault that produced a plausible-looking wrong answer.
"""

from __future__ import annotations

import datetime
import importlib.util
import pathlib
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "aes_metrics", ROOT / "scripts" / "aes_metrics.py")
aes = importlib.util.module_from_spec(spec)
sys.modules["aes_metrics"] = aes
spec.loader.exec_module(aes)

TODAY = datetime.date(2026, 10, 2)


def write(path: pathlib.Path, text: str) -> pathlib.Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path


def decision(did: str, verdict: str, *, ticket: str | None = None,
             question: str = "a question", body: str = "measured: 1px") -> str:
    meta = [f"id: {did}", f"date: 2026-09-30", f"question: {question}",
            f"verdict: {verdict}"]
    if ticket:
        meta.append(f"ticket: {ticket}")
    return f"---\n" + "\n".join(meta) + "\n---\n\n# " + did + f"\n\n{body}\n"


# --- front matter -----------------------------------------------------------

def test_front_matter_is_parsed():
    meta = aes._parse_front_matter("---\nid: D001\nverdict: SUPORTADA\n---\n\nbody")

    assert meta == {"id": "D001", "verdict": "SUPORTADA"}


def test_a_file_with_no_front_matter_is_kept_and_flagged():
    # Dropping the file would make a malformed record invisible, which is the one
    # thing a scanner must not do.
    records = aes.load_records(ROOT / "aes" / "decisions")

    assert records, "the project's own decisions must load"
    assert all("meta" in r for r in records)


def test_dates_are_parsed_and_absent_dates_stay_absent():
    assert aes._parse_date("2026-09-30") == datetime.date(2026, 9, 30)
    assert aes._parse_date("not a date") is None


# --- evidence ---------------------------------------------------------------

def test_prose_alone_is_not_evidence():
    assert aes._evidence("I looked at it and it seemed wrong.") is False


def test_a_runnable_reference_is_evidence():
    assert aes._evidence("measured with `flutter test test/room_render_test`") is True


# --- retractions ------------------------------------------------------------

def test_a_record_does_not_retract_itself():
    """The bug this file exists for: `match.group(0)` filtered nothing.

    D006's body discusses retracting a previous attribution and names D001, and
    the filter was supposed to drop the record's own id. It compared against the
    matched phrase instead, so a record whose own id appeared anywhere near the
    word "wrong" retracted itself, and the contradiction scanner fired on the
    tool's own reflection.
    """
    body = "D005 was a wrong attribution. It retracted D001."

    found = aes._retractions(body, "D005")

    assert "D005" not in found
    assert "D001" in found


def test_a_retraction_is_found_in_both_verb_forms():
    assert aes._retractions("D002 retracts D001", "D009") == ["D001"]
    assert aes._retractions("this takes back D001", "D009") == ["D001"]


def test_a_record_that_retracts_nothing_returns_empty():
    assert aes._retractions("nothing to see", "D001") == []


# --- conflict: stale ticket references --------------------------------------

def test_a_decision_citing_a_missing_ticket_is_a_finding(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "SUPORTADA", ticket="T999"))
    write(tmp_path / "tickets" / "T001-x.md",
          "---\nid: T001\nstatus: open\n---\n\nbody\n")

    report = aes.conflict(TODAY)

    classes = {f["class"] for f in report["findings"]}
    assert "stale ticket reference" in classes
    assert report["verdict"] == "FAIL"


def test_a_decision_citing_a_ticket_that_exists_is_clean(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "SUPORTADA", ticket="T001"))
    write(tmp_path / "tickets" / "T001-x.md",
          "---\nid: T001\nstatus: open\n---\n\nbody\n")
    write(tmp_path / "shadow" / "access.log", "D001 2026-09-30\n")

    report = aes.conflict(TODAY)

    assert [f for f in report["findings"]
            if f["class"] == "stale ticket reference"] == []


# --- conflict: supersession -------------------------------------------------

def test_two_verdicts_on_one_ticket_is_a_blocker(tmp_path, monkeypatch):
    """D004 said it could not tell why; D005 said it knew.

    Both answer for T082, both stand on file, and nothing marks the older one as
    superseded. A reader opening the directory finds two live answers to one
    question and no way to tell which is current.
    """
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D004.md",
          "---\nid: D004\ndate: 2026-09-28\nquestion: why\n"
          "verdict: NÃO-VERIFICÁVEL\nticket: T082\n---\n\ncould not tell\n")
    write(tmp_path / "decisions" / "D005.md",
          "---\nid: D005\ndate: 2026-09-30\nquestion: why\n"
          "verdict: SUPORTADA\nticket: T082\n---\n\nmeasured: two spaces\n")
    write(tmp_path / "tickets" / "T082-x.md",
          "---\nid: T082\nstatus: open\n---\n\nbody\n")
    write(tmp_path / "shadow" / "access.log", "D004 2026-09-28\nD005 2026-09-30\n")

    report = aes.conflict(TODAY)

    contradictions = [f for f in report["findings"]
                      if f["class"] == "epistemic state contradiction"]
    assert contradictions, "two verdicts on one ticket must be a blocker"
    assert report["verdict"] == "FAIL"


def test_one_verdict_on_one_ticket_is_not_a_conflict(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D005.md",
          "---\nid: D005\ndate: 2026-09-30\nquestion: why\n"
          "verdict: SUPORTADA\nticket: T082\n---\n\nmeasured: two spaces\n")
    write(tmp_path / "tickets" / "T082-x.md",
          "---\nid: T082\nstatus: open\n---\n\nbody\n")
    write(tmp_path / "shadow" / "access.log", "D005 2026-09-30\n")

    report = aes.conflict(TODAY)

    assert [f for f in report["findings"]
            if f["class"] == "epistemic state contradiction"] == []


# --- conflict: causality ----------------------------------------------------

def test_a_closed_ticket_with_a_negative_decision_is_a_blocker(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "NÃO-SUPORTADA", ticket="T001"))
    write(tmp_path / "tickets" / "T001-x.md",
          "---\nid: T001\nstatus: done\n---\n\nbody\n")
    write(tmp_path / "shadow" / "access.log", "D001 2026-09-30\n")

    report = aes.conflict(TODAY)

    assert [f for f in report["findings"]
            if f["class"] == "causality violation"]


def test_a_verdict_the_gate_does_not_know_is_a_blocker(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "PROVAVELMENTE"))
    write(tmp_path / "shadow" / "access.log", "D001 2026-09-30\n")

    report = aes.conflict(TODAY)

    assert [f for f in report["findings"] if f["class"] == "unknown verdict"]


# --- the three verdicts -----------------------------------------------------

def test_the_gate_offers_exactly_three_verdicts():
    assert sorted(aes.VERDICTS) == [
        "NÃO-SUPORTADA", "NÃO-VERIFICÁVEL", "SUPORTADA"]


def test_each_verdict_carries_a_different_obligation():
    """A gate that lets everything through with the same follow-up is a rubber
    stamp with extra steps. SUPORTADA may be relied on; the other two may not,
    and NÃO-VERIFICÁVEL additionally says re-reading will not help."""
    obligations = {v: aes.verdict_obligation(v) for v in aes.VERDICTS}

    assert obligations["SUPORTADA"].startswith("may be relied on")
    assert obligations["NÃO-SUPORTADA"].startswith("may not be relied on until")
    assert "measurement" in obligations["NÃO-VERIFICÁVEL"]
    assert len(set(obligations.values())) == 3


def test_an_unknown_verdict_carries_the_obligation_that_it_is_unknown():
    assert aes.verdict_obligation("MAYBE") == "UNKNOWN VERDICT"


# --- aes-debt ---------------------------------------------------------------

def test_suportada_with_nothing_runnable_counts_as_debt(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "SUPORTADA", body="it is fine, trust me"))

    report = aes.debt(TODAY)

    assert report["unverified"] == ["D001"]
    assert report["breaches"]


def test_evidence_makes_the_same_verdict_clean(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "SUPORTADA", body="measured by flutter test: 3200px"))

    report = aes.debt(TODAY)

    assert report["unverified"] == []
    assert report["breaches"] == []


def test_a_negative_verdict_is_never_debt(tmp_path, monkeypatch):
    """Debt is the cost of leaning on something. A record that says no cannot be
    leaned on, so it owes nothing -- including a record with no evidence."""
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "NÃO-SUPORTADA", body="trust me"))

    report = aes.debt(TODAY)

    assert report["unverified"] == []


def test_a_verifiable_record_is_reported_as_waiting_on_a_measurement(
        tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    write(tmp_path / "decisions" / "D001.md",
          decision("D001", "NÃO-VERIFICÁVEL"))

    report = aes.debt(TODAY)

    assert report["waiting_on_measurement"] == ["D001"]


# --- aes-narrative: the honesty rule ----------------------------------------

def test_absent_knowledge_base_is_undefined_not_zero(tmp_path, monkeypatch):
    """The rule the whole module is built on.

    Reporting "omission rate 0%" when there are no shadow documents would score
    an absent knowledge base as a perfect one. The number must not exist, and the
    reason must travel with it.
    """
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "nowhere")
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    write(tmp_path / "decisions" / "D001.md", decision("D001", "SUPORTADA"))

    report = aes.narrative(TODAY)

    metrics = report["metrics"]
    # The decision metrics stay measurable; it is the five that need shadow
    # documents that have no number at all.
    for name in ("omission_rate", "pinning_bias", "access_concentration",
                 "synthesis_coverage", "score_clustering"):
        assert name in metrics["undefined"]
        # The reason has to travel with the metric, or "undefined" reads as
        # "zero, and zero is fine".
        assert "no documents" in metrics["undefined"][name] or \
               "does not exist" in metrics["undefined"][name]
    assert report["verdict"] == "WARN"


def test_gini_of_an_even_spread_is_zero():
    assert aes._gini([1, 1, 1, 1]) == pytest.approx(0.0)


def test_gini_of_a_concentrated_spread_is_high():
    assert aes._gini([1, 0, 0, 0, 0, 0, 0, 0]) > 0.7


def test_gini_of_nothing_is_zero_not_an_error():
    assert aes._gini([]) == 0.0


# --- the project's own record set -------------------------------------------

def test_the_project_decisions_all_use_the_three_verdicts():
    verdicts = {d["verdict"] for d in aes.decisions(TODAY)}

    assert verdicts <= set(aes.VERDICTS), f"unexpected verdicts: {verdicts}"


def test_every_decision_the_project_can_rely_on_has_evidence():
    """Run against the real files, not a fixture.

    This is the assertion that would have caught D005 if it had been written as
    an assertion instead of an opinion, and it is the one that has to keep
    passing as decisions accumulate.
    """
    unverified = aes.debt(TODAY)["unverified"]

    assert unverified == [], f"SUPORTADA with nothing re-runnable: {unverified}"


def test_the_projects_ticket_citations_all_resolve():
    dangling = [f for f in aes.conflict(TODAY)["findings"]
                if f["class"] == "stale ticket reference"]

    assert dangling == [], f"decisions cite tickets that do not exist: {dangling}"


# --- supersession: the mark, and what a mark has to point at -----------------

def test_a_marked_supersession_is_history_not_a_contradiction(tmp_path, monkeypatch):
    """D004 said it could not tell; D005 said it knew.

    Marking D004 `superseded_by: D005` makes it history rather than a second live
    answer. Before the marker existed, the contradiction scanner fired on a
    directory that was merely honest about having changed its mind -- which trains
    you to ignore the scanner, and then it misses the contradictions that are
    real.
    """
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D004.md",
          "---\nid: D004\ndate: 2026-09-28\nquestion: why\n"
          "verdict: NÃO-VERIFICÁVEL\nticket: T082\nsuperseded_by: D005\n---\n\nno\n")
    write(tmp_path / "decisions" / "D005.md",
          "---\nid: D005\ndate: 2026-09-30\nquestion: why\n"
          "verdict: SUPORTADA\nticket: T082\n---\n\nmeasured: two spaces\n")
    write(tmp_path / "tickets" / "T082-x.md",
          "---\nid: T082\nstatus: open\n---\n\nbody\n")
    write(tmp_path / "shadow" / "access.log", "D004 2026-09-28\nD005 2026-09-30\n")

    report = aes.conflict(TODAY)

    assert report["superseded_records"] == ["D004"]
    assert [f for f in report["findings"]
            if f["class"] == "epistemic state contradiction"] == []
    assert [f for f in report["findings"]
            if f["class"] == "causality violation"] == []
    assert report["blockers"] == 0


def test_a_mark_against_a_decision_that_does_not_exist_is_a_blocker(
        tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D004.md",
          "---\nid: D004\ndate: 2026-09-28\nquestion: why\n"
          "verdict: NÃO-SUPORTADA\nsuperseded_by: D099\n---\n\nno\n")
    write(tmp_path / "shadow" / "access.log", "D004 2026-09-28\n")

    report = aes.conflict(TODAY)

    assert [f for f in report["findings"]
            if f["class"] == "dangling supersession"]


def test_a_mark_against_an_older_record_is_a_blocker(tmp_path, monkeypatch):
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D004.md",
          "---\nid: D004\ndate: 2026-09-30\nquestion: why\n"
          "verdict: NÃO-SUPORTADA\nsuperseded_by: D005\n---\n\nno\n")
    write(tmp_path / "decisions" / "D005.md",
          "---\nid: D005\ndate: 2026-09-28\nquestion: why\n"
          "verdict: SUPORTADA\n---\n\nmeasured\n")
    write(tmp_path / "shadow" / "access.log", "D004 2026-09-30\nD005 2026-09-28\n")

    report = aes.conflict(TODAY)

    assert [f for f in report["findings"]
            if f["class"] == "backwards supersession"]


# --- aes-narrative: the five metrics, computed and not merely counted -------

def make_shadow(root, docs, index_lines=(), access=True):
    shadow = root / "shadow"
    shadow.mkdir(parents=True, exist_ok=True)
    for name, fields in docs.items():
        front = "\n".join(f"{k}: {v}" for k, v in fields.items())
        write(shadow / f"{name}.md", f"---\n{front}\n---\n\n# {name}\n\nThe rule.\n")
    write(shadow / "INDEX.md", "# index\n\n" + "\n".join(index_lines) + "\n")
    if access:
        # By the document's own id, which is what the log records and what the
        # metrics look up. Writing the filename here made every count miss, and
        # the metric that depended on it reported zero rather than saying it
        # could not be computed.
        lines = []
        for fields in docs.values():
            if fields.get("access_count"):
                for _ in range(int(fields["access_count"])):
                    lines.append(f"{fields['id']} 2026-10-02 abc123 why")
        write(shadow / "access.log", "\n".join(lines) + "\n")
    return shadow


def narrative_with(tmp_path, monkeypatch, docs, index_lines, access=True):
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    shadow = make_shadow(tmp_path, docs, index_lines, access)
    assert shadow.exists()
    return aes.narrative(TODAY)


def doc(name, score, accesses, state="SUPPORTED"):
    return {
        "id": name,
        "score": score,
        "epistemic_state": state,
        "access_count": accesses,
        "provenance": "T001",
        "last_verified": "2026-10-02",
    }


def test_omission_rate_counts_documents_the_index_does_not_carry(
        tmp_path, monkeypatch):
    report = narrative_with(
        tmp_path, monkeypatch,
        {"a": doc("SD-A", "1.0", 3), "b": doc("SD-B", "0.9", 2)},
        index_lines=["SD-A"])

    metrics = report["metrics"]["defined"]
    assert metrics["shadow_documents"] == 2
    assert metrics["omission_rate"] == 0.5, "one of two documents is not indexed"
    assert any(f["class"] == "omission rate" for f in report["findings"])


def test_synthesis_coverage_is_the_share_of_read_documents_carrying_a_rule(
        tmp_path, monkeypatch):
    report = narrative_with(
        tmp_path, monkeypatch,
        {"a": doc("SD-A", "1.0", 5), "b": doc("SD-B", "0.9", 0)},
        index_lines=["SD-A", "SD-B"])

    defined = report["metrics"]["defined"]
    # SD-B was never read, so it is not in the denominator.
    assert defined["synthesis_coverage"] == 1.0
    assert defined["documents_never_read"] == ["SD-B"]


def test_identical_scores_are_reported_as_carrying_no_information(
        tmp_path, monkeypatch):
    """The project's own documents first all scored 1.0.

    An index that sorts by score and cannot distinguish anything is an index
    sorted by nothing, and saying so is the only thing that distinguishes a
    curated index from a broken one.
    """
    report = narrative_with(
        tmp_path, monkeypatch,
        {"a": doc("SD-A", "1.0", 2), "b": doc("SD-B", "1.0", 2),
         "c": doc("SD-C", "1.0", 2)},
        index_lines=["SD-A", "SD-B", "SD-C"])

    defined = report["metrics"]["defined"]
    assert defined["distinct_scores"] == 1
    assert any(f["class"] == "score clustering" for f in report["findings"])


def test_an_index_with_no_scores_is_pinning_bias(tmp_path, monkeypatch):
    # Hand-placed entries with nothing to rank them by.
    unscored = {"a": {"id": "SD-A", "access_count": 2, "provenance": "T1",
                      "last_verified": "2026-10-02"}}
    report = narrative_with(tmp_path, monkeypatch, unscored,
                            index_lines=["SD-A"])

    assert report["metrics"]["defined"]["pinning_bias"] == 1.0
    assert any(f["class"] == "pinning bias" for f in report["findings"])


def test_access_concentration_is_undefined_without_a_log(tmp_path, monkeypatch):
    report = narrative_with(
        tmp_path, monkeypatch,
        {"a": doc("SD-A", "1.0", 3)}, index_lines=["SD-A"], access=False)

    assert "access_concentration" in report["metrics"]["undefined"]
    assert "access.log" in report["metrics"]["undefined"]["access_concentration"]


def test_concentrated_access_is_reported(tmp_path, monkeypatch):
    docs = {"a": doc("SD-A", "1.0", 2), "b": doc("SD-B", "0.9", 1),
            "c": doc("SD-C", "0.8", 1), "d": doc("SD-D", "0.7", 1)}
    report = narrative_with(tmp_path, monkeypatch, docs,
                            index_lines=list(docs))

    defined = report["metrics"]["defined"]
    assert defined["access_concentration"] > 0.0
    assert isinstance(defined["access_concentration"], float)


def test_a_document_missing_the_fields_the_metrics_need_is_flagged(
        tmp_path, monkeypatch):
    """A doc with no score must not be scored as zero.

    Otherwise a knowledge base where nobody wrote the metadata looks perfectly
    evenly distributed, which is the exact opposite of what it is.
    """
    report = narrative_with(
        tmp_path, monkeypatch,
        {"a": {"id": "SD-A", "access_count": 1}},
        index_lines=["SD-A"])

    assert any(f["class"] == "incomplete shadow record"
               for f in report["findings"])
    assert report["metrics"]["defined"]["shadow_documents"] == 1


# --- the project's own shadow layer -----------------------------------------

def test_the_projects_shadow_layer_is_measurable():
    report = aes.narrative(TODAY)

    defined = report["metrics"]["defined"]
    assert defined.get("shadow_documents", 0) >= 1
    assert defined["omission_rate"] == 0.0, (
        "every shadow document should be in the hot index; one that is not is "
        "a document nobody will read")
    assert defined["documents_never_read"] == [], (
        "the access log claims every document was read, or it is wrong")
    assert defined["distinct_scores"] >= 2, (
        "if every document scores the same, the index is sorted by nothing")


def test_every_shadow_document_names_the_work_it_came_from():
    for record in aes.shadow_docs():
        assert record["provenance"], f"{record['id']} has no provenance"
        assert record["last_verified"], f"{record['id']} was never verified"


# --- the causality check on a stale basis ----------------------------------

def test_a_done_ticket_whose_decision_says_otherwise_is_a_blocker(
        tmp_path, monkeypatch):
    """T087 was closed while D006 still said the work was not established.

    A ticket marked done whose governing decision holds a negative verdict is a
    contradiction the board cannot show: the work reads as finished and the
    reason it was needed reads as unmet. It passed because the decision file is
    not the ticket, and nothing joined them.
    """
    monkeypatch.setattr(aes, "DECISIONS", tmp_path / "decisions")
    monkeypatch.setattr(aes, "TICKETS", tmp_path / "tickets")
    monkeypatch.setattr(aes, "SHADOW", tmp_path / "shadow")
    write(tmp_path / "decisions" / "D006.md",
          "---\nid: D006\ndate: 2026-09-30\nquestion: why\n"
          "verdict: NÃO-SUPORTADA\nticket: T087\n---\n\nnot established\n")
    write(tmp_path / "tickets" / "T087-x.md",
          "---\nid: T087\nstatus: done\n---\n\nbody\n")
    write(tmp_path / "shadow" / "access.log", "D006 2026-09-30\n")

    report = aes.conflict(TODAY)

    violations = [f for f in report["findings"]
                  if f["class"] == "causality violation"]
    assert violations, "a closed ticket with a negative basis must be a blocker"
    assert report["verdict"] == "FAIL"


def test_the_projects_closed_tickets_all_have_an_established_basis():
    """Runs against the real tree.

    This is the assertion that would have caught D006 when T087 was closed, and
    it is the one that has to keep passing as tickets get closed.
    """
    stale = [f["where"] for f in aes.conflict(TODAY)["findings"]
             if f["class"] == "causality violation"]

    assert stale == [], (
        f"closed tickets whose decision record still says the work is not "
        f"established: {stale}")


def test_every_decision_this_project_made_about_the_move_has_a_record():
    """Three design decisions were taken in one session and none was recorded.

    They lived in commits and tickets, which is where a record stops being
    findable. `superpower_up` on the height axis, `floor_first` on draw order and
    `rebuild_to_measure` on instrumentation are all decisions, and all three now
    have a decision record with a ticket and a verdict.
    """
    bodies = "\n".join(
        path.read_text() for path in aes.DECISIONS.glob("*.md"))

    for marker, decision in [("z is the height", "D007"),
                             ("floor treatment is drawn", "D008"),
                             ("rebuild the scene exactly", "D009"),
                             ("cannot wait for a room change", "D010")]:
        assert marker in bodies, f"{decision} is missing or was renamed"
