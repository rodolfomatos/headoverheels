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
        (74, 70, 66),
        (44, 41, 38),
        (96, 92, 88),
        (58, 54, 50),
        (40, 37, 34),
        (198, 168, 96),
    ),
    AreaPalette(
        "jungle",
        (58, 92, 52),
        (32, 58, 30),
        (78, 118, 66),
        (44, 72, 40),
        (30, 52, 28),
        (150, 210, 90),
    ),
    AreaPalette(
        "cauldron",
        (72, 58, 78),
        (42, 34, 48),
        (96, 78, 102),
        (56, 44, 60),
        (38, 30, 42),
        (198, 120, 220),
    ),
    AreaPalette(
        "mine",
        (66, 62, 58),
        (38, 35, 32),
        (88, 82, 76),
        (50, 46, 42),
        (34, 31, 28),
        (232, 168, 72),
    ),
    AreaPalette(
        "tower",
        (60, 58, 76),
        (34, 32, 46),
        (84, 80, 104),
        (48, 45, 62),
        (32, 30, 40),
        (170, 150, 240),
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
    tile = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    draw.polygon(diamond_polygon(TILE_W, TILE_H), fill=palette.floor_top + (255,))
    # A darker lower band gives the floor some depth without a second sprite.
    draw.polygon(
        diamond_polygon(TILE_W, TILE_H, top=6),
        outline=palette.floor_side + (255,),
    )
    for offset in (10, 20, 30):
        draw.point([(TILE_W // 2 + offset, TILE_H // 2)], fill=palette.floor_side)
    return tile


def wall_tile(palette: AreaPalette) -> Image.Image:
    """A solid block: a lit diamond on top of two visible sides."""
    tile = Image.new("RGBA", (TILE_W, TILE_H + BLOCK_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    top = BLOCK_H
    left = [(0, TILE_H // 2), (TILE_W // 2, TILE_H - 1), (TILE_W // 2, top + TILE_H // 2 - 1)]
    right = [
        (TILE_W - 1, TILE_H // 2),
        (TILE_W // 2, TILE_H - 1),
        (TILE_W // 2, top + TILE_H // 2 - 1),
    ]
    draw.polygon(left, fill=palette.wall_left + (255,))
    draw.polygon(right, fill=palette.wall_side + (255,))
    draw.polygon(
        diamond_polygon(TILE_W, TILE_H, top=top),
        fill=palette.wall_top + (255,),
    )
    draw.line(
        diamond_polygon(TILE_W, TILE_H, top=top) + [diamond_polygon(TILE_W, TILE_H, top=top)[0]],
        fill=shade(palette.wall_top, 1.25) + (255,),
        width=1,
    )
    return tile.crop((0, 0, TILE_W, TILE_H + BLOCK_H))


def wall_top_tile(palette: AreaPalette) -> Image.Image:
    tile = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    draw.polygon(diamond_polygon(TILE_W, TILE_H), fill=palette.wall_top + (255,))
    draw.polygon(
        diamond_polygon(TILE_W, TILE_H, top=5),
        outline=shade(palette.wall_top, 0.8) + (255,),
    )
    return tile


def build_tileset(palette: AreaPalette) -> Image.Image:
    sheet = Image.new("RGBA", (TILE_W * 3, TILE_H + BLOCK_H), (0, 0, 0, 0))
    floor = floor_tile(palette)
    wall = wall_tile(palette)
    top = wall_top_tile(palette)
    for index, tile in enumerate([floor, wall, top]):
        # Floor and wall top are 32 tall, the block is 48; align them on the
        # lower half so a room reads as a flat plane with blocks on it.
        offset = (TILE_H + BLOCK_H) - tile.height
        sheet.paste(tile, (index * TILE_W, offset), tile)
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
