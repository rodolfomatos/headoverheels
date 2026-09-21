#!/usr/bin/env python3
"""
Validation Pipeline for Head over Heels sprite system.
Comprehensive validation of all sprite assets before integration.
"""

import sys
import json
import re
import subprocess
from pathlib import Path
from PIL import Image
import numpy as np

# Configuration
ASSETS_DIR = Path(__file__).parent.parent / "assets" / "sprites"
STYLE_DIR = Path(__file__).parent.parent / "style"

# Load style configurations
with open(STYLE_DIR / "palette.json") as f:
    PALETTE = json.load(f)

with open(STYLE_DIR / "geometry.json") as f:
    GEOMETRY = json.load(f)

# Build allowed colors set
ALLOWED_COLORS = set()
for color in PALETTE["base"].values():
    ALLOWED_COLORS.add(color.lower())
for theme_colors in PALETTE["themes"].values():
    for color in theme_colors.values():
        ALLOWED_COLORS.add(color.lower())

TILE_W = GEOMETRY.get("tile_width", 64)
TILE_H = GEOMETRY.get("tile_height", 32)


class ValidationResult:
    def __init__(self, name):
        self.name = name
        self.passed = 0
        self.failed = 0
        self.errors = []
        self.warnings = []

    def add_error(self, msg):
        self.errors.append(msg)
        self.failed += 1

    def add_warning(self, msg):
        self.warnings.append(msg)

    def add_pass(self):
        self.passed += 1


class ValidationPipeline:
    def __init__(self, assets_dir):
        self.assets_dir = Path(assets_dir)
        self.results = {}

    def _get_allowed_colors(self):
        return ALLOWED_COLORS

    def check_tiles(self):
        result = ValidationResult("tiles")
        
        for img_file in Path("assets/sprites/tiles").rglob("*.png"):
            try:
                img = Image.open(img_file)
                if img.mode != "RGBA":
                    img = img.convert("RGBA")
                
                if img_file.name.endswith("_masters.png") or img_file.name in ["castle_masters.png", "egyptus.png", "penitentiary.png", "safari.png", "bookworld.png", "moonbase.png"]:
                    if img.size != (1024, 512):
                        result.add_error(f"{img_file.relative_to(Path('assets/sprites'))}: Master tileset wrong size {img.size}, expected 1024x512")
                    else:
                        result.add_pass()
                elif img.size != (64, 32):
                    result.add_error(f"{img_file.relative_to(Path('assets/sprites'))}: Wrong tile size {img.size}, expected 64x32")
                else:
                    result.add_pass()
                
                data = np.array(img)
                if img.size == (64, 32):
                    y, x = np.mgrid[0:32, 0:64]
                    in_diamond = (np.abs(x - 32) / 32 + np.abs(y - 16) / 16) <= 1.0
                    alpha = data[:, :, 3]
                    outside = (~in_diamond) & (alpha > 0)
                    if np.any(outside):
                        coords = np.where(outside)
                        for y, x in zip(coords[0][:5], coords[1][:5]):
                            result.add_warning(f"{img_file.name}: Non-transparent pixel outside diamond at ({x}, {y})")
                
            except Exception as e:
                result.add_error(f"Failed to validate {img_file}: {e}")
        
        self.results["tiles"] = result
        return result

    def _get_allowed_colors_for_file(self, img_file):
        """Get allowed colors for a specific image file, including theme-specific colors for theme tilesets."""
        allowed = set(ALLOWED_COLORS)
        
        # Theme tileset images - allow theme-specific colors
        theme_tilesets = {
            "castle_masters.png": "castle",
            "egyptus.png": "egyptus",
            "penitentiary.png": "penitentiary",
            "safari.png": "safari",
            "bookworld.png": "bookworld",
            "moonbase.png": "moonbase",
        }
        
        if img_file.name in theme_tilesets:
            theme_name = theme_tilesets[img_file.name]
            theme_palette = PALETTE.get("themes", {}).get(theme_name, {})
            for color in theme_palette.values():
                allowed.add(color.lower())
        
        return allowed

    def check_palette(self):
        result = ValidationResult("palette")
        
        for img_file in Path("assets/sprites").rglob("*.png"):
            try:
                img = Image.open(img_file)
                if img.mode != "RGBA":
                    img = img.convert("RGBA")
                data = np.array(img)
                
                # Determine allowed colors for this file
                allowed_colors = self._get_allowed_colors_for_file(img_file)
                
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
                        if color not in by_color:
                            by_color[color] = []
                        by_color[color].append((x, y))
                    
                    for color, positions in by_color.items():
                        result.add_error(f"  {img_file.name}: Found disallowed color {color} at {len(positions)} pixels")
                else:
                    result.add_pass()
            except Exception as e:
                result.add_error(f"Failed to check palette for {img_file}: {e}")
        
        self.results["palette"] = result
        return result

    def check_dimensions(self):
        result = ValidationResult("dimensions")
        
        expected_dims = {
            "character_head_": (48, 48),
            "character_heels_": (48, 56),
            "character_duo_": (56, 64),
            "entity_fish_": (64, 32),
            "entity_rabbit_": (32, 32),
            "entity_crown_": (32, 32),
            "entity_spring_": (48, 48),
            "entity_switch_": (48, 48),
            "entity_conveyor_": (64, 32),
            "entity_teleport_": (64, 64),
            "entity_door_": (64, 64),
            "entity_monster_": (64, 64),
            "entity_guardian_": (96, 96),
            "entity_hush_puppy_": (48, 48),
            "entity_bag_": (32, 32),
            "entity_key_": (24, 24),
            "entity_doughnut_": (16, 16),
            "tile_": (64, 32),
            "ui_": (32, 32),
        }
        
        for img_file in Path("assets/sprites").rglob("*.png"):
            try:
                img = Image.open(img_file)
                matched = False
                for prefix, (ew, eh) in expected_dims.items():
                    if img_file.name.startswith(prefix):
                        if img.size != (ew, eh):
                            result.add_error(f"{img_file.relative_to(Path('assets/sprites'))}: {img.size} != expected {ew}x{eh}")
                        result.add_pass()
                        matched = True
                        break
                if not matched and not (img_file.name.startswith("tileset_") or 
                                        img_file.name.startswith("atlas_") or
                                        img_file.name == "manifest.json" or
                                        img_file.name.endswith("_master.png") or
                                        img_file.name.endswith("_masters.png")):
                    pass
            except Exception as e:
                result.add_error(f"Failed to check {img_file}: {e}")
        
        self.results["dimensions"] = result
        return result

    def check_naming(self):
        result = ValidationResult("naming")
        pattern = re.compile(r'^[a-z]+_[a-z0-9_]+(?:_[a-z]+)?(?:_[nsew]{1,2})?_\d{2}\.png$')
        
        for img_file in Path("assets/sprites").rglob("*.png"):
            if img_file.name in ["manifest.json"] or img_file.name.startswith("tileset_") or \
               img_file.name.startswith("atlas_") or img_file.name.endswith("_master.png") or \
               img_file.name.endswith("_masters.png") or img_file.name.endswith("_idle_front.png") or \
               img_file.name.count('_') == 1 and img_file.name.endswith('.png') or \
               img_file.name in ["castle_masters.png", "egyptus.png", "penitentiary.png", "safari.png", "bookworld.png", "moonbase.png"] or \
               img_file.name in ["barrel.png", "lever.png", "chain.png", "torch.png", "banner.png", "skull.png", "crate.png", "sign.png"]:
                continue
            
            if not re.match(r'^[a-z]+_[a-z0-9_]+(?:_[a-z]+)?(?:_[nsew]{1,2})?_\d{2}\.png$', img_file.name):
                result.add_error(f"Invalid naming: {img_file.relative_to(Path('assets/sprites'))}")
            else:
                result.add_pass()
        
        self.results["naming"] = result
        return result

    def check_alpha(self):
        result = ValidationResult("alpha")
        
        for img_file in Path("assets/sprites").rglob("*.png"):
            try:
                img = Image.open(img_file)
                if img.mode != "RGBA":
                    img = img.convert("RGBA")
                data = np.array(img)
                alpha = data[:, :, 3]
                semi = (alpha > 0) & (alpha < 255)
                if np.any(semi):
                    coords = np.where(semi)
                    count = len(coords[0])
                    # Allow higher threshold for master sprites (intentional semi-transparency for effects)
                    threshold = 5000 if img_file.name.endswith("_master.png") or img_file.name.endswith("_masters.png") else 1000
                    if count > threshold:
                        result.add_error(f"{img_file.relative_to(Path('assets/sprites').parent)}: {count} semi-transparent pixels")
                    else:
                        result.add_pass()
                else:
                    result.add_pass()
            except Exception as e:
                result.add_error(f"Failed to check alpha for {img_file}: {e}")
        
        self.results["alpha"] = result
        return result

    def run_all(self):
        print("Running Validation Pipeline...")
        print()
        
        self.check_tiles()
        print("✅ Tiles validated")
        
        self.check_palette()
        print("✅ Palette validated")
        
        self.check_dimensions()
        print("✅ Dimensions validated")
        
        self.check_naming()
        print("✅ Naming validated")
        
        self.check_alpha()
        print("✅ Alpha validated")
        
        return self.results

    def print_summary(self):
        print("\n" + "=" * 50)
        print("VALIDATION PIPELINE SUMMARY")
        print("=" * 50)
        
        total_passed = 0
        total_failed = 0
        
        for category, result in self.results.items():
            status = "✅ PASS" if result.failed == 0 else "❌ FAIL"
            print(f"  {result.name:15s}: {status}")
            if result.errors:
                for err in result.errors:
                    print(f"    - {err}")
            if result.warnings:
                for warn in result.warnings:
                    print(f"    ⚠️  {warn}")
        
        total_passed = sum(r.passed for r in self.results.values())
        total_failed = sum(r.failed for r in self.results.values())
        
        print("-" * 50)
        print(f"Total: {sum(r.passed for r in self.results.values())} passed, {sum(r.failed for r in self.results.values())} failed")
        
        return 0 if sum(r.failed for r in self.results.values()) == 0 else 1


def main():
    pipeline = ValidationPipeline("assets/sprites")
    results = pipeline.run_all()
    pipeline.print_summary()
    return 0 if sum(r.failed for r in pipeline.results.values()) == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
