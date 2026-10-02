# Synthesis — input and model, round 3

Scope `2e10061..a39801d`. Fourteen commits, forty files, four personas. Rubric
`templates/review-rubric.md`, hash
`7f375dc0acc2ccfa325259a81eeca0f628b3554fe3e71075dc4f13b9e584aba0`.

## Findings

| # | Finding | Persona | Severity | State |
|---|---|---|---|---|
| 1 | The render-priority tiebreak is asserted in prose, tested nowhere | Cínico | BLOCKER | open |
| 2 | Nothing in `make check` drives the game | Pragmático, Utilizador | BLOCKER | open |
| 3 | The transition loop breaks early, so the invariant is sampled over the wrong window | Cínico | MAJOR | open |
| 4 | `verticalVelocity` is unconstrained; D007 is a document, not a gate | Cínico | MAJOR | open |
| 5 | The shadow index can drift from the scores it claims to rank by | Purista | MAJOR | open |
| 6 | `ai_sprites.py`'s CLI is the largest untested surface in the repo | Purista | MAJOR | open |
| 7 | `gridPosition` is a float, so every movement test is 60x slower and less precise | Pragmático | MAJOR | open |
| 8 | T085's two-frame budget is a chosen number; measured is zero | Pragmático | MAJOR | open |
| 9 | The party still slides; one pose per direction | Utilizador | MAJOR | open |
| 10 | No key hint in the HUD; keyboard dies if focus moves | Utilizador | MAJOR | open |
| 11 | `blank frames` and `findable()` share one loop with a `break` | Cínico | MINOR | open |
| 12 | `aes-conflict` does not check a decision with no ticket | Cínico | MINOR | open |

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

## Recommendation

Do not close this round. Both blockers are about evidence rather than behaviour, and
evidence that nobody has checked is the thing this system exists to stop trusting.

Findings 3, 4, 5, 8 and 11 are each a small change with a measurable outcome, and
they are the ones that make the next round's blockers smaller rather than repeating
this one.
