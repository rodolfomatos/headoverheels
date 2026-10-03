#!/usr/bin/env python3
"""Staleness gate for the shadow documents.

The skill's own `gmif-staleness-check.sh` iterates `aes/shadow/SD-GMIF-*.md`.
This project's six documents are `SD-CI-*` and `SD-META-*`, so the glob matched
zero files and it printed "No STALE GMIF shadows" -- a clean bill for a gate that
had examined nothing. That is recorded as claim C-002 in
`aes/graph/tooling-integrity.yaml`.

Two consequences shape this replacement:

  * it looks at every shadow document that carries the fields, not at a name
    pattern, and
  * examining zero documents is a FAILURE, not a pass. A gate that cannot
    distinguish "nothing is stale" from "I read nothing" cannot be trusted when
    it matters, which is the failure this project has already produced six times.

A document can acknowledge its own staleness with `staleness_acknowledged: true`
and a `staleness_reason:`. That is an explicit decision with a name on it, not a
silent skip.
"""

from __future__ import annotations

import datetime as dt
import pathlib
import re
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
SHADOW_DIR = REPO_ROOT / "aes" / "shadow"

# A claim nobody has re-measured in this long is not knowledge any more, it is a
# memory of having been right once.
FRESH_DAYS = 30
AGING_DAYS = 90

FIELD = re.compile(
    r"^(epistemic_state|last_verified|access_count|staleness_acknowledged|"
    r"staleness_reason|score)\s*:\s*(.+?)\s*$",
    re.MULTILINE,
)
DATE = re.compile(r"(\d{4}-\d{2}-\d{2})")


def parse_date(value: str) -> dt.date | None:
    found = DATE.search(value)
    return dt.date.fromisoformat(found.group(1)) if found else None


def read_document(path: pathlib.Path) -> dict:
    text = path.read_text(encoding="utf-8")
    fields = {m.group(1): m.group(2) for m in FIELD.finditer(text)}
    return {
        "path": path,
        "name": path.name,
        "epistemic_state": fields.get("epistemic_state"),
        "last_verified": parse_date(fields.get("last_verified", "")),
        "access_count": fields.get("access_count"),
        "acknowledged": fields.get("staleness_acknowledged", "").lower()
        == "true",
        "reason": fields.get("staleness_reason"),
    }


def candidates(shadow_dir: pathlib.Path = SHADOW_DIR) -> list[pathlib.Path]:
    if not shadow_dir.is_dir():
        return []
    return sorted(
        p for p in shadow_dir.glob("*.md")
        if p.name != "INDEX.md" and not p.name.startswith("README")
    )


def audit(today: dt.date,
          shadow_dir: pathlib.Path = SHADOW_DIR) -> dict:
    paths = candidates(shadow_dir)
    rows = [read_document(p) for p in paths]

    # The vacuity guard. Without this, an empty directory is indistinguishable
    # from a clean bill of health, and the gate reports success for having done
    # no work -- which is what the skill's version did.
    if not rows:
        return {
            "verdict": "FAIL",
            "reason": f"no shadow documents under {shadow_dir}",
            "examined": 0,
            "rows": [],
        }

    stale, aging, fresh, acknowledged, malformed = [], [], [], [], []

    for row in rows:
        missing = [f for f in ("epistemic_state", "last_verified")
                   if not row[f]]
        if missing:
            malformed.append((row["name"], f"missing {', '.join(missing)}"))
            continue
        age = (today - row["last_verified"]).days
        row["age_days"] = age
        if row["acknowledged"]:
            if not row["reason"]:
                malformed.append(
                    (row["name"],
                     "staleness_acknowledged with no staleness_reason"))
                continue
            acknowledged.append(row)
        elif age > AGING_DAYS:
            stale.append(row)
        elif age > FRESH_DAYS:
            aging.append(row)
        else:
            fresh.append(row)

    return {
        "verdict": "FAIL" if (stale or malformed) else "PASS",
        "examined": len(rows),
        "fresh": fresh,
        "aging": aging,
        "stale": stale,
        "acknowledged": acknowledged,
        "malformed": malformed,
        "rows": rows,
    }


def report(result: dict, today: dt.date) -> None:
    label = lambda d: f"fresh<={FRESH_DAYS}d aging<={AGING_DAYS}d stale>{AGING_DAYS}d"
    print(f"staleness gate -- {label(None)}")
    if result["verdict"] == "FAIL" and not result["examined"]:
        print(f"[!!] FAIL -- {result['reason']}")
        print("     Nothing was examined. That is not a pass.")
        return

    print(f"     examined {result['examined']} shadow document(s)")
    for row in result.get("fresh", []):
        print(f"[ok] {row['name']}: {row['age_days']}d, {row['epistemic_state']}")
    for row in result.get("aging", []):
        print(f"[~] {row['name']}: {row['age_days']}d, {row['epistemic_state']}"
              " -- re-verify before relying on it")
    for row in result.get("acknowledged", []):
        print(f"[ok] {row['name']}: {row['age_days']}d, acknowledged -- "
              f"{row['reason']}")
    for name, why in result.get("malformed", []):
        print(f"[!!] FAIL -- {name}: {why}")
    for row in result.get("stale", []):
        print(f"[!!] FAIL -- {row['name']}: {row['age_days']}d since last "
              f"verified ({row['last_verified']}). Re-measure it, or record "
              f"staleness_acknowledged with a reason.")


def main() -> int:
    today = dt.date.today()
    result = audit(today)
    report(result, today)
    return 0 if result["verdict"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())