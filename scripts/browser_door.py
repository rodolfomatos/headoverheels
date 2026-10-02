#!/usr/bin/env python3
"""Did walking through a door change the room?

`browser_motion.py` asks "does the frame change", and the party moving changes the
frame, so that question is answered by a game that is alive and broken in the same
way. It was green through the party vanishing on every door, the joystick a half
turn out, an untouched party sliding down the room, and a switch under a conveyor.

This asks a different question, and the discriminator is arithmetic rather than a
threshold somebody liked:

- The party is a 64x40 sprite. Walking it across a 1000x720 frame changes at most
  about 0.4% of it.
- A different room changes nearly all of it, because the floor, the walls and every
  entity in it are different.

So "more than a fifth of the frame changed" cannot be walking. It is a different
room. The margin is wide enough that the number does not need defending, which is
the point: a gate whose threshold is a guess gets relaxed the first time a slow
machine is called unreasonable.
"""

from __future__ import annotations

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import browser_pixels as bp  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Walking the party cannot change this much of the frame. The sprite is 64x40, so a
# sweep across a 1000x720 frame is about 0.4%; a fifth of the frame is fifty times
# that, and a room change is most of it.
ROOM_CHANGE_SHARE = 0.20

# And "nothing moved at all" is its own failure: a build where the keyboard does
# nothing would otherwise pass this by never changing anything.
ANY_MOTION_SHARE = 0.0005


def share_changed(a: pathlib.Path, b: pathlib.Path) -> float:
    """The fraction of pixels that differ between two captures."""
    wa, ha, _, pa = bp.decode(a)
    wb, hb, _, pb = bp.decode(b)
    if (wa, ha) != (wb, hb):
        raise SystemExit(
            f"{a.name} is {wa}x{ha} and {b.name} is {wb}x{hb}: two captures of "
            f"different sizes cannot be compared, and treating them as equal "
            f"would make every number meaningless")
    total = wa * ha
    step = 2  # sampled, as browser_motion does, so this is not slow
    differing = 0
    sampled = 0
    for y in range(0, ha, step):
        for x in range(0, wa, step):
            sampled += 1
            if pa[y * wa + x] != pb[y * wa + x]:
                differing += 1
    return differing / max(1, sampled)


def main() -> int:
    before = sorted((ROOT / "build/browser").glob("hoh_key_*.png"))
    after = sorted((ROOT / "build/browser").glob("hoh_after_*.png"))
    if not before or not after:
        print("no keyboard walk captures found; the KEYS step did not run")
        return 1

    print(f"ROOM CHANGE: more than {ROOM_CHANGE_SHARE:.0%} of the frame")
    print(f"ANY MOTION:   more than {ANY_MOTION_SHARE:.2%} of the frame\n")

    moved = 0
    changed_room = 0
    for a, b in zip(before, after):
        share = share_changed(a, b)
        print(f"  {a.name} -> {b.name}: {share:.2%}")
        if share > ANY_MOTION_SHARE:
            moved += 1
        if share > ROOM_CHANGE_SHARE:
            changed_room += 1

    print(f"\n{moved} of {len(before)} steps moved the party at all")
    print(f"{changed_room} of {len(before)} steps changed the room")

    if moved == 0:
        print("\nFAIL: the keyboard does nothing in a real browser.")
        print("Every key was held and no pixel moved. This is a finding no widget")
        print("test could make, because there the keys go through the notifier")
        print("rather than through the page.")
        return 1

    if changed_room == 0:
        print("\nFAIL: the party moved and the room never changed.")
        print("Walking is not going through a door, and nothing in the gate has")
        print("ever told the two apart.")
        return 1

    print("\nOK: the party walked, and at least one step changed the room.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
