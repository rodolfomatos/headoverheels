#!/usr/bin/env python3
"""
Validate tile sprites for correct geometry and palette.
"""

import json
import sys
import re
from pathlib import Path
from PIL import Image
import numpy as np

STYLE_DIR = Path(__file__).parent.parent / "style"
with open(STYLE_DIR / "geometry.json") as f:
    GEOMETRY = json.load(f)
with open(STYLE_DIR / "palette.json") as f:
    PALETTE = json.load(f)

ALLOWED_COLORS = set()
for color in PALETTE["base"].values():
    ALLOWED_COLORS.add(color.lower())
for theme_colors in PALETTE["themes"].values():
    for color in theme_colors.values():
        ALLOWED_COLORS.add(color.lower())

TILE_W = 64
TILE_H = 32


def validate_tile(img_path: Path, theme: str = "") -> list[str]:
    """Validate a single tile sprite."""
    errors = []
    
    try:
        img = Image.open(img_path)
    except Exception as e:
        return [f"Failed to open {img_path}: {e}"]
    
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    # 1. Check dimensions
    if img.size != (TILE_W, TILE_H):
        return [f"Wrong dimensions: {img.size} (expected {TILE_W}x{TILE_H})"]
    
    # 2. Check diamond geometry
    errors = check_diamond_geometry(np.array(img))
    if errors:
        errors = [f"Geometry: {e}" for e in errors]
    
    # 3. Check palette
    palette_errors = check_palette(np.array(img))
    if palette_errors:
        errors.extend([f"Palette: {e}" for e in palette_errors])
    
    # 4. Check alpha mask
    alpha_errors = check_alpha_mask(np.array(img))
    if alpha_errors:
        errors.extend([f"Alpha: {e}" for e in alpha_errors])
    
    # 5. Check for tile ID in filename
    if not extract_tile_id(img_path):
        return [f"Cannot extract tile ID from filename: {img_path.name}"]
    
    return errors


def check_diamond_geometry(data: np.ndarray) -> list[str]:
    """Check that non-transparent pixels are within the isometric diamond."""
    h, w = data.shape[:2]
    
    y, x = np.mgrid[0:h, 0:w]
    in_diamond = (np.abs(x - 32) / 32 + np.abs(y - 16) / 16) <= 1.0
    
    alpha = data[:, :, 3]
    outside_diamond = (~in_diamond) & (alpha > 0)
    if np.any(outside_diamond):
        coords = np.where(outside_diamond)
        for y, x in zip(coords[0][:5], coords[1][:5]):
            return [f"Non-transparent pixel outside diamond at ({x}, {y})"]
    
    return []


def check_palette(data: np.ndarray) -> list[str]:
    for y in range(data.shape[0]):
        for x in range(data.shape[1]):
            r, g, b, a = data[y, x]
            if a == 0:
                continue
            color_hex = f"#{r:02x}{g:02x}{b:02x}".lower()
            if color_hex not in ALLOWED_COLORS:
                return [f"Disallowed color {color_hex} at ({x}, {y})"]
    return []


def check_alpha_mask(data: np.ndarray) -> list[str]:
    alpha = data[:, :, 3]
    semi_transparent = (alpha > 0) & (alpha < 255)
    if np.any(semi_transparent):
        coords = np.where(semi_transparent)
        for y, x in zip(coords[0][:3], coords[1][:3]):
            return [f"Semi-transparent pixel at ({x}, {y}) - use binary alpha"]
    return []


def extract_tile_id(path: Path) -> int | None:
    match = re.search(r'_(\d{3})', path.stem)
    if match:
        return int(match.group(1))
    match = re.search(r'(\d{3})', path.stem)
    if match:
        return int(match.group(1))
    return None


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_tiles.py <input_dir> [--theme THEME] [--manifest MANIFEST]")
        return 1
    
    input_dir = Path(sys.argv[1])
    theme = ""
    manifest_path = None
    
    for i, arg in enumerate(sys.argv):
        if arg == "--theme" and i + 1 < len(sys.argv):
            theme = sys.argv[i + 1]
        elif arg == "--manifest" and i + 1 < len(sys.argv):
            manifest_path = Path(sys.argv[i + 1])
    
    if not input_dir.exists():
        print(f"Input directory not found: {input_dir}")
        return 1
    
    errors = []
    for img_file in input_dir.rglob("*.png"):
        errs = validate_tile(img_file, "")
        if errs:
            for err in errs:
                print(f"❌ {img_file.name}: {err}")
    
    if errors:
        print(f"\n❌ Total errors: {len(errors)}")
        return 1
    else:
        print("✅ All tiles valid")
        return 0


if __name__ == "__main__":
    sys.exit(main())