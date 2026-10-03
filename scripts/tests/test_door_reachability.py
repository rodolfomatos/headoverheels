"""Tests for the door reachability analysis.

`scripts/door_reachability.py` exists because T095 concluded, from sixteen browser
walks that never went through a door, that the map could not say where the doors
were. The map says: 42 `door` triggers carry `position` and `size`. The walk was
holding one direction key from wherever the party stood, and from `castle_start`'s
spawn at (1,1) that walks the row y=1 -- while the east door is at (15,8).

So the numbers here are about the *plan*, not about the game:

  * the old single-hold plan reached 0 of 16 hops, and
  * an aligned two-leg plan expresses all of them.

Neither is a claim that any door works. They are the difference between an
instrument that can ask and one that cannot.
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "door_reachability", ROOT / "scripts" / "door_reachability.py")
reach = importlib.util.module_from_spec(spec)
sys.modules["door_reachability"] = reach
spec.loader.exec_module(reach)

ROOMS = reach.load_rooms()
WORLD = json.loads(reach.WORLD.read_text(encoding="utf-8"))
START = WORLD.get("startRoom")


def test_the_map_does_record_where_the_doors_are():
    """The premise T095 rested on. It was wrong."""
    doors = [d for room in ROOMS.values() for d in reach.doors_of(room)]

    assert len(doors) == 42
    assert all("position" in d for d in doors), (
        "a door trigger without a position is a door the walk cannot aim at")
    assert all("x" in d["position"] and "y" in d["position"] for d in doors)


def test_the_old_single_hold_plan_mostly_missed_the_door():
    """Sixteen walks; thirteen of them could not have gone through a door.

    The first version of this analysis said sixteen out of sixteen. It was wrong:
    `distance_along` compared the two signed distances, which holds only on a
    diagonal, so it rejected every door on a wall and returned "never reachable"
    for all of them -- a predicate that says no to everything looks exactly like a
    finding. With the perpendicular component compared against zero, three hops
    are genuinely walkable.

    Three is still the finding: thirteen of the sixteen walks said nothing about
    their door, and T095 drew a conclusion from all sixteen.
    """
    sequence = reach.walk_sequence(ROOMS, START)
    crossable = [hop for hop in sequence if hop[1] in reach.WALK_DIRECTIONS]
    assert crossable, "the walk should cross at least one wall"

    reachable = 0
    for room_id, direction, target, start in crossable:
        for door in reach.doors_of(ROOMS[room_id]):
            exit_spec = door.get("exit") or {}
            if exit_spec.get("room") != target:
                continue
            if exit_spec.get("direction") != direction:
                continue
            tile = (int(door["position"]["x"]), int(door["position"]["y"]))
            if reach.distance_along(start, tile, direction) > 0:
                reachable += 1
                break

    assert reachable == 3, (
        f"{reachable} hop(s) are walkable by a single hold; 3 was what the plan "
        "could reach, and if the walker has been taught to line up with a door "
        "this number should be larger -- update it deliberately")


def test_a_door_at_the_party_own_tile_is_not_a_door_it_walked_through():
    """`castle_cell`'s west door is at (1,8) and the party arrives on (1,8).

    Counting that as reachable would let the walk claim a door it never entered.
    Distance has to be positive.
    """
    assert reach.distance_along((1, 8), (1, 8), "west") == -1
    assert reach.distance_along((1, 8), (5, 8), "east") == 4


def test_arrival_is_through_a_door_not_at_the_spawn():
    """The bug that hid the first one.

    Scoring every hop from each room's `spawnPoint` put 24 of 42 doors within
    reach of a straight line. A walk enters a room through the door it came in by,
    and `world.json` names that side as `exit.entrance`.
    """
    arrival = reach.entrance_tile(ROOMS["castle_cell"], "west")

    assert arrival == (1, 8)
    assert ROOMS["castle_cell"]["spawnPoint"]["x"] != arrival[0] or \
        ROOMS["castle_cell"]["spawnPoint"]["y"] != arrival[1]


def test_every_hop_of_the_walk_has_a_door_for_its_direction():
    """A hop with no matching door trigger is a hole in the map, not a walk."""
    sequence = reach.walk_sequence(ROOMS, START)
    holes = []
    for room_id, direction, target, _ in sequence:
        if direction not in reach.WALK_DIRECTIONS:
            continue
        if not any((d.get("exit") or {}).get("room") == target
                   and (d.get("exit") or {}).get("direction") == direction
                   for d in reach.doors_of(ROOMS[room_id])):
            holes.append((room_id, direction, target))

    assert holes == [], f"hops with no door trigger: {holes}"


def test_the_analysis_fails_only_when_no_hop_is_walkable():
    """The exit code has to mean something.

    It returns 1 when the walk cannot reach a single door -- a plan in that state
    cannot report on one. Three walkable hops is not that state, so it returns 0
    and prints the thirteen that are.
    """
    assert reach.main([]) == 0


def test_distance_along_only_accepts_the_perpendicular():
    """The bug that made every door look unreachable."""
    # on the same row, ahead: a real distance
    assert reach.distance_along((1, 8), (5, 8), "east") == 4
    assert reach.distance_along((5, 8), (1, 8), "west") == 4
    # same column, ahead
    assert reach.distance_along((8, 1), (8, 5), "south") == 4
    # off the line
    assert reach.distance_along((1, 8), (5, 9), "east") == -1
    # behind
    assert reach.distance_along((5, 8), (1, 8), "east") == -1
    # on top of the party
    assert reach.distance_along((1, 8), (1, 8), "west") == -1


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))