# Persona 2 — Purista

## MAJOR 1 — the shadow documents are the only thing here with no gate

Six shadow documents, six scores, and every number in them is a number I have to
take on trust. `room_render_test` prints them; nothing asserts them. That is fine
for a record and not fine for the hot index, because `aes/shadow/INDEX.md` orders by
score and a wrong score reorders what the next session reads first.

The cheap gate: `aes-narrative` already computes `score_clustering`. It should also
check that `INDEX.md`'s order matches descending score, so the index cannot drift
from the thing it claims to rank by.

## MAJOR 2 — `ai_sprites.py` is the largest untested surface in the repo

Twenty-seven tests on the deterministic half, and the CLI itself exercised by
nothing. It reads the manifest, resolves a spec, builds a prompt and writes files.
The manifest key changing from `sprites` to `assets` broke every test at once when I
wrote it; a spec that stops existing degrades to a prompt with no description,
silently.

## MINOR 3 — D007's consequence list is a specification written as prose

"Consequences, all of them obligations rather than conveniences." A consequence that
is not asserted will be undone by the next person who does not read the decision,
and the cost of undoing it is exactly the bug the decision was made to close.

## What I approve

Deleting the aggregate placement guard rather than demoting it. Keeping a check that
cannot fail under a name that suggests it holds a line is how this project lost a
day of browser-side geometry work in the first place.
