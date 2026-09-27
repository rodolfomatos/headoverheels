#!/usr/bin/env python3
"""Publishes the asset list of a game into its pubspec, or checks that it is current.

A pubspec entry ending in `/` bundles the files directly inside that directory
and nothing below it, so `assets/sprites/` ships the manifest and none of the
sprites. A tree this deep cannot be listed by hand without something being
missed, and nothing notices: the build succeeds and the game draws nothing.

So the list is generated from the tree, and `make check` fails when it is stale.

    python3 scripts/publish_assets.py games/knightlore                    # write
    python3 scripts/publish_assets.py games/knightlore --check             # verify
    python3 scripts/publish_assets.py games/x --root assets --root style   # other roots
"""

import argparse
import sys
from pathlib import Path

BEGIN = "# BEGIN GENERATED ASSETS"
END = "# END GENERATED ASSETS"
# Directories that are not shipped: caches, intermediates, anything ignored.
SKIP_DIRS = {".dart_tool", "build", "sprites_normalized", "__pycache__", ".idea"}
# What a game ships: its assets, and the style files the tooling reads.
DEFAULT_ROOTS = ("assets", "style")


def game_root(argument: str) -> Path:
    return Path(argument)


def asset_entries(root: Path, roots: tuple[str, ...]) -> list[str]:
    """The leaf directories and loose files under [roots], as pubspec paths.

    Only the leaves are listed: a directory is there for the files directly
    inside it, which is the only thing a `dir/` entry ships. A loose file such as
    `assets/levels/world.json` is listed on its own.
    """
    entries: list[str] = []
    for name in roots:
        base = root / name
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            parts = path.relative_to(root).parts
            if any(part in SKIP_DIRS for part in parts):
                continue
            if path.is_dir():
                if any(child.is_file() for child in path.iterdir()):
                    entries.append(path.relative_to(root).as_posix() + "/")
            elif path.parent == base:
                entries.append(path.relative_to(root).as_posix())
    return sorted(set(entries))


def render(entries: list[str]) -> str:
    lines = [BEGIN]
    lines += [f"    - {entry}" for entry in entries]
    lines.append(END)
    return "\n".join(lines)


def current_block(pubspec: str) -> str | None:
    begin = pubspec.find(BEGIN)
    end = pubspec.find(END)
    if begin < 0 or end < 0:
        return None
    return pubspec[begin : end + len(END)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("game")
    parser.add_argument(
        "--root",
        action="append",
        default=None,
        help="a directory to publish, repeatable (default: assets, style)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero when the pubspec is not what this script writes",
    )
    arguments = parser.parse_args()

    root = game_root(arguments.game)
    pubspec_path = root / "pubspec.yaml"
    if not pubspec_path.exists():
        print(f"no pubspec at {pubspec_path}")
        return 1
    pubspec = pubspec_path.read_text()

    roots = tuple(arguments.root) if arguments.root else DEFAULT_ROOTS
    entries = asset_entries(root, roots)
    if not entries:
        print(f"{root} has no assets to publish")
        return 1
    block = render(entries)

    if arguments.check:
        existing = current_block(pubspec)
        if existing is None:
            print(f"{pubspec_path} has no generated asset block")
            return 1
        if existing != block:
            print(
                f"{pubspec_path} does not match the tree: "
                f"{len(existing.splitlines()) - 2} entries there, "
                f"{len(entries)} here. "
                f"Run: python3 scripts/publish_assets.py {root}"
            )
            return 1
        print(f"{pubspec_path}: {len(entries)} asset entries, up to date")
        return 0

    begin = pubspec.find(BEGIN)
    end = pubspec.find(END)
    if begin < 0 or end < 0:
        print(f"{pubspec_path} has no {BEGIN} marker to replace")
        return 1
    pubspec_path.write_text(pubspec[:begin] + block + pubspec[end + len(END) :])
    print(f"{pubspec_path}: wrote {len(entries)} asset entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
