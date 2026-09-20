#!/usr/bin/env python3
"""
Validate sprite palettes against the defined Spectrum+ palette.
"""

import json
import sys
from pathlib import Path
from PIL import Image

STYLE_DIR = Path(__file__).parent.parent / "style"
with open(STYLE_DIR / "palette.json") as f:
    PALETTE = json.load(f)

# Build allowed color set
ALLOWED_COLORS = set()
for color in PALETTE["base"].values():
    ALLOWED_COLORS.add(color.lower())
for theme_colors in PALETTE["themes"].values():
    for color in theme_colors.values():
        ALLOWED_COLORS.add(color.lower())

# Also add base 16 colors for strict mode
STRICT_COLORS = set(PALETTE["base"].values())
for theme_colors in PALETTE["themes"].values():
    for color in theme_colors.values():
        STRICT_COLORS.add(color.lower())


def validate_palette(img_path: Path, strict: bool = False) -> list[str]:
    """Validate a single image's palette."""
    errors = []
    
    try:
        img = Image.open(img_path)
    except Exception as e:
        return [f"Failed to open {img_path}: {e}"]
    
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    data = np.array(img)
    height, width = data.shape[:2]
    
    allowed = STRICT_COLORS if strict else ALLOWED_COLORS
    violations = []
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = data[y, x]
            if a == 0:
                continue
            color_hex = f"#{r:02x}{g:02x}{b:02x}".lower()
            if color_hex not in allowed:
                violations.append((x, y, color_hex))
    
    if violations:
        # Group by color
        by_color = {}
        for x, y, color in violations:
            if color not in by_color:
                by_color[color] = []
            by_color[color].append((x, y))
        
        for color, positions in by_color.items():
            errors.append(f"  {img_path.name}: Found disallowed color {color} at {len(positions)} pixels")
            if len(positions) <= 5:
                for x, y in positions[:5]:
                    errors.append(f"    at ({x}, {y})")
    
    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_palette.py <input_dir> [--strict]")
        return 1
    
    input_dir = Path(sys.argv[1])
    strict = "--strict" in sys.argv
    
    if not input_dir.exists():
        print(f"Input directory not found: {input_dir}")
        return 1
    
    all_errors = []
    total = 0
    
    for img_file in input_dir.rglob("*.png"):
        total += 1
        errors = validate_palette(img_file, strict)
        if errors:
            for err in errors:
                print(f"❌ {err}")
            all_errors.extend(errors)
        else:
            print(f"✅ {img_file.name}")
    
    print(f"\nChecked: {total}, Violations: {len(all_errors)}")
    return 0 if len(all_errors) == 0 else 1


if __name__ == "__main__":
    import numpy as np
    sys.exit(main())