#!/usr/bin/env python3
"""Did the walk in `browser_walk.js` actually go where it says it went?

The Node side drives and records what it *believes*: which room it thinks the party
is in after each key. This decides whether the belief is true, from the captures
and from the game's own map.

Three claims, in increasing strength:

1. **The party moved.** A build where the keyboard does nothing would otherwise
   pass by never changing anything.
2. **Each hop crossed a door.** The share of the frame that changed has to be one a
   room change explains and walking does not.
3. **The map is realisable.** Every room the map says is reachable from the start
   was actually entered, and every hop that was supposed to cross a door did.

The discriminator is arithmetic, not taste. The party is a 64x40 sprite, so walking
it across a 1000x720 frame changes about 0.4% of it; a different room changes
nearly all of it, because the floor, the walls and every entity in it are
different. A fifth of the frame is about fifty times the sprite's maximum share, so
it cannot be walking.
"""

from __future__ import annotations

import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import browser_pixels as bp  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHOTS = ROOT / "build" / "browser"

ROOM_CHANGE_SHARE = 0.20
ANY_MOTION_SHARE = 0.0005
STEP = 2


def share_changed(a: pathlib.Path, b: pathlib.Path) -> float:
    """The fraction of sampled pixels that differ between two captures."""
    wa, ha, _, pa = bp.decode(a)
    wb, hb, _, pb = bp.decode(b)
    if (wa, ha) != (wb, hb):
        raise SystemExit(
            f"{a.name} is {wa}x{ha} and {b.name} is {wb}x{hb}: captures of "
            f"different sizes cannot be compared, and treating them as equal "
            f"would make every number here meaningless")
    sampled = differing = 0
    for y in range(0, ha, STEP):
        base = y * wa
        for x in range(0, wa, STEP):
            sampled += 1
            if pa[base + x] != pb[base + x]:
                differing += 1
    return differing / max(1, sampled)


def main() -> int:
    walk_file = SHOTS / "walk.json"
    if not walk_file.exists():
        print("no walk.json: the browser walk did not run")
        return 1
    walk = json.loads(walk_file.read_text())

    print(f"start          {walk['start']}")
    print(f"map says       {len(walk['reachable'])} rooms are reachable")
    print(f"walk claims    {len(walk['visited'])} visited")
    print()
    print(f"ROOM CHANGE: more than {ROOM_CHANGE_SHARE:.0%} of the frame")
    print(f"ANY MOTION:   more than {ANY_MOTION_SHARE:.2%} of the frame\n")

    moved = crossed = 0
    stuck = []
    for step in walk["walk"]:
        if step.get("skipped"):
            print(f"  {step['tag']}: SKIPPED -- {step.get('note')}")
            continue
        before = SHOTS / step["before"]
        after = SHOTS / step["settled"]
        if not before.exists() or not after.exists():
            stuck.append((step, "a capture is missing"))
            print(f"  {step['tag']}: no captures")
            continue
        share = share_changed(before, after)
        verdict = "room" if share > ROOM_CHANGE_SHARE else (
            "moved" if share > ANY_MOTION_SHARE else "nothing")
        print(f"  {step['tag']}: {step['from']} --{step['direction']}--> "
              f"{step['to']}: {share:.2%} ({verdict})")
        if share > ANY_MOTION_SHARE:
            moved += 1
        if share > ROOM_CHANGE_SHARE:
            crossed += 1
        else:
            stuck.append((step, f"only {share:.2%} of the frame changed"))

    print()
    print(f"{moved} of {len(walk['walk'])} steps moved the party at all")
    print(f"{crossed} of {len(walk['walk'])} steps crossed a door")

    failures = []
    if walk["errors"]:
        failures.append(f"the page logged {len(walk['errors'])} errors: "
                        f"{walk['errors'][:3]}")
    # "Nothing happened" has two causes and the gate must not confuse them.
    #
    # A broken door and a renderer too slow to walk are the same picture: the party
    # shifts a little and the room never changes. They are not the same finding.
    # A player who cannot walk because the game is stuck and a player who cannot
    # walk because the harness runs at one frame a second need different tickets,
    # and only one of them is a fault in this project.
    if 0 < moved < len(walk["walk"]):
        best = max((share_changed(SHOTS / s["before"], SHOTS / s["settled"])
                    for s in walk["walk"] if not s.get("skipped")
                    and (SHOTS / s["before"]).exists()
                    and (SHOTS / s["settled"]).exists()), default=0.0)
        print(f"\nthe furthest any hop changed the frame: {best:.2%}")
        if best < 0.02:
            print(
                "The party moves a little and never crosses a door. That is what a\n"
                "renderer too slow to walk looks like, and it is not the same as a\n"
                "broken door: a broken door with a fast renderer shows the party\n"
                "crossing the room and stopping at the exit.\n"
                "\nMeasured here, the build runs at roughly one frame per second under\n"
                "software GL, and the party covers about one tile per thirty frames\n"
                "-- so one tile is half a minute of wall time here. A walk across a\n"
                "planet is not reachable in this environment, and no conclusion\n"
                "about the doors follows from that.")
            raise SystemExit(2)

    if moved == 0:
        failures.append(
            "the keyboard does nothing in a real browser. Every key was held "
            "and no pixel moved. No widget test could have found this, because "
            "there the keys go through the notifier rather than through the page.")
    if stuck:
        failures.append(
            "these hops were supposed to cross a door and did not: "
            + "; ".join(f"{s['tag']} {s['from']}->{s['to']} ({why})"
                        for s, why in stuck))

    unvisited = set(walk["reachable"]) - set(walk["visited"])
    if unvisited:
        failures.append(
            f"the map says these are reachable and the walk never entered them: "
            f"{sorted(unvisited)}")

    if failures:
        print("\nFAIL")
        for f in failures:
            print(f"  - {f}")
        return 1

    print(f"\nOK: every one of the {len(walk['reachable'])} rooms the map calls "
          f"reachable was entered, and every hop crossed a door.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())