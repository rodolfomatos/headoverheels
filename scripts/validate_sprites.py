#!/usr/bin/env python3
"""
Master validation script for all sprites.
Metadata-driven via assets/sprites/manifest.yaml.
Reconciled with 2026 Visual Design System.
"""

import sys
import json
import yaml
from pathlib import Path
from PIL import Image
import numpy as np

SCRIPTS_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPTS_DIR.parent
ASSETS_DIR = PROJECT_ROOT / "assets" / "sprites"
MANIFEST_PATH = ASSETS_DIR / "manifest.yaml"
STYLE_DIR = PROJECT_ROOT / "style"

# Load palettes
with open(STYLE_DIR / "palette.json") as f:
    PALETTE_DATA = json.load(f)

with open(STYLE_DIR / "geometry.json") as f:
    GEOMETRY = json.load(f)

# Build allowed colors per palette
BASE_COLORS = set(c.lower() for c in PALETTE_DATA["base"].values())
THEME_COLORS = {}
for theme, colors in PALETTE_DATA["themes"].items():
    THEME_COLORS[theme] = set(c.lower() for c in colors.values())

TILE_W = GEOMETRY["tile_geometry"]["logical_width"]
TILE_H = GEOMETRY["tile_geometry"]["logical_height"]


def load_manifest():
    """Load asset manifest."""
    if not MANIFEST_PATH.exists():
        print(f"Manifest not found: {MANIFEST_PATH}")
        return []
    with open(MANIFEST_PATH) as f:
        data = yaml.safe_load(f)
    return data.get("assets", [])


def get_allowed_colors(palette_name: str) -> set:
    """Get allowed colors for a palette."""
    colors = set(BASE_COLORS)
    if palette_name in THEME_COLORS:
        colors.update(THEME_COLORS[palette_name])
    if palette_name == "extended":
        colors.update(THEME_COLORS.get("extended", set()))
    return colors


def validate_tiles(assets) -> list[str]:
    """Validate tile geometry."""
    errors = []
    for asset in assets:
        if asset.get("category") != "tile":
            continue
        file_path = ASSETS_DIR / asset["file"]
        if not file_path.exists():
            errors.append(f"Tile file not found: {asset['file']}")
            continue
        try:
            img = Image.open(file_path)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            # Check dimensions
            expected = (asset["runtime_size"]["width"], asset["runtime_size"]["height"])
            if img.size != expected:
                errors.append(f"{asset['file']}: {img.size} != expected {expected}")
            # Check diamond mask for 64x32 tiles
            if img.size == (64, 32):
                data = np.array(img)
                y, x = np.mgrid[0:32, 0:64]
                in_diamond = (np.abs(x - 32) / 32 + np.abs(y - 16) / 16) <= 1.0
                alpha = data[:, :, 3]
                outside = (~in_diamond) & (alpha > 0)
                if np.any(outside):
                    coords = np.where(outside)
                    for y, x in zip(coords[0][:5], coords[1][:5]):
                        errors.append(f"{asset['file']}: Non-transparent pixel outside diamond at ({x}, {y})")
        except Exception as e:
            errors.append(f"Failed to validate tile {asset['file']}: {e}")
    return errors


def validate_palette(assets) -> list[str]:
    """Validate palette per asset's declared palette."""
    errors = []
    for asset in assets:
        file_path = ASSETS_DIR / asset["file"]
        if not file_path.exists():
            continue
        try:
            img = Image.open(file_path)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            data = np.array(img)
            
            allowed = get_allowed_colors(asset.get("palette", "base"))
            
            violations = []
            for y in range(data.shape[0]):
                for x in range(data.shape[1]):
                    r, g, b, a = data[y, x]
                    if a == 0:
                        continue
                    color_hex = f"#{r:02x}{g:02x}{b:02x}".lower()
                    if color_hex not in allowed:
                        violations.append((x, y, color_hex))
            
            if violations:
                by_color = {}
                for x, y, color in violations:
                    by_color.setdefault(color, []).append((x, y))
                for color, positions in by_color.items():
                    errors.append(f"{asset['file']}: Disallowed color {color} at {len(positions)} pixels (palette: {asset.get('palette', 'base')})")
        except Exception as e:
            errors.append(f"Failed to check palette for {asset['file']}: {e}")
    return errors


def validate_dimensions(assets) -> list[str]:
    """Validate dimensions match manifest."""
    errors = []
    for asset in assets:
        file_path = ASSETS_DIR / asset["file"]
        if not file_path.exists():
            continue
        try:
            img = Image.open(file_path)
            expected = (asset["runtime_size"]["width"], asset["runtime_size"]["height"])
            if img.size != expected:
                errors.append(f"{asset['file']}: {img.size} != expected {expected} (from manifest)")
        except Exception as e:
            errors.append(f"Failed to check dimensions for {asset['file']}: {e}")
    return errors


def validate_naming(assets) -> list[str]:
    """Validate naming convention."""
    import re
    errors = []
    # Physical filename pattern
    pattern = re.compile(r'^[a-z]+_[a-z0-9_]+(?:_[a-z]+)?(?:_[nsew]{1,2})?_\d{2}\.png$')
    # Asset ID pattern
    id_pattern = re.compile(r'^(character|entity|tile|ui|fx)\.[a-z0-9_]+\.[a-z0-9_]+(\.[a-z0-9_]+)?$')
    
    for asset in assets:
        # Check physical filename
        filename = Path(asset["file"]).name
        if filename.endswith('_master.png') or filename.endswith('_masters.png') or \
           filename.startswith('tileset_') or filename.startswith('atlas_') or \
           filename in ['safari.png', 'egyptus.png', 'moonbase.png', 'bookworld.png', 'penitentiary.png', 'castle_masters.png'] or \
           filename in ['barrel.png', 'lever.png', 'chain.png', 'torch.png', 'banner.png', 'skull.png', 'crate.png', 'sign.png', 'pressure_plate.png']:
            pass  # Known exceptions
        elif not pattern.match(filename):
            errors.append(f"Invalid physical filename: {filename}")
        
        # Check Asset ID format
        asset_id = asset.get("id", "")
        if asset_id and not id_pattern.match(asset_id):
            errors.append(f"Invalid Asset ID format: {asset_id}")
    return errors


def validate_alpha(assets) -> list[str]:
    """Validate alpha channel per asset's declared mode."""
    errors = []
    for asset in assets:
        file_path = ASSETS_DIR / asset["file"]
        if not file_path.exists():
            continue
        try:
            # Skip master sprite sheets
            if asset["file"].endswith('_master.png') or asset["file"].endswith('_idle_front.png'):
                continue
            img = Image.open(file_path)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            data = np.array(img)
            alpha = data[:, :, 3]
            
            alpha_mode = asset.get("alpha", "opaque")
            
            if alpha_mode == "opaque":
                semi = (alpha > 0) & (alpha < 255)
                if np.any(semi):
                    coords = np.where(semi)
                    count = len(coords[0])
                    if count > 100:
                        errors.append(f"{asset['file']}: {count} semi-transparent pixels (alpha mode: opaque)")
            elif alpha_mode == "binary":
                # Allow 0, 128, 255
                invalid = (alpha > 0) & (alpha < 255) & (alpha != 128)
                if np.any(invalid):
                    coords = np.where(invalid)
                    count = len(coords[0])
                    if count > 100:
                        errors.append(f"{asset['file']}: {count} non-binary alpha pixels (alpha mode: binary)")
            elif alpha_mode == "smooth":
                # Any alpha allowed
                pass
        except Exception as e:
            errors.append(f"Failed to check alpha for {asset['file']}: {e}")
    return errors


def validate_animations(assets) -> list[str]:
    """Validate animation consistency (baseline, anchor, scale)."""
    errors = []
    # Group by animation
    anims = {}
    for asset in assets:
        if asset.get("category") == "character":
            key = (asset.get("character"), asset.get("animation"), asset.get("direction"))
            anims.setdefault(key, []).append(asset)
    
    for key, frames in anims.items():
        if len(frames) < 2:
            continue
        # Check anchor consistency
        anchors = [f["anchor"] for f in frames]
        if len(set((a["x"], a["y"]) for a in anchors)) > 1:
            errors.append(f"Animation {key}: inconsistent anchors {anchors}")
        # Check runtime size consistency
        sizes = [(f["runtime_size"]["width"], f["runtime_size"]["height"]) for f in frames]
        if len(set(sizes)) > 1:
            errors.append(f"Animation {key}: inconsistent sizes {sizes}")
    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_sprites.py <assets_dir> [--strict]")
        return 1
    
    assets_dir = Path(sys.argv[1])
    if not assets_dir.exists():
        print(f"Assets directory not found: {assets_dir}")
        return 1
    
    # Load manifest
    assets = load_manifest()
    if not assets:
        print("No assets in manifest or manifest not found")
        return 1
    
    print("🔍 Running metadata-driven sprite validation...\n")
    
    all_errors = {}
    
    # 1. Tiles
    print("📐 Validating tiles...")
    tile_errors = validate_tiles(assets)
    all_errors["tiles"] = tile_errors
    print(f"  {'✅' if not tile_errors else '❌'} Tiles: {len(tile_errors)} errors")
    
    # 2. Palette
    print("🎨 Validating palette...")
    palette_errors = validate_palette(assets)
    all_errors["palette"] = palette_errors
    print(f"  {'✅' if not palette_errors else '❌'} Palette: {len(palette_errors)} errors")
    
    # 3. Dimensions
    print("📏 Validating dimensions...")
    dim_errors = validate_dimensions(assets)
    all_errors["dimensions"] = dim_errors
    print(f"  {'✅' if not dim_errors else '❌'} Dimensions: {len(dim_errors)} errors")
    
    # 4. Naming
    print("📝 Validating naming...")
    naming_errors = validate_naming(assets)
    all_errors["naming"] = naming_errors
    print(f"  {'✅' if not naming_errors else '❌'} Naming: {len(naming_errors)} errors")
    
    # 5. Alpha
    print("🔍 Validating alpha...")
    alpha_errors = validate_alpha(assets)
    all_errors["alpha"] = alpha_errors
    print(f"  {'✅' if not alpha_errors else '❌'} Alpha: {len(alpha_errors)} errors")
    
    # 6. Animations
    print("🎬 Validating animations...")
    anim_errors = validate_animations(assets)
    all_errors["animations"] = anim_errors
    print(f"  {'✅' if not anim_errors else '❌'} Animations: {len(anim_errors)} errors")
    
    # Summary
    print("\n" + "=" * 50)
    print("SPRITE VALIDATION SUMMARY")
    print("=" * 50)
    
    total_errors = sum(len(e) for e in all_errors.values())
    
    for category, errors in all_errors.items():
        status = "✅ PASS" if not errors else "❌ FAIL"
        print(f"  {category:15s}: {status}")
        for err in errors:
            print(f"    - {err}")
    
    print("-" * 50)
    print(f"Total errors: {total_errors}")
    
    if total_errors > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())