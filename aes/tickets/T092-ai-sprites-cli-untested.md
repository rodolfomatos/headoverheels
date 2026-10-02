---
id: T092
status: open
severity: major
found_by: aes-peer-review/2026-10-02-input-and-model (purista)
---

# T092 — the art pipeline's CLI is the largest untested surface in the repo

## Statement

`scripts/ai_sprites.py` has twenty-seven tests on the deterministic half —
`cut_out`, `fit`, `fit_palette`, the prompt builders, the workflow substitution,
and every one of them is a pure function. The CLI itself is exercised by nothing.
It was run by hand once, during the commit that added it, and that run was not
kept.

## What that left unproven

- The manifest key. It was `sprites` in the draft and is `assets` in the file, and
  every test broke at once when it was found. Nothing would catch it again.
- The spec lookup. A spec that stops existing degrades to a prompt with no
  description, silently, and the prompt is then written to a file a person may
  act on.
- The candidate-only guarantee. That nothing writes into `assets/sprites/` is the
  rule the whole pipeline exists for, and it is enforced by a directory choice
  rather than by a check.
- The lock. `--lock` refuses to replace an accepted sprite, and the refusal is
  the only thing standing between a regeneration and signed-off art.

## What closing it needs

Run the CLI in a temporary tree and assert four things: a run directory appears
with a prompt and a control; `--accept` with no `raw.png` refuses and says so; a
locked asset is not replaced; and nothing under `assets/sprites/` changed. The last
one is the rule, and it is worth a test on its own.
