# Review rubric — render fidelity and evidence

Pre-registered before any reviewer looked at the diff. A review against a rubric
written after the fact is a review of the author's preferences.

Scope: `da02f9e..eb92dca`, the rendering and evidence work of 2026-09-30.

Each finding must name exactly one of these, and must be falsifiable.

## R1 — Evidence

Every claim that something is fixed, drawn or measured is attached to a command
whose output is recorded and which a reader can run again. A screenshot is
evidence; "I checked and it looked right" is not. A measurement quoted from
memory, from an earlier build, or from a filter that silently excluded the case
is not evidence of that case.

## R2 — Test teeth

A test added or changed in this range fails when the fault it exists for is
present. A test that passed before and after a fix, on both sides of the fault,
is not a guard; it is decoration, and if it is the only thing standing between
the fault and the next release it is worse than nothing, because it reads as
protection.

## R3 — Path fidelity

A test exercises the path a player takes. A test that constructs the object it
measures, renders it through a helper the code under test also uses, or calls a
component's method directly rather than the engine's, measures its own
construction. It may still be a useful test; it is not evidence about the game.

## R4 — Measurement honesty

No claim is stated before it is understood. When a measurement turns out to
have been wrong — a filter that matched nothing, a reading of the wrong element,
a DOM query that cannot see the thing it names — the error is recorded with its
own date and the falsifier, and the original is left standing beside it. Erasing
it is not correction.

## R5 — Constraint

No asset, sprite, sound, level or other content comes from the original 1987
games. The games are original work built on a reusable engine; the artwork is
drawn by generators in `scripts/` and the audio is computed. A research copy of a
tape image may be read and measured; it is never a source of shipped bytes.

## R6 — Blast radius

Changes are surgical. A change that fixes one rendering fault and also rewrites
adjacent code, renames things it does not need to, or reformats what it did not
touch is a finding, whatever its merits, because the next person cannot tell
what was deliberate.

## R7 — Data and renderer are separate

The renderer does not compensate for bad data, and bad data is not papered over
in the renderer. A manifest that declares more frames than a sheet paints, a
generator that writes to the wrong tree, a row that does not exist: each is a
data fault, it is fixed where it is generated, and it is caught by a check that
looks at content rather than at metadata.

## R8 — Process

Gates are run and their real output reported. The board and the decision records
match the repository. Nothing is pushed that a standing rule says needs human
approval, and nothing is landed with a failing gate.

## Verdicts

Accepted findings become tickets with a closure condition. A finding whose
closure condition cannot be executed is rejected at intake, not at the end.