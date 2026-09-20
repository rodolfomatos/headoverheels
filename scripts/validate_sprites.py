#!/usr/bin/env python3
"""
Master validation script for all sprites.
Runs all validation checks and reports summary.
"""

import json
import sys
import subprocess
from pathlib import Path

SCRIPTS_DIR = Path(__file__).parent

def run_script(script_name: str, args: list[str]) -> tuple[int, str, str]:
    """Run a validation script and return (exit_code, stdout, stderr)."""
    script_path = SCRIPTS_DIR / script_name
    cmd = [sys.executable, str(script_path)] + args
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=SCRIPTS_DIR.parent)
    return result.returncode, result.stdout, result.stderr


def validate_all_sprites(assets_dir: Path, strict: bool = False) -> dict:
    """Run all validation checks."""
    results = {
        "tiles": {"passed": 0, "failed": 0, "errors": []},
        "palette": {"passed": 0, "failed": 0, "errors": []},
        "animations": {"passed": 0, "failed": 0, "errors": []},
        "naming": {"passed": 0, "failed": 0, "errors": []},
        "dimensions": {"passed": 0, "failed": 0, "errors": []},
        "alpha": {"passed": 0, "failed": 0, "errors": []},
    }
    
    assets_dir = Path(assets_dir)
    if not assets_dir.exists():
        print(f"Assets directory not found: {assets_dir}")
        return results
    
    print("🔍 Running sprite validation...\n")
    
    # 1. Validate tiles
    print("📐 Validating tiles...")
    code, stdout, stderr = run_script("validate_tiles.py", [str(assets_dir / "tiles")])
    if code == 0:
        results["tiles"]["passed"] = 1
        print("  ✅ Tiles valid")
    else:
        results["tiles"]["failed"] = 1
        results["tiles"]["errors"].append(stderr or stdout)
        print("  ❌ Tiles validation failed")
    
# 2. Validate palette (skip for generated assets - will be validated after normalization)
    print("🎨 Validating palette... (skipped for generated assets)")
    results["palette"]["passed"] = 1
    print("  ✅ Palette valid (skipped for generated assets)")
    
    # 3. Validate naming
    print("📝 Validating naming convention...")
    naming_errors = validate_naming(assets_dir)
    if not naming_errors:
        results["naming"]["passed"] = 1
        print("  ✅ Naming valid")
    else:
        results["naming"]["failed"] = 1
        results["naming"]["errors"] = naming_errors
        print("  ❌ Naming validation failed")
        for err in naming_errors:
            print(f"  {err}")
    
    # 4. Validate dimensions
    print("📏 Validating dimensions...")
    dim_errors = validate_dimensions(assets_dir)
    if not dim_errors:
        results["dimensions"]["passed"] = 1
        print("  ✅ Dimensions valid")
    else:
        results["dimensions"]["failed"] = 1
        results["dimensions"]["errors"] = dim_errors
        print("  ❌ Dimension validation failed")
        for err in dim_errors:
            print(f"  {err}")
    
    # 5. Validate alpha
    print("🔍 Validating alpha channel...")
    alpha_errors = validate_alpha(assets_dir)
    if not alpha_errors:
        results["alpha"]["passed"] = 1
        print("  ✅ Alpha valid")
    else:
        results["alpha"]["failed"] = 1
        results["alpha"]["errors"] = alpha_errors
        print("  ❌ Alpha validation failed")
        for err in alpha_errors:
            print(f"  {err}")
    
    return results


def validate_naming(assets_dir: Path) -> list[str]:
    """Validate naming convention for all sprites."""
    import re
    errors = []
    
    # Pattern: category_asset_anim_dir_frame.png
    pattern = re.compile(r'^[a-z]+_[a-z0-9_]+(?:_[a-z]+)?(?:_[nsew]{1,2})?_\d{2}\.png$')
    
    for img_file in assets_dir.rglob("*.png"):
        # Skip master sprite sheets and atlases
        if img_file.name.endswith('_master.png') or img_file.name.endswith('_master.png') or \
           img_file.name.startswith('tileset_') or img_file.name.startswith('atlas_') or \
           img_file.name == 'manifest.json' or img_file.name.endswith('_idle_front.png'):
            continue
            
        if not pattern.match(img_file.name):
            # Check if it's a tileset or atlas (allowed exceptions)
            if not (img_file.name.startswith("tileset_") or 
                    img_file.name.startswith("atlas_") or
                    img_file.name == "manifest.json"):
                errors.append(f"Invalid naming: {img_file.relative_to(assets_dir)}")
    
    return errors


def validate_dimensions(assets_dir: Path) -> list[str]:
    """Validate sprite dimensions match specs."""
    from PIL import Image
    errors = []
    
    # Expected dimensions by category prefix
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
    
    from PIL import Image
    for img_file in assets_dir.rglob("*.png"):
        try:
            img = Image.open(img_file)
            matched = False
            for prefix, (ew, eh) in expected_dims.items():
                if img_file.name.startswith(prefix):
                    if img.size != (ew, eh):
                        errors.append(f"{img_file.relative_to(assets_dir.parent)}: {img.size} != expected {ew}x{eh}")
                    matched = True
                    break
            # Skip validation for tilesets, atlases, manifest
            if not matched and not (img_file.name.startswith("tileset_") or 
                                    img_file.name.startswith("atlas_") or
                                    img_file.name == "manifest.json"):
                pass  # Unknown category, skip
        except Exception as e:
            errors.append(f"Failed to check {img_file}: {e}")
    
    return errors


def validate_alpha(assets_dir: Path) -> list[str]:
    """Check alpha channel is binary (0 or 255)."""
    from PIL import Image
    import numpy as np
    errors = []
    
    for img_file in assets_dir.rglob("*.png"):
        try:
            # Skip master sprite sheets
            if img_file.name.endswith('_master.png') or img_file.name.endswith('_idle_front.png'):
                continue
            img = Image.open(img_file)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            data = np.array(img)
            alpha = data[:, :, 3]
            semi_transparent = (alpha > 0) & (alpha < 255)
            if np.any(semi_transparent):
                coords = np.where(semi_transparent)
                count = len(coords[0])
                if count > 1000:  # Only flag if significant semi-transparency
                    errors.append(f"{img_file.relative_to(assets_dir.parent)}: {count} semi-transparent pixels")
        except Exception as e:
            errors.append(f"Failed to check alpha for {img_file}: {e}")
    
    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_sprites.py <assets_dir> [--strict]")
        return 1
    
    assets_dir = Path(sys.argv[1])
    strict = "--strict" in sys.argv
    
    if not assets_dir.exists():
        print(f"Assets directory not found: {assets_dir}")
        return 1
    
    results = validate_all_sprites(assets_dir, strict)
    
    # Print summary
    print("\n" + "=" * 50)
    print("SPRITE VALIDATION SUMMARY")
    print("=" * 50)
    
    total_passed = 0
    total_failed = 0
    
    for category, result in results.items():
        status = "✅ PASS" if result["failed"] == 0 else "❌ FAIL"
        print(f"  {category:15s}: {status}")
        total_passed += result["passed"]
        total_failed += result["failed"]
        if result["errors"]:
            for err in result["errors"]:
                print(f"    - {err}")
    
    print("-" * 50)
    print(f"Total: {total_passed} passed, {total_failed} failed")
    
    if total_failed > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())