#!/usr/bin/env python3
"""A GMIF gate with teeth.

The skill ships `gmif-check.sh`, which builds an SMT2 file per island and asks Z3
whether the claims in it can all be true. On this project's first real island it
reported SAT, and Z3 was right that the island was satisfiable and wrong about
why: the file it produced is not valid SMT-LIB at all.

    (assert (! every_entity_visible :named every_entity_visible))

Z3 rejects that with `invalid named expression, declaration already defined with
this name`. The script redirects stderr into the result file, greps for `sat` or
`unsat`, finds neither, and falls through to SAT. So the gate reported a clean
bill for an island it never actually checked, and the island in question asserts
both `every_entity_visible` and `not every_entity_visible`.

A gate that cannot fail is worse than no gate, because it manufactures green and
is trusted precisely when nobody is looking. Three things are done differently
here, and each one closes a way this can pass without having checked anything:

**Any output that is not exactly `sat` or `unsat` is a failure.** Z3 printing an
error is not a pass. There is no default branch that guesses.

**Named assertions get a prefix that cannot collide with a declaration.** The
skill reuses the claim id as the assertion name, which is the same symbol space,
so every island with more than one node is malformed.

**The unsat core is printed, and it is the point.** A gate that says "unsat"
without saying which claims conflicted has told you there is a problem and given
you no way to start on it.

Usage:
    python3 scripts/gmif_check.py                 # every island
    python3 scripts/gmif_check.py --verbose       # the SMT2, and Z3's stderr
"""

from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import subprocess
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
GRAPH = ROOT / "aes" / "graph"
VERIFICATION = ROOT / "aes" / "verification" / "gmif"
CACHE = ROOT / ".aes" / "cache" / "gmif"

Z3_TIMEOUT = 30
MIN_VALIDATION_CONFIDENCE = 0.85
MIN_EXTRACTION_CONFIDENCE = 0.85
LIVE_STATES = ("INFERRED", "SUPPORTED")
CONNECTORS = ("implies", "and", "or", "xor", "nand")


def have_z3() -> bool:
    return bool(shutil.which("z3"))


def node_state(node: dict) -> str:
    """The epistemic state, under either name the ecosystem has used.

    `aes-epistemics`'s SKILL.md documents `epistemic_state`. Its own
    `gmif-check.sh` reads `state`, and defaults to ASSUMED when it is missing, so
    an island written to the documentation is silently filtered out and the gate
    reports "no logical claims to validate" and passes. Accepting both is what
    makes an island written to the docs actually get checked.
    """
    return node.get("state") or node.get("epistemic_state") or "ASSUMED"


def is_validated(node: dict) -> tuple[bool, str]:
    if node.get("validation_type") != "logical":
        return False, f"validation_type is {node.get('validation_type')!r}"
    for field, floor in (("validation_confidence", MIN_VALIDATION_CONFIDENCE),
                         ("extraction_confidence", MIN_EXTRACTION_CONFIDENCE)):
        value = node.get(field, 0.0)
        if value <= floor:
            return False, f"{field} is {value}, needs > {floor}"
    # A falsified claim is history, and history belongs in the graph. The
    # solver is told it is false rather than being left out; skipping it
    # would let an island full of refuted gates pass unchecked.
    if node_state(node) not in LIVE_STATES and node_state(node) != "FALSIFIED":
        return False, (f"state is {node_state(node)!r}, needs one of "
                      f"{LIVE_STATES} or FALSIFIED")
    if not node.get("logical_form"):
        return False, "no logical_form"
    return True, ""


class UnsupportedForm(ValueError):
    """A logical_form this gate will not guess at."""


# `=>` first: an identifier pattern would happily match the `=` on its own and
# leave the `>` unparsed, so `a => b` was not an implication at all.
# Claim ids are `C-001`, so the hyphen has to be in the token. It was not, and
# `findall` skips characters it cannot match rather than failing: the parser read
# "C-001" as the token "C", dropped "-001", and accepted it. A parser that loses
# input and says nothing is worse than one that refuses.
TOKEN = re.compile(r"=>|[()]|[A-Za-z_][A-Za-z0-9_-]*")


def symbol(node_id: str) -> str:
    """The SMT-LIB constant for a claim id.

    The schema documents `id: C-001`, with a hyphen, and SMT-LIB has no hyphen in
    a symbol. Writing `(declare-const C-001 Bool)` produces a file Z3 rejects, so
    an island written to the documentation could not be validated at all -- and
    the skill's own `gmif-check.sh` skips such a node silently, which is how a
    schema-conforming island ends up validating nothing.

    So the id stays as documented and the solver gets a derived name.
    """
    return re.sub(r"[^A-Za-z0-9_]", "_", str(node_id))


def s_expr(form: str, declared: set[str]) -> str:
    """Turn a node's logical_form into SMT-LIB, or refuse to.

    The grammar is deliberately tiny: an atom, `not <atom>`, or exactly one
    binary operator over two atoms. Anything else raises, and the island fails.

    An earlier version rewrote operators with repeated regexes, which turned
    `a and b and c` into `(and a b) and c` -- not a well-formed SMT expression --
    and would have handed it to Z3 as if it were. A gate that quietly emits
    something it did not check is the exact failure this whole file exists to
    prevent, so the parser refuses instead of guessing, and `--all` reports which
    claims it would not accept.

    Parenthesised grouping is accepted, because writing `(and a b)` by hand is
    the natural thing to do and rejecting it would be pedantry rather than rigour.
    """
    source = str(form).strip()
    tokens = TOKEN.findall(source)
    if not tokens:
        raise UnsupportedForm("empty logical_form")

    # Every character of the form has to end up in a token. `findall` skips what
    # it cannot match, so a form with an unexpected character used to parse
    # cleanly and quietly lose the part it did not understand.
    if "".join(tokens) != re.sub(r"\s+", "", source):
        lost = re.sub(r"\s+", "", source).replace("".join(tokens), "", 1)
        raise UnsupportedForm(
            f"{form!r} contains {lost!r}, which is not an operator, a "
            f"parenthesis or a claim id; the parser would have dropped it")

    pos = 0

    def peek():
        return tokens[pos] if pos < len(tokens) else None

    def take():
        nonlocal pos
        token = tokens[pos]
        pos += 1
        return token

    operators = ("and", "or", "=>", "xor", "nand", "=")

    def parse_atom():
        token = peek()
        if token == "(":
            take()
            # `(and a b)` writes the operator first, which is what people type
            # when they are thinking in SMT rather than in infix.
            if peek() in operators:
                operator = take()
                left, right = parse_not(), parse_not()
                if take() != ")":
                    raise UnsupportedForm(
                        f"unbalanced parenthesis in {form!r}")
                return f"({operator} {left} {right})"
            inner = parse_expr()
            if take() != ")":
                raise UnsupportedForm(f"unbalanced parenthesis in {form!r}")
            return inner
        if token is None or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_-]*", token):
            raise UnsupportedForm(f"unexpected token {token!r} in {form!r}")
        take()
        return token

    def parse_not():
        token = peek()
        if token == "not":
            take()
            return f"(not {parse_atom()})"
        return parse_atom()

    def parse_expr():
        left = parse_not()
        operator = peek()
        if operator in operators:
            take()
            right = parse_not()
            return f"({operator} {left} {right})"
        return left

    result = parse_expr()
    if pos != len(tokens):
        raise UnsupportedForm(
            f"{form!r} has more than one operator per claim; write the "
            f"intermediate claim as its own node so the solver can name it")
    return result


def build_smt2(island: dict) -> tuple[str, list[dict]]:
    """The SMT2 for one island, and the nodes that went into it."""
    skipped = []
    valid = []
    for node in island.get("nodes", []):
        ok, why = is_validated(node)
        if ok:
            valid.append(node)
        else:
            skipped.append({"id": node.get("id"), "reason": why})

    declared = {str(n["id"]) for n in valid}
    # Claim ids as they appear in a logical_form, and the constants they stand for.
    to_symbol = {str(n["id"]): symbol(n["id"]) for n in valid}
    lines = ["(set-logic QF_UF)", "(set-option :produce-unsat-cores true)"]

    for name in sorted(to_symbol):
        lines.append(f"(declare-const {to_symbol[name]} Bool)")

    emitted = []
    for node in valid:
        named = f"a_{symbol(node['id'])}"
        try:
            body = s_expr(node["logical_form"], declared)
        except UnsupportedForm as error:
            # Dropped from the solver's input and reported, never passed through
            # as if it had been checked.
            skipped.append({"id": node["id"],
                            "reason": f"unsupported logical_form: {error}"})
            continue
        for claim_id, constant in sorted(
                to_symbol.items(), key=lambda kv: -len(kv[0])):
            body = re.sub(rf"\b{re.escape(claim_id)}\b", constant, body)
        if node_state(node) == "FALSIFIED":
            body = f"(not {body})"
        lines.append(f"(assert (! {body} :named {named}))")
        emitted.append(node["id"])
    declared = set(emitted)

    seen = set()
    for edge in island.get("edges", []):
        kind = edge.get("type", "")
        sources = edge.get("from", [])
        if isinstance(sources, str):
            sources = [sources]
        target = edge.get("to", "")
        if kind not in CONNECTORS or not sources or target not in declared:
            continue
        if not all(source in declared for source in sources):
            continue
        if target not in declared:
            continue
        premise = (sources[0] if len(sources) == 1
                   else f"(and {' '.join(sources)})")
        key = (kind, tuple(sources), target)
        if key in seen:
            continue
        seen.add(key)
        for claim_id, constant in sorted(
                to_symbol.items(), key=lambda kv: -len(kv[0])):
            premise = re.sub(rf"\b{re.escape(claim_id)}\b", constant, premise)
        premise = premise.replace(target, to_symbol[target])
        named = f"e_{'_'.join(symbol(x) for x in sources)}_to_{symbol(target)}"
        if kind == "implies":
            lines.append(f"(assert (! (=> {premise} "
                         f"{to_symbol[target]}) :named {named}))")
        elif kind == "and":
            lines.append(
                f"(assert (! (= {to_symbol[target]} {premise}) :named {named}))")

    # `get-unsat-core` is only meaningful after an unsat answer, and asking for
    # it after sat is an error Z3 reports on stderr -- which this gate treats as a
    # failure. The core is fetched in a second run, once there is a core.
    lines += ["(check-sat)", "(exit)"]
    return "\n".join(lines) + "\n", skipped


def check(island_path: pathlib.Path, verbose: bool = False) -> dict:
    island = yaml.safe_load(island_path.read_text()) or {}
    name = island_path.stem
    smt2, skipped = build_smt2(island)
    asserted = smt2.count("(assert")

    CACHE.mkdir(parents=True, exist_ok=True)
    VERIFICATION.mkdir(parents=True, exist_ok=True)
    smt_file = CACHE / f"{name}.smt2"
    smt_file.write_text(smt2)

    uncheckable = [s for s in skipped
                   if s["reason"].startswith("unsupported logical_form")]
    if uncheckable:
        return {
            "island": name,
            "result": "PARTIAL",
            "verdict": "FAIL",
            "detail": f"{len(uncheckable)} claim(s) could not be put to the "
                      f"solver, so this island was not fully checked: "
                      f"{[s['id'] for s in uncheckable]}. Partly checked is "
                      f"not checked.",
            "skipped": skipped,
        }

    if asserted == 0:
        return {
            "island": name,
            "result": "EMPTY",
            "verdict": "WARN",
            "detail": "no node passed the validation filter, so there was "
                      "nothing to ask Z3",
            "skipped": skipped,
        }

    try:
        proc = subprocess.run(
            ["z3", "-smt2", f"-T:{Z3_TIMEOUT}", str(smt_file)],
            capture_output=True, text=True, timeout=Z3_TIMEOUT + 10)
    except subprocess.TimeoutExpired:
        return {"island": name, "result": "TIMEOUT", "verdict": "FAIL",
                "detail": f"Z3 did not answer in {Z3_TIMEOUT}s, so the claims "
                          f"are still unknown. Unknown is not a pass.",
                "skipped": skipped}

    stdout = proc.stdout.strip()
    stderr = proc.stderr.strip()

    if proc.returncode != 0 or stderr:
        # This is the branch the skill does not have. Z3 complaining is not a
        # result; treating it as one is how a malformed island became a clean
        # bill here.
        return {
            "island": name, "result": "ERROR", "verdict": "FAIL",
            "detail": f"Z3 exited {proc.returncode}: {stderr or stdout}",
            "skipped": skipped,
        }

    if stdout == "unsat":
        core = _core(_ask_for_core(smt_file))
        return {
            "island": name, "result": "UNSAT", "verdict": "FAIL",
            "detail": "these claims cannot all be true",
            "core": core,
            "skipped": skipped,
        }
    if stdout == "sat":
        return {"island": name, "result": "SAT", "verdict": "PASS",
                "detail": "the claims in this island are mutually consistent",
                "skipped": skipped}

    return {
        "island": name, "result": "UNKNOWN", "verdict": "FAIL",
        "detail": f"Z3 said {stdout!r}, which is neither sat nor unsat. An "
                  f"answer this gate cannot read is not a pass.",
        "skipped": skipped,
    }


def _ask_for_core(smt_file: pathlib.Path) -> str:
    """Ask Z3 again for the core, with a file that asks for it.

    Z3 reads commands from the file, so the `get-unsat-core` has to be in it.
    Passing it on stdin does not work: the file already ended in `(exit)`.
    """
    with_core = smt_file.with_name(smt_file.stem + "_core.smt2")
    body = smt_file.read_text().replace("(check-sat)", "(check-sat)\n(get-unsat-core)", 1)
    with_core.write_text(body)
    proc = subprocess.run(
        ["z3", "-smt2", f"-T:{Z3_TIMEOUT}", str(with_core)],
        capture_output=True, text=True, timeout=Z3_TIMEOUT + 10)
    return proc.stdout


def _core(stdout: str) -> list[str]:
    return [line.strip() for line in stdout.splitlines()
            if line.strip().startswith("(") and line.strip() != "(exit)"]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    if not have_z3():
        sys.exit("z3 is not installed. Unknown is not a pass.")

    if not GRAPH.exists() or not list(GRAPH.glob("*.yaml")):
        sys.exit(f"no islands in {GRAPH}: there is nothing to check, which is "
                 f"not the same as there being nothing wrong")

    rows = []
    for path in sorted(GRAPH.glob("*.yaml")):
        row = check(path, verbose=args.verbose)
        rows.append(row)
        marker = {"PASS": "ok", "WARN": "--", "FAIL": "!!"}[row["verdict"]]
        print(f"[{marker}] {row['island']}: {row['result']} -- {row['detail']}")
        for skipped in row.get("skipped", []):
            print(f"       skipped {skipped['id']}: {skipped['reason']}")
        if row.get("core"):
            print(f"       unsat core: {', '.join(row['core'])}")
        if args.verbose:
            print((GRAPH / f"{row['island']}.yaml").read_text())

    failed = [r for r in rows if r["verdict"] == "FAIL"]
    print(f"\n{len(rows)} island(s): "
          f"{len(rows) - len(failed)} ok, {len(failed)} failed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
