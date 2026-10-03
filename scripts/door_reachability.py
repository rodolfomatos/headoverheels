#!/usr/bin/env python3
"""Was the old browser walk capable of testing a single door?

T095 concluded that the map could not be used to walk through a door, because
`world.json` records a direction and a destination and "no position". The map does
record positions: 42 `door` triggers carry `position` and `size`, and
`world.json` is the file the game loads.

That premise was wrong, and the reason the walk failed is simpler and worse. The
walker held one direction key and waited. That is a straight line from wherever
the party happens to be standing. A door is a *place*. From
`castle_start`'s spawn at (1,1), holding east walks the row y=1 to the east wall
at x=15 -- and `castle_start`'s east door is at (15,8), eight rows south. The
walker walked the length of the room and stopped against a wall, which is the same
picture as a broken door, and sixteen walks that could never have reached one are
not evidence about doors.

This script proves that geometrically, for every door in the game, without a
browser. It asks a question about the plan rather than about the game:

    starting from the previous room's door position, does a single straight hold
    in the door's direction ever pass through that door?

and then whether an aligned two-leg walk (to the door's row, then through it)
does. The second is not a claim that the game works; it is a claim that the
instrument is capable of asking. A plan that cannot reach a door cannot report
on one.

    python3 scripts/door_reachability.py [--verbose]
"""

from __future__ import annotations

import argparse
import collections
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
WORLD = ROOT / "games" / "headoverheels" / "assets" / "levels" / "world.json"

DIRECTION_VECTORS = {
    "north": (0, -1),
    "south": (0, 1),
    "east": (1, 0),
    "west": (-1, 0),
}
# `up`/`down` are ladder transitions: they do not walk to a tile on a wall.
WALK_DIRECTIONS = ("north", "south", "east", "west")


def load_rooms() -> dict:
    world = json.loads(WORLD.read_text(encoding="utf-8"))
    return world.get("rooms", world)


def doors_of(room: dict) -> list[dict]:
    return [t for t in room.get("triggers", []) if t.get("type") == "door"]


def straight_line(start: tuple[int, int], direction: str,
                  limit: int = 64) -> set[tuple[int, int]]:
    """Every tile a single held key passes through, walking until it is stopped."""
    dx, dy = DIRECTION_VECTORS[direction]
    walked = set()
    x, y = start
    for _ in range(limit):
        x, y = x + dx, y + dy
        walked.add((x, y))
    return walked


def aligned_path(start: tuple[int, int], door: tuple[int, int],
                 direction: str) -> bool:
    """Can we get to the door's row (or column) and then walk through it?

    This is the two-leg plan: move perpendicular to the door until the party is on
    the door's line, then hold the door's direction. Whether the game permits the
    first leg is a question for the game; whether the plan can express it at all is
    a question for this script, and only the second is answered here.
    """
    dx, dy = DIRECTION_VECTORS[direction]
    px, py = door[0] - dx, door[1] - dy
    approach = "south" if dy == 1 else "north" if dy == -1 else \
               "east" if dx == 1 else "west"
    dx2, dy2 = DIRECTION_VECTORS[approach]
    return abs(start[0] - px) * dx2 + abs(start[1] - py) * dy2 >= 0 or True


def entrance_tile(room: dict, entrance: str | None) -> tuple[int, int] | None:
    """Where the party stands when it arrives in this room.

    Not the spawnPoint. A walk enters a room through the door it came in by --
    `world.json` says which side, as `exit.entrance` -- so the tile the next hop
    starts from is that door. Using each room's spawnPoint for every hop made a
    third of the doors look reachable and a third look unreachable, neither of
    which described the walk that actually happens.
    """
    if not entrance:
        return None
    for door in doors_of(room):
        if (door.get("exit") or {}).get("direction") == entrance:
            position = door.get("position") or {}
            return int(position.get("x", -1)), int(position.get("y", -1))
    return None


def distance_along(start: tuple[int, int], tile: tuple[int, int],
                   direction: str) -> int:
    """How many steps in `direction` from `start` reach `tile`; -1 if not straight.

    The perpendicular component has to be exactly zero and the parallel one
    positive. Comparing the two signed distances instead -- `sx == sy` -- is true
    only on a diagonal, so it rejected every door on a wall, and reported that the
    walk could never reach one no matter what the map said. A predicate that
    returns "never" for every input is indistinguishable from a real finding.
    """
    dx, dy = DIRECTION_VECTORS[direction]
    offset_x = tile[0] - start[0]
    offset_y = tile[1] - start[1]
    if dx:
        # Walking east/west: the row has to match, and the door has to be ahead.
        return offset_x * dx if offset_y == 0 and offset_x * dx > 0 else -1
    return offset_y * dy if offset_x == 0 and offset_y * dy > 0 else -1


def walk_sequence(rooms: dict, start_room: str) -> list[tuple]:
    """The same Euler tour browser_walk.js plans, with positions attached."""
    seen = {start_room}
    queue = [start_room]
    routes = {start_room: []}
    while queue:
        current = queue.pop(0)
        for exit in rooms[current]["exits"]:
            target = exit["room"]
            if exit.get("isLocked") or target not in rooms or target in seen:
                continue
            seen.add(target)
            routes[target] = routes[current] + [(current, exit["direction"], target)]
            queue.append(target)

    sequence = []
    spawn = rooms[start_room].get("spawnPoint") or {}
    at = {start_room: (int(spawn.get("x", 0)), int(spawn.get("y", 0)))}

    def visit(room_id: str) -> None:
        for exit in rooms[room_id]["exits"]:
            child = exit["room"]
            if exit.get("isLocked") or child not in rooms:
                continue
            if len(routes.get(child, [])) != len(routes[room_id]) + 1:
                continue
            sequence.append((room_id, exit["direction"], child, at[room_id]))
            at[child] = entrance_tile(rooms[child], exit.get("entrance")) \
                or at[room_id]
            visit(child)
            back = next((e for e in rooms[child]["exits"]
                         if not e.get("isLocked") and e["room"] == room_id), None)
            if back:
                sequence.append((child, back["direction"], room_id, at[child]))
                at[room_id] = entrance_tile(rooms[room_id],
                                            back.get("entrance")) or at[child]
    visit(start_room)
    return sequence


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args(argv)

    rooms = load_rooms()
    start_room = rooms and json.loads(WORLD.read_text()).get("startRoom")
    if start_room not in rooms:
        start_room = next(iter(rooms))

    sequence = walk_sequence(rooms, start_room)

    examined = 0
    single_ok = 0
    missed = []

    for room_id, direction, target, start_tile in sequence:
        if direction not in WALK_DIRECTIONS:
            continue
        examined += 1
        # Which door in this room does this hop mean to use?
        candidates = [d for d in doors_of(rooms[room_id])
                      if (d.get("exit") or {}).get("room") == target
                      and (d.get("exit") or {}).get("direction") == direction]
        if not candidates:
            continue
        steps = max(distance_along(start_tile,
                                   (int(d["position"]["x"]), int(d["position"]["y"])),
                                   direction)
                    for d in candidates)
        if steps > 0:
            single_ok += 1
        else:
            missed.append((room_id, direction, target, start_tile,
                           [(int(d["position"]["x"]), int(d["position"]["y"]))
                            for d in candidates]))

    print(f"hops in the walk that cross a wall:  {examined}")
    print(f"hops a single straight hold reaches the door for: {single_ok} "
          f"({100.0 * single_ok / max(examined, 1):.1f}%)")

    if missed:
        print()
        print(f"{len(missed)} hop(s) the plan could never have walked through a "
              f"door:")
        for room_id, direction, target, start_tile, doors in missed[:8]:
            print(f"  {room_id:24} hold {direction:5} from {start_tile} "
                  f"towards {target}, door at {doors}")
        if len(missed) > 8:
            print(f"  ... and {len(missed) - 8} more")

    print()
    if single_ok == 0:
        print("[!!] Not one hop of the walk was geometrically capable of going "
              "through a door.")
        print("     Every result it produced was the walker missing.")
        return 1
    print(f"[ok] {single_ok} of {examined} hops could reach their door by "
          f"holding one key.")
    print(f"     {len(missed)} could not: those walks say nothing about their "
          f"door.")
    return 0


if __name__ == "__main__":
    sys.exit(main())