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
    if ACCESS_LOG.exists():
        for line in ACCESS_LOG.read_text().splitlines():
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


def narrative(today: datetime.date) -> dict:
    """Five ways the story the project tells can differ from what it did.

    Most of these cannot be computed here, and the reason is reported instead of
    a number. There is no shadow directory: no shadow documents, no access log,
    no scores. An omission rate of zero would mean the project had a perfect
    knowledge base. It has no knowledge base at all.
    """
    records = decisions(today)
    findings = []
    metrics: dict = {}

    if not SHADOW.exists():
        undefined = [
            "omission_rate", "pinning_bias", "access_concentration",
            "synthesis_coverage", "score_clustering",
        ]
        metrics["defined"] = {}
        metrics["undefined"] = {
            name: "aes/shadow/ does not exist: there are no shadow documents "
                   "to omit, pin, cluster or synthesise"
            for name in undefined
        }
        findings.append({
            "class": "no narrative to measure",
            "detail":
                "aes/shadow/ is absent, so all five narrative metrics are "
                "undefined. They are not zero: a zero omission rate would be "
                "read as a complete index, and there is no index.",
            "severity": "major",
        })
    else:
        docs = list(SHADOW.glob("*.md"))
        metrics["defined"] = {"shadow_documents": len(docs)}
        metrics["undefined"] = {}

    # Of what does exist: is the record set load-bearing, or is it decoration?
    load_bearing = [r for r in records if r["evidence"]]
    metrics["defined"]["decisions"] = len(records)
    metrics["defined"]["decisions_with_re_runnable_evidence"] = len(load_bearing)

    concentration = _gini([1.0 if r["evidence"] else 0.0 for r in records])
    metrics["defined"]["evidence_gini"] = round(concentration, 4)
    if concentration > NARRATIVE_MAX_GINI and records:
        findings.append({
            "class": "evidence concentration",
            "detail": f"Gini {concentration:.2f} over decisions with "
                      f"re-runnable evidence: the record set is not evenly "
                      f"load-bearing",
            "severity": "minor",
        })

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
