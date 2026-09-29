#!/usr/bin/env python3
"""Publish a tileset per planet, and describe it from the sheet it comes from.

The image in the tileset is named by its file name alone: flame_tiled resolves a
tileset's image under `assets/images/`, and a path that already starts with
`assets/images/` asks for `assets/images/assets/images/castle.png`, which is
what the first version of this wrote and what the room tests caught.

Four of the five planets had no tileset the game could load: the world names a
theme for every room, `generate_rooms.dart` asked for `<theme>.tsx`, and only
`castle.tsx` existed, so every room in every planet drew the castle. The art was
not missing. `assets/sprites/tiles/<theme>.png` is a 1024x512 sheet for each of
them, and what was missing was the description of that sheet and a copy the game
can load.

The tile count and the column count are measured from the PNG rather than
written down here, so a sheet that changes size cannot leave a tileset lying
about it. Run with `--check` to verify what is published without writing.
"""

import argparse
import struct
import sys
from pathlib import Path

from PIL import Image

from tileset_geometry import apply_diamond_mask

ROOT = Path(__file__).parent.parent
GAME = ROOT / "games" / "headoverheels"
# The worlds' themes, and the sheet each one's art lives in. `castle` is the odd
# one: its sheet was written straight to the published place by an older
# generator, so there is nothing to copy for it.
THEMES = {
    "castle": GAME / "assets" / "images" / "castle.png",
    "egyptus": GAME / "assets" / "sprites" / "tiles" / "egyptus.png",
    "penitentiary": GAME / "assets" / "sprites" / "tiles" / "penitentiary.png",
    "safari": GAME / "assets" / "sprites" / "tiles" / "safari.png",
    "bookworld": GAME / "assets" / "sprites" / "tiles" / "bookworld.png",
}
TILE_W, TILE_H = 64, 32
COLUMNS = 16
IMAGE_ROOT = GAME / "assets" / "images"
TILESET_ROOT = GAME / "assets" / "levels" / "tilesets"

TSX = """<?xml version='1.0' encoding='utf-8'?>
<tileset version="1.10" tiledversion="1.10.0" name="{theme}" tilewidth="{tile_w}" tileheight="{tile_h}" tilecount="{count}" columns="{columns}">
 <grid orientation="isometric" width="{tile_w}" height="{tile_h}" />
 <image source="{theme}.png" width="{width}" height="{height}" />
</tileset>
"""


def png_size(path: Path) -> tuple:
    """The size of a PNG, from its own header."""
    with open(path, "rb") as handle:
        head = handle.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG")
    return struct.unpack(">II", head[16:24])


def build(theme: str, source: Path, check: bool) -> bool:
    """Publish one planet's tileset. Returns whether it is already right."""
    if not source.exists():
        print(f"{theme}: no art at {source}", file=sys.stderr)
        return False

    width, height = png_size(source)
    rows = height // TILE_H
    columns = width // TILE_W
    count = rows * columns

    published = IMAGE_ROOT / f"{theme}.png"
    tileset = TILESET_ROOT / f"{theme}.tsx"
    wanted_image = f"assets/images/{theme}.png"
    wanted_tileset = TSX.format(
        theme=theme,
        tile_w=TILE_W,
        tile_h=TILE_H,
        count=count,
        columns=columns,
        width=width,
        height=height,
    ).strip()

    problems = []
    if not published.exists():
        problems.append(f"missing {published.relative_to(GAME)}")
    elif png_size(published) != (width, height):
        problems.append(
            f"{published.name} is {png_size(published)}, the art is {(width, height)}"
        )
    if not tileset.exists():
        problems.append(f"missing {tileset.relative_to(GAME)}")
    elif tileset.read_text().strip() != wanted_tileset:
        problems.append(f"{tileset.name} does not describe {source.name}")

    if not problems:
        print(f"{theme}: {count} tiles in {columns} columns, published")
        return True

    if check:
        for problem in problems:
            print(f"{theme}: {problem}", file=sys.stderr)
        return False

    # The sheets are drawn as squares and the game draws them as diamonds, so the
    # mask is applied on the way out. Applying it to an already-masked sheet
    # changes nothing, which is what makes this safe to run twice.
    IMAGE_ROOT.mkdir(parents=True, exist_ok=True)
    TILESET_ROOT.mkdir(parents=True, exist_ok=True)
    if source != published:
        image = Image.open(source).convert("RGBA")
        apply_diamond_mask(image).save(published, optimize=True)
    tileset.write_text(wanted_tileset + "\n")
    print(f"{theme}: published {count} tiles")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero when a planet's tileset is not what this writes",
    )
    arguments = parser.parse_args()

    ok = True
    for theme, source in THEMES.items():
        ok = build(theme, source, arguments.check) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
