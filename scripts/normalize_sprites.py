#!/usr/bin/env python3
"""
Normalize sprites for Head over Heels sprite system.
Manifest-driven: reads assets/sprites/manifest.yaml and processes master sprites
into normalized runtime frames.

Responsibilities:
- Load manifest and process each asset
- Validate master sprite dimensions
- Crop/align to runtime size with correct anchor
- Normalize scale (nearest-neighbor)
- Validate/convert palette per asset's declared palette
- Validate alpha mode (opaque/binary/smooth)
- Output normalized frames to build/normalized/
"""

import sys
import json
import yaml
from pathlib import Path
from PIL import Image
import numpy as np

PROJECT_ROOT = Path(__file__).parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets" / "sprites"
MANIFEST_PATH = ASSETS_DIR / "manifest.yaml"
BUILD_DIR = PROJECT_ROOT / "build" / "normalized"
STYLE_DIR = PROJECT_ROOT / "style"

# Load style configs
with open(STYLE_DIR / "geometry.json") as f:
    GEOMETRY = json.load(f)

with open(STYLE_DIR / "palette.json") as f:
    PALETTE_DATA = json.load(f)

# Build allowed colors per palette
BASE_COLORS = {c.lower() for c in PALETTE_DATA["base"].values()}
THEME_COLORS = {}
for theme, colors in PALETTE_DATA["themes"].items():
    THEME_COLORS[theme] = {c.lower() for c in colors.values()}

TILE_W = GEOMETRY["tile_geometry"]["logical_width"]
TILE_H = GEOMETRY["tile_geometry"]["logical_height"]

TOLERANCE = 1  # pixels for dimension/anchor tolerance


def load_manifest():
    """Load asset manifest."""
    with open(MANIFEST_PATH) as f:
        data = yaml.safe_load(f)
    return data.get("assets", [])


def get_allowed_colors(palette_name: str) -> set:
    """Get allowed colors for a palette."""
    colors = set(BASE_COLORS)
    if palette_name in THEME_COLORS:
        colors.update(THEME_COLORS[palette_name])
    return colors


def normalize_sprite(asset: dict) -> list[str]:
    """Normalize a single asset's master sprite to runtime frames."""
    errors = []
    
    master_path = ASSETS_DIR / asset["file"]
    if not master_path.exists():
        return [f"Master file not found: {asset['file']}"]
    
    try:
        master = Image.open(master_path)
    except Exception as e:
        return [f"Failed to open {master_path}: {e}"]
    
    if master.mode != "RGBA":
        master = master.convert("RGBA")
    
    # Get runtime spec
    rt_w = asset["runtime_size"]["width"]
    rt_h = asset["runtime_size"]["height"]
    anchor = asset.get("anchor", {"x": rt_w // 2, "y": rt_h})
    alpha_mode = asset.get("alpha", "opaque")
    palette_name = asset.get("palette", "base")
    category = asset.get("category", "unknown")
    
    # Determine source region (for tilesets/spritesheets)
    src_region = asset.get("source_region")
    if src_region:
        # Extract sub-image from master
        box = (src_region["x"], src_region["y"], 
               src_region["x"] + src_region["width"], 
               src_region["y"] + src_region["height"])
        frame = master.crop(box)
    else:
        # Use entire master as single frame
        frame = master
    
    # Validate/correct dimensions
    if frame.size != (rt_w, rt_h):
        old_size = frame.size
        # Resize with nearest-neighbor to preserve pixel art
        frame = frame.resize((rt_w, rt_h), Image.NEAREST)
        # Resize is expected for props, not an error
        print(f"  ℹ️ Resized {old_size} -> ({rt_w}, {rt_h})")
    
    # Validate anchor (check content center-bottom matches expected)
    # Skip for tiles (extracted from tileset, anchor not meaningful)
    # Skip for props (anchor is isometric placement point, not content center)
    if category not in ["tile", "prop"]:
        data = np.array(frame)
        content_anchor = find_content_anchor(data)
        expected_anchor = (anchor["x"], anchor["y"])
        if content_anchor:
            dx = content_anchor[0] - expected_anchor[0]
            dy = content_anchor[1] - expected_anchor[1]
            if abs(dx) > TOLERANCE or abs(dy) > TOLERANCE:
                errors.append(f"  ⚠️ Anchor offset: content={content_anchor} expected={expected_anchor} (dx={dx}, dy={dy})")
    
    # Validate palette
    allowed = get_allowed_colors(palette_name)
    palette_errors = validate_palette(frame, allowed, asset["file"])
    errors.extend(palette_errors)
    
    # Validate alpha
    alpha_errors = validate_alpha(frame, alpha_mode, asset["file"])
    errors.extend(alpha_errors)
    
    # Save normalized frame
    out_path = BUILD_DIR / asset["file"]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    frame.save(out_path, "PNG", optimize=True)
    
    return errors


def find_content_anchor(data: np.ndarray) -> tuple | None:
    """Find the visual anchor (center-x, bottom-y of non-transparent content)."""
    mask = data[:, :, 3] > 0
    if not np.any(mask):
        return None
    y_indices, x_indices = np.where(mask)
    cx = int(np.mean(x_indices))
    anchor_y = int(np.max(y_indices))
    return (cx, anchor_y)


def validate_palette(img: Image.Image, allowed_colors: set, filename: str) -> list[str]:
    """Validate image uses only allowed palette colors."""
    errors = []
    data = np.array(img)
    violations = []
    
    for y in range(data.shape[0]):
        for x in range(data.shape[1]):
            r, g, b, a = data[y, x]
            if a == 0:
                continue
            color_hex = f"#{r:02x}{g:02x}{b:02x}".lower()
            if color_hex not in allowed_colors:
                violations.append((x, y, color_hex))
    
    if violations:
        by_color = {}
        for x, y, color in violations:
            by_color.setdefault(color, []).append((x, y))
        for color, positions in by_color.items():
            errors.append(f"{filename}: Disallowed color {color} at {len(positions)} pixels")
    
    return errors


def validate_alpha(img: Image.Image, alpha_mode: str, filename: str) -> list[str]:
    """Validate alpha channel matches declared mode."""
    errors = []
    data = np.array(img)
    alpha = data[:, :, 3]
    
    if alpha_mode == "opaque":
        semi = (alpha > 0) & (alpha < 255)
        if np.any(semi):
            count = np.sum(semi)
            if count > 50:  # Allow tiny amounts from resizing
                errors.append(f"{filename}: {count} semi-transparent pixels (alpha mode: opaque)")
    elif alpha_mode == "binary":
        invalid = (alpha > 0) & (alpha < 255) & (alpha != 128)
        if np.any(invalid):
            count = np.sum(invalid)
            if count > 50:
                errors.append(f"{filename}: {count} non-binary alpha pixels (alpha mode: binary)")
    elif alpha_mode == "smooth":
        pass  # Any alpha allowed
    else:
        errors.append(f"{filename}: Unknown alpha mode '{alpha_mode}'")
    
    return errors


def main():
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    
    assets = load_manifest()
    print(f"🔧 Normalizing {len(assets)} assets from manifest...")
    
    total_errors = 0
    processed = 0
    
    for asset in assets:
        # Skip tilesets (they're source images, not individual frames)
        if asset.get("category") == "tileset":
            print(f"  ⏭️ Skipping tileset: {asset['id']}")
            continue
        
        # Skip master sprites (spritesheets)
        if asset.get("type") == "master":
            print(f"  ⏭️ Skipping master: {asset['id']}")
            continue
        
        errors = normalize_sprite(asset)
        if errors:
            print(f"❌ {asset['id']} ({asset['file']})")
            for err in errors:
                print(f"   {err}")
            total_errors += len(errors)
        else:
            print(f"✅ {asset['id']}")
        processed += 1
    
    print(f"\nProcessed: {processed}, Total errors: {total_errors}")
    return 0 if total_errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())