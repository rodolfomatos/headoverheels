from pathlib import Path

import numpy as np
from PIL import Image


def apply_diamond_mask(image: Image.Image) -> Image.Image:
    data = np.array(image.convert("RGBA"))
    height, width = data.shape[:2]
    y, x = np.mgrid[0:32, 0:64]
    inside = (np.abs(x - 32) / 32 + np.abs(y - 16) / 16) <= 1.0
    for tile_y in range(height // 32):
        for tile_x in range(width // 64):
            offset_y = tile_y * 32
            offset_x = tile_x * 64
            cell = data[offset_y:offset_y + 32, offset_x:offset_x + 64]
            cell[~inside, 3] = 0
            data[offset_y:offset_y + 32, offset_x:offset_x + 64] = cell
    return Image.fromarray(data, "RGBA")


def save_masked(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    apply_diamond_mask(image).save(path, optimize=True)
