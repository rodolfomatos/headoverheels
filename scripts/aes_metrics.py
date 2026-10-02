#!/usr/bin/env python3
"""The measurement substrate for the AES skills.

Five of the six AES skills ship as a specification and nothing else: no scripts,
no thresholds, no way to fail. That makes them prose. Prose cannot be wrong in a
way anyone can detect, which means a phase that "passed" them proves nothing --
and a project that believes it ran them is carrying a debt it cannot see.

This module is the missing half. It loads what the project actually wrote --
decision records, tickets, peer-review rubrics, access logs -- and computes the
quantities the specifications name, so each claim has a number that can come out
wrong.

Two rules govern what goes in here.

**An absent input is reported as absent, never as zero.** There are no shadow
documents in this project, so the narrative metrics that depend on them are
reported as undefined with the reason. A tool that scores "no knowledge base" as
a perfect knowledge base is worse than no tool, because it launders a gap into a
pass.

**Every threshold is a named constant, not a literal buried in a comparison.**
`aes-debt-rules` exists to extract these. They are here, and they are extractable.

Usage:
    python3 scripts/aes_metrics.py debt
    python3 scripts/aes_metrics.py conflict
    python3 scripts/aes_metrics.py narrative
    python3 scripts/aes_metrics.py pm
    python3 scripts/aes_metrics.py all --json
"""

from __future__ import annotations

import argparse
import datetime
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
AES = ROOT / "aes"
DECISIONS = AES / "decisions"
TICKETS = AES / "tickets"
REVIEWS = AES / "peer-reviews"
SHADOW = AES / "shadow"
ACCESS_LOG = SHADOW / "access.log"
KANBAN = AES / "kanban.md"

# --- thresholds -------------------------------------------------------------
# Named so `aes-debt-rules` can extract them and so a change is a visible diff.

DEBT_STALE_DAYS = 30
DEBT_MAX_UNVERIFIED_RATIO = 0.50
DEBT_MAX_SUPERSEDED_RATIO = 0.40
NARRATIVE_MAX_OMISSION = 0.30
NARRATIVE_MAX_GINI = 0.70
NARRATIVE_MAX_PINNED_RATIO = 0.50
CONFLICT_MAX_AGE_DAYS = 3650

# --- the three verdicts and what each one obliges --------------------------

VERDICTS = {
    "SUPORTADA": {
        "obligation": "may be relied on; carries the evidence that supports it",
        "expires": False,
    },
    "NÃO-SUPORTADA": {
        "obligation": "may not be relied on until new evidence lands",
        "expires": False,
    },
    "NÃO-VERIFICÁVEL": {
        "obligation": "may not be relied on, and no amount of re-reading will "
                      "change that; the next step is a measurement, not an opinion",
        "expires": False,
    },
}

FRONTMATTER = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def _parse_front_matter(text: str) -> dict:
    match = FRONTMATTER.match(text)
    if not match:
        return {}
    out = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        out[key.strip()] = value.strip().strip("'\"")
    return out


def load_records(directory: pathlib.Path) -> list[dict]:
    """Every markdown file under a directory, with its front matter and a date.

    A file whose front matter cannot be parsed is kept, with no fields, so that
    a malformed record shows up in the counts instead of quietly not being one.
    """
    if not directory.exists():
        return []
    records = []
    for path in sorted(directory.rglob("*.md")):
        text = path.read_text()
        meta = _parse_front_matter(text)
        records.append({
            "path": path,
            "rel": _relative(path),
            "meta": meta,
            "body": text,
            "date": _parse_date(meta.get("date", "")),
        })
    return records


def _relative(path: pathlib.Path) -> str:
    """The path as the project would name it, or absolute if it is not in it.

    `relative_to(ROOT)` raises on a path outside the repository, which is exactly
    what a caller passing its own fixtures wants, and a tool that only works on
    the real tree cannot be tested against the faults it is supposed to catch.
    """
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def _parse_date(value: str) -> datetime.date | None:
    for fmt in ("%Y-%m-%d", "%Y/%m/%d"):
        try:
            return datetime.datetime.strptime(value, fmt).date()
        except ValueError:
            continue
    return None


def age_days(record: dict, today: datetime.date) -> int | None:
    if record["date"] is None:
        return None
    return (today - record["date"]).days


def decisions(today: datetime.date) -> list[dict]:
    out = []
    for record in load_records(DECISIONS):
        meta = record["meta"]
        record["verdict"] = meta.get("verdict")
        record["id_name"] = meta.get("id") or record["path"].stem
        record["question"] = meta.get("question", "")
        record["ticket"] = meta.get("ticket")
        record["age"] = age_days(record, today)
        record["id_name"] = meta.get("id") or record["path"].stem
        record["retracts"] = _retractions(record["body"], record["id_name"])
        record["evidence"] = _evidence(record["body"])
        record["known_verdict"] = record["verdict"] in VERDICTS
        record["superseded_by"] = meta.get("superseded_by")
        out.append(record)
    return out


def _retractions(body: str, own_id: str) -> list[str]:
    """Decision ids this record takes back.

    A retraction is the strongest thing in the system and the easiest to lose:
    D001 takes back an attribution, and nothing in the directory records that it
    did, so the retracted claim stays standing next to the retraction forever.
    """
    found = re.findall(r"\bD(\d{3})\b", body)
    cited = set()
    for match in re.finditer(
        r"retract\w*|took back|takes back|wrong attribution|was wrong",
        body,
        re.IGNORECASE,
    ):
        # Only what follows the verb. The window used to extend backwards as
        # well, so "D002 retracts D001" cited D002 as retracted by D002: the
        # scanner would have reported a record superseding itself.
        window = body[match.end():match.end() + 400]
        cited.update(re.findall(r"\bD(\d{3})\b", window))
    return sorted(f"D{n}" for n in cited if f"D{n}" != own_id)


def _evidence(body: str) -> bool:
    """Whether the record points at something that can be re-run.

    "Measured", "verified", a test name, a file path, a command. Prose that only
    argues is not evidence, and a verdict with no evidence is an opinion with a
    formal header.
    """
    patterns = [
        r"\bmeasured\b", r"\bverified\b", r"\$\s", r"\bmake check\b",
        r"flutter test", r"pytest", r"\.dart\b", r"\.py\b", r"\.json\b",
        r"```",
    ]
    return any(re.search(p, body, re.IGNORECASE) for p in patterns)


def tickets() -> dict:
    by_id = {}
    for record in load_records(TICKETS):
        meta = record["meta"]
        tid = meta.get("id") or record["path"].stem.split("-")[0]
        by_id[tid] = {
            "id": tid,
            "status": meta.get("status", "unknown"),
            "severity": meta.get("severity", "unspecified"),
            "rel": record["rel"],
        }
    return by_id


def verdict_obligation(verdict: str) -> str:
    return VERDICTS.get(verdict, {}).get("obligation", "UNKNOWN VERDICT")


# --- aes-debt ---------------------------------------------------------------

def debt(today: datetime.date) -> dict:
    """Epistemic debt: claims nobody has checked, claims taken back, and gaps.

    Three ratios, each with a named threshold. `unverified` is the one that
    matters most: a decision that reached SUPORTADA without anything anyone can
    re-run is the failure this whole system exists to prevent, and it looks
    exactly like a decision that did the work.
    """
    records = decisions(today)
    unverified = [r for r in records
                  if r["verdict"] == "SUPORTADA" and not r["evidence"]]
    stale = [r for r in records
             if r["age"] is not None and r["age"] > DEBT_STALE_DAYS
             and r["verdict"] == "SUPORTADA"]
    retractable = [r for r in records if r["retracts"]]
    unknown = [r for r in records if not r["known_verdict"]]
    unverifiable = [r for r in records if r["verdict"] == "NÃO-VERIFICÁVEL"]

    total = len(records) or 1
    ratios = {
        "unverified": len(unverified) / total,
        "stale": len(stale) / total,
        "retracting": len(retractable) / total,
    }

    breaches = []
    if ratios["unverified"] > DEBT_MAX_UNVERIFIED_RATIO:
        breaches.append(
            f"unverified SUPORTADA {ratios['unverified']:.0%} > "
            f"{DEBT_MAX_UNVERIFIED_RATIO:.0%}: "
            f"{[r['id_name'] for r in unverified]}")
    if ratios["retracting"] > DEBT_MAX_SUPERSEDED_RATIO:
        breaches.append(
            f"records that retract something {ratios['retracting']:.0%} > "
            f"{DEBT_MAX_SUPERSEDED_RATIO:.0%}: "
            f"{[r['id_name'] for r in retractable]}")

    return {
        "skill": "aes-debt",
        "records": len(records),
        "ratios": {k: round(v, 4) for k, v in ratios.items()},
        "thresholds": {
            "unverified": DEBT_MAX_UNVERIFIED_RATIO,
            "retracting": DEBT_MAX_SUPERSEDED_RATIO,
            "stale_days": DEBT_STALE_DAYS,
        },
        "unverified": [r["id_name"] for r in unverified],
        "stale": [r["id_name"] for r in stale],
        "retracting": [r["id_name"] for r in retractable],
        "unknown_verdict": [r["id_name"] for r in unknown],
        "waiting_on_measurement": [r["id_name"] for r in unverifiable],
        "breaches": breaches,
        "verdict": "FAIL" if breaches else "PASS",
    }


# --- aes-conflict -----------------------------------------------------------

def conflict(today: datetime.date) -> dict:
    """The five conflict classes, scanned over what the project actually wrote."""
    every = decisions(today)
    superseded = [r for r in every if r["superseded_by"]]
    records = [r for r in every if not r["superseded_by"]]
    by_id = {r["id_name"]: r for r in every}
    known = tickets()
    findings = []

    # 1. Stale ticket references: a decision citing a ticket that does not exist.
    for record in records:
        tid = record["ticket"]
        if tid and tid not in known:
            findings.append({
                "class": "stale ticket reference",
                "where": record["id_name"],
                "detail": f"cites {tid}, which is not in aes/tickets/. A "
                          f"record that points at work nobody wrote down "
                          f"cannot be relied on, whatever its verdict says.",
                "severity": "blocker",
            })

    # 1c. A decision that governs nothing. Either a decision in general, or a
    #     record that missed its ticket -- and the second is invisible, because
    #     the record reads as authoritative and nothing joins it to the board.
    ungoverned = [r["id_name"] for r in records if not r["ticket"]]
    if ungoverned:
        findings.append({
            "class": "decision with no ticket",
            "where": ", ".join(ungoverned),
            "detail": "these decisions name no ticket. Either they are "
                      "decisions in general, which is worth saying out loud, "
                      "or a record missed its ticket and cannot be found from "
                      "the board.",
            "severity": "minor",
        })

    # 2. Epistemic contradictions: two records answering the same question with
    #    different verdicts, where one retracts the other and the retracted one
    #    is still standing in the directory.
    for record in records:
        for target in record["retracts"]:
            if target not in by_id:
                continue
            other = by_id[target]
            findings.append({
                "class": "epistemic state contradiction",
                "where": record["id_name"],
                "detail":
                    f"{record['id_name']} retracts {target}, which is still on "
                    f"file with verdict {other['verdict']}. A retraction that "
                    f"does not mark the old record leaves two live answers to "
                    f"one question.",
                "severity": "blocker",
            })

    # 3. Causality violations: a ticket closed while the decision that governs
    #    it says the thing is not established.
    for tid, info in known.items():
        if info["status"] not in ("done", "closed"):
            continue
        for record in records:
            if record["ticket"] != tid:
                continue
            if record["verdict"] in ("NÃO-SUPORTADA", "NÃO-VERIFICÁVEL"):
                findings.append({
                    "class": "causality violation",
                    "where": tid,
                    "detail":
                        f"{tid} is {info['status']} but {record['id_name']} "
                        f"holds {record['verdict']}. The work is recorded as "
                        f"finished while its own basis says otherwise.",
                    "severity": "blocker",
                })

    # 3b. Supersession without marking: two records on one ticket answering the
    #     same question with different verdicts. The newer one supersedes and the
    #     older one stays standing, so the directory holds two live answers.
    by_ticket: dict = {}
    for record in records:
        if record["ticket"]:
            by_ticket.setdefault(record["ticket"], []).append(record)
    for tid, group in by_ticket.items():
        verdicts = {r["verdict"] for r in group}
        if len(group) > 1 and len(verdicts) > 1:
            group = sorted(group, key=lambda r: (r["age"] is None, -(r["age"] or 0)))
            newest, older = group[0], group[1:]
            for other in older:
                findings.append({
                    "class": "epistemic state contradiction",
                    "where": newest["id_name"],
                    "detail":
                        f"{newest['id_name']} ({newest['verdict']}) and "
                        f"{other['id_name']} ({other['verdict']}) both answer "
                        f"for {tid} with different verdicts, and the older one "
                        f"is not marked superseded. Supersession is a fact about "
                        f"the record, not an ordering someone remembers.",
                    "severity": "blocker",
                })

    # 4. Unknown verdicts: a record whose verdict is not one of the three. The
    #    gate that refuses to agree is worthless if it accepts anything.
    for record in records:
        if not record["known_verdict"]:
            findings.append({
                "class": "unknown verdict",
                "where": record["id_name"],
                "detail": f"verdict {record['verdict']!r} is not one of "
                          f"{sorted(VERDICTS)}",
                "severity": "blocker",
            })

    # 5. Orphan access entries: the access log is the audit trail; entries that
    #    name nothing are fiction.
    orphans = 0
    if (SHADOW / "access.log").exists():
        for line in (SHADOW / "access.log").read_text().splitlines():
            if line.strip() and len(line.split()) < 2:
                orphans += 1
    else:
        findings.append({
            "class": "missing audit trail",
            "where": "aes/shadow/access.log",
            "detail": "does not exist, so no access to a decision record is "
                      "recorded anywhere. There is no orphan-entry check "
                      "because there is no log to check.",
            "severity": "major",
        })

    for record in superseded:
        target = by_id.get(record["superseded_by"])
        if target is None:
            findings.append({
                "class": "dangling supersession",
                "where": record["id_name"],
                "detail": f"marked superseded_by {record['superseded_by']}, "
                          f"which is not on file. Marking a record against a "
                          f"decision that does not exist silences it without "
                          f"replacing it.",
                "severity": "blocker",
            })
        elif record["age"] is not None and target["age"] is not None \
                and target["age"] > record["age"]:
            findings.append({
                "class": "backwards supersession",
                "where": record["id_name"],
                "detail": f"{target['id_name']} is {target['date']} and older "
                          f"than the record it supersedes ({record['date']})",
                "severity": "blocker",
            })

    blockers = [f for f in findings if f["severity"] == "blocker"]
    return {
        "skill": "aes-conflict",
        "findings": findings,
        "superseded_records": [r["id_name"] for r in superseded],
        "blockers": len(blockers),
        "orphan_access_entries": orphans,
        "verdict": "FAIL" if blockers else ("WARN" if findings else "PASS"),
    }


# --- aes-narrative ----------------------------------------------------------

def _gini(values: list[float]) -> float:
    """Gini coefficient. 0 is a perfectly even spread, 1 is one owner."""
    if not values:
        return 0.0
    ordered = sorted(values)
    n = len(ordered)
    total = sum(ordered)
    if total == 0:
        return 0.0
    cumulative = sum((i + 1) * v for i, v in enumerate(ordered))
    return (2 * cumulative) / (n * total) - (n + 1) / n


SHADOW_FIELDS = ("id", "score", "epistemic_state", "access_count", "provenance")


def shadow_docs() -> list[dict]:
    """The shadow layer, with the fields a doc has to carry to be measurable.

    A doc missing `score` or `access_count` is not silently scored as zero: it is
    returned with `complete: False`, because the alternative is a knowledge base
    that looks evenly distributed because none of its documents say.
    """
    if not SHADOW.exists():
        return []
    docs = []
    for path in sorted(SHADOW.glob("*.md")):
        if path.name == "INDEX.md":
            continue
        text = path.read_text()
        meta = _parse_front_matter(text)
        docs.append({
            "path": path,
            "id": meta.get("id") or path.stem,
            "score": float(meta["score"]) if meta.get("score") else None,
            "access_count": int(meta["access_count"]) if meta.get("access_count") else None,
            "last_verified": meta.get("last_verified"),
            "provenance": meta.get("provenance"),
            "state": meta.get("epistemic_state"),
            "has_rule": "# " in text,
            "complete": all(meta.get(f) for f in SHADOW_FIELDS if f != "state"),
        })
    return docs


def access_counts() -> dict:
    """How often each document was actually read, from the audit log.

    An absent log means the count is unknown, not zero, and the metrics that
    depend on it say so.
    """
    # Derived from SHADOW rather than from the module constant, so that moving
    # SHADOW moves the log with it. Reading the constant meant a caller that
    # pointed the tool at another shadow layer got this project's real access
    # counts mixed into its own numbers, which is worse than getting none.
    log = SHADOW / "access.log"
    if not log.exists():
        return {}
    counts: dict = {}
    for line in log.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) >= 2:
            counts[parts[0]] = counts.get(parts[0], 0) + 1
    return counts


def narrative(today: datetime.date) -> dict:
    """Five ways the story this project tells can differ from what it did.

    Every metric names the input it needs. An absent input yields an undefined
    metric with the reason attached, never a zero: this project had no shadow
    directory at all, and an omission rate of 0% would have read as a complete
    index where there was no index at all.
    """
    docs = shadow_docs()
    records = decisions(today)
    findings: list = []
    metrics: dict = {"defined": {}, "undefined": {}}

    metrics["defined"].update({
        "shadow_documents": len(docs),
        "decisions": len(records),
        "decisions_with_re_runnable_evidence": sum(
            1 for r in records if r["evidence"]),
    })

    if not docs:
        for name in ("omission_rate", "pinning_bias", "access_concentration",
                     "synthesis_coverage", "score_clustering"):
            metrics["undefined"][name] = (
                "aes/shadow/ has no documents, so there is nothing to omit, "
                "pin, cluster or synthesise")
        findings.append({
            "class": "no narrative to measure",
            "detail": "aes/shadow/ is empty. These five metrics are undefined, "
                      "not zero.",
            "severity": "major",
        })
    else:
        counts = access_counts()
        index = (SHADOW / "INDEX.md")
        index_text = index.read_text() if index.exists() else ""

        # 1. Omission rate: documents the hot index does not carry.
        listed = {d["id"] for d in docs if d["id"] in index_text}
        omitted = [d["id"] for d in docs if d["id"] not in listed]
        metrics["defined"]["omission_rate"] = round(len(omitted) / len(docs), 4)
        if len(omitted) / len(docs) > NARRATIVE_MAX_OMISSION:
            findings.append({
                "class": "omission rate",
                "detail": f"{len(omitted)} of {len(docs)} documents are not in "
                          f"aes/shadow/INDEX.md: {omitted}",
                "severity": "minor",
            })

        # 1b. The index must agree with the scores it claims to rank by.
        #     `INDEX.md` says it is sorted by score. If it is not, the next
        #     session reads the wrong lesson first, and nothing downstream looks
        #     at the index again.
        order_in_index = [
            line.split("|")[2].strip()
            for line in index_text.splitlines()
            if line.startswith("|") and line.count("|") >= 3
            and "---" not in line and "score" not in line.lower()
        ]
        by_score = sorted(
            (d for d in docs if d["score"] is not None),
            key=lambda d: -d["score"])
        # In the index's order, not the score order. Building the list from the
        # scores and filtering by membership makes the comparison trivially true,
        # which is a gate that cannot fail wearing a gate's clothes.
        scores = {d["id"]: d["score"] for d in by_score}
        listed_ids = [i for i in order_in_index if i in scores]
        if len(listed_ids) > 1:
            sorted_ok = all(
                scores[a] >= scores[b] for a, b in zip(listed_ids, listed_ids[1:]))
            metrics["defined"]["index_matches_scores"] = sorted_ok
            if not sorted_ok:
                findings.append({
                    "class": "index drifts from its scores",
                    "detail": f"aes/shadow/INDEX.md claims to be sorted by "
                              f"score and lists {listed_ids}, which is not "
                              f"descending. The index is what the next session "
                              f"reads first.",
                    "severity": "minor",
                })

        # 2. Pinning bias: how much of the index is hand-placed rather than
        #    selected by score. A hand-written index is a curated one, which is
        #    not a fault -- but an index that claims to be sorted by score and
        #    is not is a different thing.
        pinned = sum(1 for d in docs if d["id"] in index_text and d["score"] is None)
        by_score = sum(
            1 for d in docs
            if d["id"] in index_text and d["score"] is not None)
        metrics["defined"]["pinned_entries"] = pinned
        metrics["defined"]["score_ranked_entries"] = by_score
        if listed and by_score == 0 and pinned:
            metrics["defined"]["pinning_bias"] = 1.0
            findings.append({
                "class": "pinning bias",
                "detail": "every indexed document is hand-placed and none "
                          "carries a score, so nothing about the index can be "
                          "checked against the thing it claims to rank by",
                "severity": "minor",
            })
        else:
            metrics["defined"]["pinning_bias"] = (
                round(pinned / (pinned + by_score), 4) if (pinned + by_score) else 0.0)

        # 3. Access concentration: Gini over how often each document was read.
        if not counts:
            metrics["undefined"]["access_concentration"] = (
                "aes/shadow/access.log does not exist, so how often anything "
                "was read is unknown rather than zero")
        else:
            known = [d for d in docs if d["id"] in counts]
            gini = _gini([float(counts[d["id"]]) for d in known])
            metrics["defined"]["access_concentration"] = round(gini, 4)
            metrics["defined"]["documents_never_read"] = [
                d["id"] for d in docs if counts.get(d["id"], 0) == 0]
            if gini > NARRATIVE_MAX_GINI and len(known) > 1:
                findings.append({
                    "class": "access concentration",
                    "detail": f"Gini {gini:.2f} over {len(known)} documents: a "
                              f"few lessons are read and the rest are not",
                    "severity": "minor",
                })

        # 4. Synthesis coverage: accessed documents that carry a rule someone can
        #    act on, rather than a narrative of what happened.
        accessed = [d for d in docs if counts.get(d["id"], 0) > 0]
        with_rule = [d for d in accessed if d["has_rule"]]
        if accessed:
            metrics["defined"]["synthesis_coverage"] = round(
                len(with_rule) / len(accessed), 4)
        else:
            # Not zero. Zero would say "nothing read carries a rule", which is a
            # claim about quality; the truth is that nothing was read, which is a
            # claim about the log.
            metrics["defined"].pop("synthesis_coverage", None)
            metrics["undefined"]["synthesis_coverage"] = (
                "no document appears in aes/shadow/access.log, so the share of "
                "what is read that carries a rule cannot be computed")

        # 5. Score clustering: are the scores spread or all the same?
        scored = sorted(d["score"] for d in docs if d["score"] is not None)
        metrics["defined"]["score_range"] = (
            [scored[0], scored[-1]] if scored else None)
        metrics["defined"]["distinct_scores"] = len(set(scored))
        if len(scored) > 2 and len(set(scored)) == 1:
            findings.append({
                "class": "score clustering",
                "detail": f"every document scores {scored[0]}, so the score "
                          f"carries no information and the index order is "
                          f"arbitrary",
                "severity": "minor",
            })

        incomplete = [d["id"] for d in docs if not d["complete"]]
        if incomplete:
            findings.append({
                "class": "incomplete shadow record",
                "detail": f"these documents are missing fields the metrics need: "
                          f"{incomplete}",
                "severity": "minor",
            })

    concentration = _gini([1.0 if r["evidence"] else 0.0 for r in records])
    metrics["defined"]["evidence_gini"] = round(concentration, 4)

    blockers = [f for f in findings if f["severity"] == "blocker"]
    return {
        "skill": "aes-narrative",
        "metrics": metrics,
        "findings": findings,
        "verdict": "FAIL" if blockers else ("WARN" if findings else "PASS"),
    }


# --- aes-project-manager ----------------------------------------------------

def project_manager(today: datetime.date) -> dict:
    """The adversarial gate: three verdicts, three different obligations.

    A gate that lets two records in a row agree is not a gate. This one refuses
    to answer anything without a verdict, and it reports the obligation each
    verdict carries, so "we checked and it was fine" is visibly different from
    "we could not check and here is what would".
    """
    records = decisions(today)
    known = tickets()
    rows = []
    breaches = []

    for record in records:
        verdict = record["verdict"]
        obligation = verdict_obligation(verdict)
        rows.append({
            "id": record["id_name"],
            "question": record["question"][:80],
            "verdict": verdict,
            "obligation": obligation,
            "evidence": record["evidence"],
            "age_days": record["age"],
            "retracts": record["retracts"],
            "ticket": record["ticket"],
            "ticket_exists": (record["ticket"] in known) if record["ticket"]
                             else None,
        })
        if verdict not in VERDICTS:
            breaches.append(f"{record['id_name']}: verdict {verdict!r} is not "
                            f"one of the three the gate allows")
        elif not record["evidence"] and verdict == "SUPORTADA":
            breaches.append(f"{record['id_name']}: SUPORTADA with nothing that "
                            f"can be re-run")
        if record["ticket"] and record["ticket"] not in known:
            breaches.append(f"{record['id_name']}: cites {record['ticket']}, "
                            f"which does not exist")

    distribution = {}
    for row in rows:
        distribution[row["verdict"]] = distribution.get(row["verdict"], 0) + 1

    return {
        "skill": "aes-project-manager",
        "records": rows,
        "verdict_distribution": distribution,
        "obligations": {k: v["obligation"] for k, v in VERDICTS.items()},
        "breaches": breaches,
        "verdict": "FAIL" if breaches else "PASS",
    }


# --- cli --------------------------------------------------------------------

SKILLS = {
    "debt": debt,
    "conflict": conflict,
    "narrative": narrative,
    "pm": project_manager,
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("skill", choices=[*SKILLS, "all"])
    parser.add_argument("--json", action="store_true", help="machine readable")
    parser.add_argument("--today", help="override today's date, YYYY-MM-DD")
    args = parser.parse_args()

    today = (_parse_date(args.today) if args.today
             else datetime.date.today())
    wanted = list(SKILLS) if args.skill == "all" else [args.skill]
    report = {name: SKILLS[name](today) for name in wanted}

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True, default=str))
        raise SystemExit(
            1 if any(r["verdict"] == "FAIL" for r in report.values()) else 0)

    exit_code = 0
    for name, result in report.items():
        print(f"\n=== {result['skill']}: {result['verdict']} ===")
        for key, value in result.items():
            if key in ("skill", "verdict"):
                continue
            if isinstance(value, dict):
                print(f"  {key}:")
                for k, v in value.items():
                    print(f"    {k}: {v}")
            elif isinstance(value, list) and value:
                print(f"  {key}:")
                for item in value:
                    print(f"    - {item}")
            else:
                print(f"  {key}: {value}")
        if result["verdict"] == "FAIL":
            exit_code = 1
    raise SystemExit(exit_code)


if __name__ == "__main__":
    main()
