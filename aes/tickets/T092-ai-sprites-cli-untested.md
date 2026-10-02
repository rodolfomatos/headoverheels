---
id: T092
status: done
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

## Closed: the CLI had never run, and three things in it had never worked

Ten tests run the command line in a throwaway tree. Two of them are the rule the
pipeline exists for, and both passed immediately: a run writes into `build/ai/`
and never touches `assets/sprites/`, and `--lock` refuses to replace an accepted
sprite.

The other eight found three bugs in code that had never executed.

**`--accept` could not work at all.** The flag is documented as taking a run
directory, and a run directory is named `<timestamp>-<id>`, but the code matched
the flag against a manifest id exactly. No run directory has ever been a manifest
id, so the one step that moves a candidate into the project never ran. It accepts
either form now and says both in the message when neither matches.

**`fit()` unpacked `runtime_size` and got its keys.** The manifest stores
`{width, height}`; unpacking a map yields `('width', 'height')`. Every test of
`fit` used a list of two ints, which the manifest has never contained. **The
function this pipeline is named after had never been run against a real entry**,
and the fixture agreed with the bug rather than with reality. The fixture now uses
the manifest's own shape, and one test asserts the shape, so a future change to it
breaks a test instead of silently making the fixtures fictional.

**`finish()` returned a path and the caller saved it as an image.** `image.save()`
on a `pathlib.Path`. The third fault on the same code path, and none of them would
have been found by reading it.

## What this says about the other 27 tests

They cover arithmetic, and arithmetic was correct. Every fault was at the seam
between the script and the real project: a manifest key that is `assets` and not
`sprites`, a manifest value that is a map and not a pair, a flag whose documented
argument is not the one the code reads. **Twenty-seven tests on pure functions
passed while the thing that used them had never worked.**

That is not an argument for fewer unit tests. It is the argument T091 makes from
the other end: a test that cannot reach the real thing it is about will pass while
the real thing is broken.
