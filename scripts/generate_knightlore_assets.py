#!/usr/bin/env python3
"""Generates the Knight Lore tilesets and sprites.

Everything here is original art produced by this script: isometric 64x32
diamond tiles for the five areas, the sabreman and the four knights, and the
puzzle furniture. No original game graphics are used.

Run from the repository root:
    python3 scripts/generate_knightlore_assets.py
"""

from __future__ import annotations

import math
import os
from dataclasses import dataclass

from PIL import Image, ImageDraw

TILE_W = 64
TILE_H = 32
BLOCK_H = 16
# Every tile sprite is this tall, with the diamond at a fixed y, so the three
# tiles of a sheet line up exactly when the renderer draws them.
TILE_SPRITE_H = TILE_H + BLOCK_H * 2
# The top of the diamond inside a sprite.
D_TOP = BLOCK_H

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_TILES = os.path.join(ROOT, "games", "knightlore", "assets", "world", "tiles")
OUT_SPRITES = os.path.join(ROOT, "games", "knightlore", "assets", "sprites")


@dataclass(frozen=True)
class AreaPalette:
    name: str
    floor_top: tuple[int, int, int]
    floor_side: tuple[int, int, int]
    wall_top: tuple[int, int, int]
    wall_side: tuple[int, int, int]
    wall_left: tuple[int, int, int]
    accent: tuple[int, int, int]


AREAS = [
    AreaPalette(
        "castle",
        (122, 114, 104),
        (74, 68, 62),
        (168, 158, 142),
        (96, 88, 80),
        (62, 57, 52),
        (236, 198, 112),
    ),
    AreaPalette(
        "jungle",
        (92, 142, 78),
        (54, 92, 48),
        (126, 180, 100),
        (74, 118, 62),
        (48, 78, 42),
        (186, 236, 118),
    ),
    AreaPalette(
        "cauldron",
        (108, 86, 120),
        (66, 52, 74),
        (152, 124, 166),
        (88, 68, 96),
        (58, 45, 64),
        (224, 150, 244),
    ),
    AreaPalette(
        "mine",
        (104, 98, 92),
        (62, 58, 54),
        (142, 132, 120),
        (82, 76, 70),
        (54, 50, 46),
        (248, 186, 96),
    ),
    AreaPalette(
        "tower",
        (94, 90, 118),
        (56, 53, 74),
        (132, 126, 162),
        (76, 72, 100),
        (50, 47, 64),
        (198, 178, 255),
    ),
]


def shade(colour: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    return tuple(max(0, min(255, int(channel * factor))) for channel in colour)


def diamond_mask(size: tuple[int, int], width: int, height: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.polygon(
        [
            (width // 2, 0),
            (width - 1, height // 2),
            (width // 2, height - 1),
            (0, height // 2),
        ],
        fill=255,
    )
    return mask


def diamond_polygon(width: int, height: int, top: int = 0):
    return [
        (width // 2, top),
        (width - 1, top + height // 2),
        (width // 2, top + height - 1),
        (0, top + height // 2),
    ]


def floor_tile(palette: AreaPalette) -> Image.Image:
    tile = Image.new("RGBA", (TILE_W, TILE_SPRITE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    draw.polygon(
        diamond_polygon(TILE_W, TILE_H, top=D_TOP),
        fill=palette.floor_top + (255,),
    )

    # An inner diamond reads as a tile edge, so the floor is not a flat sheet.
    # It has to stay centred, or the whole room ends up sheared.
    inner_w, inner_h = TILE_W - 12, TILE_H - 6
    inner = [
        (x + (TILE_W - inner_w) // 2, y + (TILE_H - inner_h) // 2 + D_TOP)
        for x, y in diamond_polygon(inner_w, inner_h)
    ]
    draw.polygon(inner, fill=shade(palette.floor_top, 1.1) + (255,))
    outline = diamond_polygon(TILE_W, TILE_H, top=D_TOP)
    draw.line(outline + [outline[0]], fill=palette.floor_side + (255,))
    # Two quiet marks so a large floor still has texture without moire.
    for dx in (-8, 9):
        draw.point(
            [(TILE_W // 2 + dx, D_TOP + TILE_H // 2)],
            fill=palette.floor_side + (255,),
        )
    return tile


def wall_tile(palette: AreaPalette) -> Image.Image:
    """A solid block: a lit diamond on top of two faces extruded downwards.

    Extruding down, not up, is what keeps the block sitting on its own tile: a
    raised top face would leave the block floating over the floor.
    """
    tile = Image.new("RGBA", (TILE_W, TILE_SPRITE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    middle = D_TOP + TILE_H // 2
    bottom = D_TOP + TILE_H - 1
    foot = TILE_SPRITE_H - 1
    left = [(0, middle), (TILE_W // 2, bottom), (TILE_W // 2, foot), (0, foot - TILE_H // 2)]
    right = [
        (TILE_W - 1, middle),
        (TILE_W // 2, bottom),
        (TILE_W // 2, foot),
        (TILE_W - 1, foot - TILE_H // 2),
    ]
    draw.polygon(left, fill=palette.wall_left + (255,))
    draw.polygon(right, fill=palette.wall_side + (255,))
    draw.polygon(
        diamond_polygon(TILE_W, TILE_H, top=D_TOP),
        fill=palette.wall_top + (255,),
    )
    outline = diamond_polygon(TILE_W, TILE_H, top=D_TOP)
    draw.line(outline + [outline[0]], fill=shade(palette.wall_top, 1.3) + (255,), width=2)

    # Masonry joints: one course line and two uprights per face.
    for face, tint in ((left, 0.72), (right, 0.55)):
        draw.line(
            [(face[0][0], middle + 8), (TILE_W // 2, bottom + 8)],
            fill=shade(palette.wall_side, tint) + (255,),
        )
        draw.line(
            [(face[3][0] + (TILE_W // 2 - face[3][0]) // 2, face[3][1] + TILE_H // 4),
             (TILE_W // 2, bottom + 8 + TILE_H // 4)],
            fill=shade(palette.wall_side, tint) + (255,),
        )
    # The corner between the two faces, and a shadow where the block meets the
    # floor.
    draw.line(
        [(TILE_W // 2, bottom), (TILE_W // 2, foot)],
        fill=shade(palette.wall_side, 0.45) + (255,),
    )
    draw.line(
        [(0, foot - TILE_H // 2), (TILE_W // 2, foot), (TILE_W - 1, foot - TILE_H // 2)],
        fill=shade(palette.wall_side, 0.5) + (200,),
    )
    return tile


def wall_top_tile(palette: AreaPalette) -> Image.Image:
    """The far wall of a room: a lit top face and the top of its front face."""
    tile = Image.new("RGBA", (TILE_W, TILE_SPRITE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    middle = D_TOP + TILE_H // 2
    bottom = D_TOP + TILE_H - 1
    draw.polygon(
        [(0, middle), (TILE_W // 2, bottom), (TILE_W - 1, middle), (TILE_W // 2, middle - TILE_H // 2)],
        fill=shade(palette.wall_side, 0.8) + (255,),
    )
    draw.polygon(
        diamond_polygon(TILE_W, TILE_H, top=D_TOP),
        fill=palette.wall_top + (255,),
    )
    draw.polygon(
        [
            (x + (TILE_W - 50) // 2, y + (TILE_H - 25) // 2 + D_TOP)
            for x, y in diamond_polygon(50, 25)
        ],
        fill=shade(palette.wall_top, 1.12) + (255,),
    )
    outline = diamond_polygon(TILE_W, TILE_H, top=D_TOP)
    draw.line(outline + [outline[0]], fill=shade(palette.wall_top, 1.35) + (255,), width=2)
    return tile


def build_tileset(palette: AreaPalette) -> Image.Image:
    sheet = Image.new("RGBA", (TILE_W * 3, TILE_SPRITE_H), (0, 0, 0, 0))
    floor = floor_tile(palette)
    wall = wall_tile(palette)
    top = wall_top_tile(palette)
    for index, tile in enumerate([floor, wall, top]):
        # All three sprites are the same height with the diamond at the same
        # y, so the renderer can centre them on the tile and line them up.
        assert tile.height == TILE_SPRITE_H, tile.height
        sheet.paste(tile, (index * TILE_W, 0), tile)
    return sheet


def knight_sprite(colour: tuple[int, int, int], frames: int = 4) -> Image.Image:
    """A small 24x32 knight, four walk frames, generated as a strip."""
    width, height = 24, 32
    frame_w = 20
    sheet = Image.new("RGBA", (frame_w * frames, height), (0, 0, 0, 0))
    for frame in range(frames):
        draw = ImageDraw.Draw(sheet)
        x0 = frame * frame_w
        bob = -1 if frame % 2 == 0 else 1
        # body
        draw.polygon(
            [
                (x0 + 10, 6 + bob),
                (x0 + 15, 14 + bob),
                (x0 + 10, 24 + bob),
                (x0 + 5, 14 + bob),
            ],
            fill=colour + (255,),
        )
        # helmet
        draw.ellipse(
            [x0 + 6, 2 + bob, x0 + 14, 10 + bob],
            fill=shade(colour, 1.2) + (255,),
        )
        # visor slit
        draw.line([(x0 + 7, 6 + bob), (x0 + 13, 6 + bob)], fill=(20, 20, 24, 255))
        # legs move with the frame
        leg = 2 if frame % 2 == 0 else 0
        draw.line(
            [(x0 + 8, 22 + bob), (x0 + 8 + leg, 30)],
            fill=shade(colour, 0.6) + (255,),
            width=2,
        )
        draw.line(
            [(x0 + 12, 22 + bob), (x0 + 12 - leg, 30)],
            fill=shade(colour, 0.6) + (255,),
            width=2,
        )
    return sheet


def prop_sprite(kind: str, accent: tuple[int, int, int]) -> Image.Image:
    size = 32
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    brown = (108, 74, 44, 255)
    if kind == "chest":
        draw.rectangle([6, 12, 26, 26], fill=brown)
        draw.rectangle([6, 12, 26, 18], fill=shade(brown[:3], 1.3) + (255,))
        draw.rectangle([14, 16, 18, 22], fill=accent + (255,))
    elif kind == "cauldron":
        draw.ellipse([4, 12, 28, 28], fill=(48, 46, 52, 255))
        draw.ellipse([7, 13, 25, 20], fill=accent + (255,))
        draw.ellipse([10, 10, 22, 16], fill=shade(accent, 0.7) + (200,))
    elif kind == "wizard":
        draw.polygon([(16, 4), (26, 28), (6, 28)], fill=accent + (255,))
        draw.ellipse([11, 2, 21, 12], fill=(226, 208, 176, 255))
        draw.line([(9, 6), (23, 2)], fill=(90, 70, 40, 255), width=2)
    elif kind == "ball":
        draw.ellipse([8, 12, 24, 28], fill=(60, 58, 64, 255))
        draw.ellipse([10, 14, 20, 20], fill=shade((60, 58, 64), 1.4) + (255,))
    elif kind == "statue":
        draw.rectangle([10, 8, 22, 28], fill=(120, 118, 126, 255))
        draw.ellipse([11, 2, 21, 12], fill=(150, 148, 156, 255))
    elif kind == "witch":
        draw.polygon([(16, 6), (26, 28), (6, 28)], fill=shade(accent, 0.8) + (255,))
        draw.ellipse([12, 4, 20, 12], fill=(80, 200, 140, 255))
    elif kind == "portcullis":
        draw.rectangle([6, 6, 26, 28], outline=accent + (255,), width=2)
        for x in range(9, 26, 4):
            draw.line([(x, 6), (x, 28)], fill=accent + (255,), width=1)
    elif kind == "scroll":
        draw.rectangle([8, 8, 24, 24], fill=(226, 214, 180, 255))
        draw.line([(10, 12), (22, 12)], fill=(120, 100, 70, 255))
        draw.line([(10, 16), (20, 16)], fill=(120, 100, 70, 255))
    elif kind == "diamond":
        draw.polygon(
            [(16, 6), (24, 16), (16, 28), (8, 16)],
            fill=accent + (255,),
        )
        draw.line([(16, 6), (16, 28)], fill=(255, 255, 255, 180))
    return image


PROPS = ["chest", "cauldron", "wizard", "ball", "statue", "witch", "portcullis",
         "scroll", "diamond"]


def main() -> None:
    os.makedirs(OUT_TILES, exist_ok=True)
    os.makedirs(OUT_SPRITES, exist_ok=True)

    for palette in AREAS:
        sheet = build_tileset(palette)
        sheet.save(os.path.join(OUT_TILES, f"{palette.name}.png"))
        print(f"tiles  {palette.name}.png {sheet.size}")

    knight_dir = os.path.join(OUT_SPRITES, "knights")
    os.makedirs(knight_dir, exist_ok=True)
    sabreman = knight_sprite((150, 152, 158))
    sabreman.save(os.path.join(knight_dir, "sabreman_idle.png"))
    for name, colour in [
        ("jinx", (76, 139, 245)),
        ("joronie", (242, 201, 76)),
        ("achinda", (235, 87, 87)),
        ("celist", (76, 175, 80)),
    ]:
        knight_sprite(colour).save(os.path.join(knight_dir, f"{name}_walk.png"))
    print(f"knights {len(os.listdir(knight_dir))} sheets")

    prop_dir = os.path.join(OUT_SPRITES, "props")
    os.makedirs(prop_dir, exist_ok=True)
    for area in AREAS:
        for prop in PROPS:
            prop_sprite(prop, area.accent).save(
                os.path.join(prop_dir, f"{prop}_{area.name}.png")
            )
    print(f"props {len(os.listdir(prop_dir))} sheets")


if __name__ == "__main__":
    main()
