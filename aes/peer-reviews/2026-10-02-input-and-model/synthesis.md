# Synthesis — input and model, round 3

Scope `2e10061..a39801d`. Fourteen commits, forty files, four personas. Rubric
`templates/review-rubric.md`, hash
`7f375dc0acc2ccfa325259a81eeca0f628b3554fe3e71075dc4f13b9e584aba0`.

## Findings

| # | Finding | Persona | Severity | State |
|---|---|---|---|---|
| 1 | The render-priority tiebreak is asserted in prose, tested nowhere | Cínico | BLOCKER | **closed** `5c61b7a` |
| 2 | Nothing in `make check` drives the game | Pragmático, Utilizador | BLOCKER | open |
| 3 | The transition loop breaks early, so the invariant is sampled over the wrong window | Cínico | MAJOR | **closed** `5c61b7a` |
| 4 | `verticalVelocity` is unconstrained; D007 is a document, not a gate | Cínico | MAJOR | **closed** `5c61b7a` |
| 5 | The shadow index can drift from the scores it claims to rank by | Purista | MAJOR | **closed** `5c61b7a` |
| 6 | `ai_sprites.py`'s CLI is the largest untested surface in the repo | Purista | MAJOR | **open** T092 |
| 7 | `gridPosition` is a float, so every movement test is 60x slower and less precise | Pragmático | MAJOR | **open** T093 |
| 8 | T085's two-frame budget is a chosen number; measured is zero | Pragmático | MAJOR | **closed** `5c61b7a` |
| 9 | The party still slides; one pose per direction | Utilizador | MAJOR | **open**, art debt |
| 10 | No key hint in the HUD; keyboard dies if focus moves | Utilizador | MAJOR | **open** T094 |
| 11 | `blank frames` and `findable()` share one loop with a `break` | Cínico | MINOR | **closed** `5c61b7a` |
| 12 | `aes-conflict` does not check a decision with no ticket | Cínico | MINOR | **closed** |

## The two blockers are the same claim

Neither reviewer could find evidence that a door works. One reached it by asking
whether the gate drives the game — and `make check` does not call
`make verify-browser`. The other reached it by pressing keys and watching a party
move, which is not a door.

That is the same shape as round 2's pattern, one level up. Round 2's finding was
that measurements could not distinguish the cases they existed to separate. Round
3's is that **no measurement here observes the thing the project exists to make**.

Every finding in both rounds that mattered was a hole in the evidence, not a
mistake in the code. The code has been wrong — a half-turned joystick, gravity on
the tile plane, a party detached from every tree — and each time the *measurement*
was what let it through.

## What the reviewers could not attack

`scripts/gmif_check.py`. The Cínico tried and could not make it report success
without having asked Z3. It fails on anything that is not a clean sat or unsat, and
19 tests cover each route to a false pass. That is the first instrument in this
project a reviewer has failed to find a soft edge in, and it is worth recording as
such rather than leaving it implied.

## What closing six of them cost

Two of the six fixes were themselves gates that could not fail, and both were
caught by their own tests rather than by a reviewer:

- The check that `INDEX.md` is sorted by score built its comparison list from the
  scores and filtered it by membership in the index, so the result was true
  whatever the index said. It now preserves the index's own order.
- The sample of a Knight Lore test failed once during this work, was not
  reproduced in three subsequent runs, and its name was not captured. It is still
  an uninvestigated flake and is recorded as such rather than as a pass.

The recurring failure mode of this project is a comparison that cannot come out
the wrong way. It has now been found in a render guard, in a satisfiability gate,
in an aggregate bounding box, in a measurement of a room the test had rearranged,
and in a fix for a finding about a gate that could not fail.

## Recommendation

Do not close this round. Both blockers are about evidence rather than behaviour, and
evidence that nobody has checked is the thing this system exists to stop trusting.

Findings 3, 4, 5, 8 and 11 are each a small change with a measurable outcome, and
they are the ones that make the next round's blockers smaller rather than repeating
this one.
