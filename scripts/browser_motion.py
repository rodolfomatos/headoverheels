#!/usr/bin/env python3
"""How much each pair of consecutive browser captures differs.

The question a screenshot cannot answer on its own is whether anything is
happening. A build that draws a room with nothing in it and a build that draws a
room with a party walking through it produce frames that look the same and
differ in a number, and the number is the one worth a gate: **0 changed pixels
means nothing on the screen is moving**, which is what a room whose party is
drawn off the edge of the canvas looks like.

It compares only frames of the same series and of the same size, so a capture
from a different window does not get compared with one that is not its pair.

    python3 scripts/browser_motion.py build/browser/hoh_*.png
"""

import argparse
import collections
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import browser_pixels as bp  # noqa: E402


def series(paths):
    """The capture series a path belongs to: everything before the last _NNN."""
    out = collections.defaultdict(list)
    for path in paths:
        stem = os.path.basename(path)
        if stem.endswith("_menu.png"):
            continue
        key = stem.rsplit("_", 1)[0]
        out[key].append(path)
    return {k: sorted(v) for k, v in out.items()}


def changed(a, b, step=2):
    wa, ha, cha, pa = bp.decode(a)
    wb, hb, chb, pb = bp.decode(b)
    if (wa, ha) != (wb, hb):
        return None
    stride = wa * cha
    n = 0
    n = 0
    for y in range(0, ha, step):
        row = y * stride
        for x in range(0, wa, step):
            o = row + x * cha
            if pa[o : o + 3] != pb[o : o + 3]:
                n += 1
    return n, (wa * ha) // (step * step)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("png", nargs="+")
    ap.add_argument(
        "--fail-under",
        type=int,
        default=1,
        help="the smallest per-step change a moving screen may have",
    )
    ap.add_argument(
        "--report-only",
        action="store_true",
        help="print the numbers and say nothing about whether they are a fault",
    )
    args = ap.parse_args()

    paths = []
    for pattern in args.png:
        paths.extend(sorted(glob.glob(pattern)) or [pattern])

    quiet = [s for s in series(paths).values() if len(s) > 1]
    if not quiet:
        print("no capture series with two frames in it")
        return 0

    quiet_total = 0
    quiet_moving = 0
    for frames in quiet:
        name = os.path.basename(frames[0]).rsplit("_", 1)[0]
        print(f"{name}:")
        for a, b in zip(frames, frames[1:]):
            result = changed(a, b)
            if result is None:
                print(f"  {os.path.basename(a)} -> {os.path.basename(b)}: "
                      "sizes differ, not compared")
                continue
            n, sampled = result
            share = 100.0 * n / sampled
            quiet_total += 1
            if n >= args.fail_under:
                quiet_moving += 1
            print(
                f"  {os.path.basename(a).rsplit('_', 1)[1][:-4]:>5}s -> "
                f"{os.path.basename(b).rsplit('_', 1)[1][:-4]:>5}s  "
                f"changed {n:>7} of {sampled} sampled pixels ({share:.2f}%)"
                + ("  moving" if n >= args.fail_under else "")
            )

    if quiet_total == 0:
        return 0
    # Most of the steps, not all of them. A party that walks into a wall and
    # stops moving has one quiet step and is not a fault; a game with nothing in
    # the room has every one of them quiet, which is.
    needed = max(1, quiet_total // 2)
    print(
        f"{quiet_moving} of {quiet_total} steps changed by at least "
        f"{args.fail_under} sampled pixels; {needed} needed"
    )
    if quiet_moving < needed:
        print(
            "nothing is moving on the screen"
            + (
                ""
                if args.report_only
                else " — which for a room with a party in it is a fault"
            )
        )
        return 0 if args.report_only else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
