---
id: SD-META-001
cluster: meta
title: A gate that cannot fail is worse than no gate
score: 1.0
epistemic_state: SUPPORTED
last_verified: 2026-10-02
access_count: 6
provenance: 13078b9, 5447864
---

# SD-META-001

`aes-epistemics`'s `gmif-check.sh` reported SAT on this project's first real
island. Z3 had never been asked.

The SMT2 it generates writes `(assert (! c :named c))` — the assertion name and the
declared constant share a symbol, so every file is a redeclaration. Z3 rejects
every one with `invalid named expression, declaration already defined with this
name`. The script redirects stderr into the result file, greps for `sat` or
`unsat`, finds neither, and falls through to SAT.

Five of the six AES skills shipped as `SKILL.md` and nothing else: no thresholds,
no scripts, no way to fail. A phase that passed them proved nothing.

## The three rules that came out of it

**Any output that is not exactly `sat` or `unsat` is a failure.** Z3 printing an
error is not a result. A default branch that guesses is how a malformed island
becomes a clean bill.

**A named assertion must not share a symbol with a declaration.**

**An island with a claim the solver could not read reports PARTIAL and fails.**
Partly checked is not checked.

## The rule

Every threshold is a named constant in code, not a literal in a comparison, and
every metric names the input it needs. An absent input is reported as absent and
never as zero: this project has no knowledge base, and an omission rate of 0%
would score an empty one as perfect.
