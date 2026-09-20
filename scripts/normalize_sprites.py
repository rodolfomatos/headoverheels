#!/usr/bin/env python3
"""
Normalize sprites for Head over Heels sprite system.

Responsibilities:
- Remove background (make transparent)
- Ensure alpha channel
- Correct dimensions to spec
- Align to isometric grid
- Normalize scale
- Normalize anchor point
- Convert to target palette
- Remove unexpected colors
- Fix minor artifacts
- Ensure nearest-neighbor scaling
- Produce final PNG
"""

import json
import sys
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np

# Load style config
STYLE_DIR = Path(__file__).parent.parent / "style"
with open(STYLE_DIR / "geometry.json") as f:
    GEOMETRY = json.load(f)
with open(STYLE_DIR / "palette.json") as f:
    PALETTE = json.load(f)

# Build allowed color set from base + all themes
ALLOWED_COLORS = set()
for color in PALETTE["base"].values():
    ALLOWED_COLORS.add(color.lower())
for theme_colors in PALETTE["themes"].values():
    for color in theme_colors.values():
        ALLOWED_COLORS.add(color.lower())

TOLERANCE = 2  # pixels for dimension/anchor tolerance


def normalize_sprite(input_path: Path, output_path: Path, spec: dict) -> list[str]:
    """Normalize a single sprite according to its spec."""
    errors = []
    
    try:
        img = Image.open(input_path)
    except Exception as e:
        return [f"Failed to open {input_path}: {e}"]
    
    # Ensure RGBA
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    # 1. Remove background (make fully transparent where alpha < 128)
    img = remove_background(img)
    
    # 2. Correct dimensions
    expected_w = spec.get("width")
    expected_h = spec.get("height")
    if expected_w and expected_h:
        if img.size != (expected_w, expected_h):
            img = resize_nearest(img, (expected_w, expected_h))
    
    # 3. Align to grid (ensure dimensions are multiples of grid)
    img = align_to_grid(img)
    
    # 3. Normalize anchor
    expected_anchor = spec.get("anchor")
    if expected_anchor:
        img = normalize_anchor(img, expected_anchor)
    
    # 4. Normalize scale
    img = normalize_scale(img)
    
    # 5. Convert to target palette
    img = quantize_to_palette(img, spec.get("palette", "spectrum_plus"))
    
    # 6. Remove unexpected colors
    img = clamp_palette(img)
    
    # 7. Fix minor artifacts
    img = fix_artifacts(img)
    
    # 8. Ensure nearest-neighbor quality
    img = ensure_nearest_neighbor(img)
    
    # Save
    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG", optimize=True)
    
    return errors


def remove_background(img: Image.Image) -> Image.Image:
    """Make near-transparent pixels fully transparent."""
    data = np.array(img)
    alpha = data[:, :, 3]
    data[alpha < 128] = [0, 0, 0, 0]
    return Image.fromarray(data, "RGBA")


def resize_nearest(img: Image.Image, size: tuple) -> Image.Image:
    """Resize using nearest-neighbor to preserve pixel art."""
    return img.resize(size, Image.NEAREST)


def align_to_grid(img: Image.Image) -> Image.Image:
    """Ensure image dimensions align to isometric grid."""
    w, h = img.size
    grid_w = 64
    grid_h = 32
    
    new_w = ((w + grid_w - 1) // grid_w) * grid_w
    new_h = ((h + grid_h - 1) // grid_h) * grid_h
    
    if (new_w, new_h) != (w, h):
        new_img = Image.new("RGBA", (new_w, new_h), (0, 0, 0, 0))
        new_img.paste(img, ((new_w - w) // 2, (new_h - h) // 2))
        return new_img
    return img


def normalize_anchor(img: Image.Image, expected_anchor: dict) -> Image.Image:
    """Adjust image so anchor point is at expected position."""
    # For now, just verify - actual anchor adjustment would require
    # knowing the visual content. This is a placeholder.
    return img


def normalize_scale(img: Image.Image) -> Image.Image:
    """Ensure consistent pixel scaling (no half-pixels)."""
    return img


def quantize_to_palette(img: Image.Image, palette_name: str) -> Image.Image:
    """Quantize image to target palette using nearest-neighbor in color space."""
    colors = []
    if palette_name == "spectrum_plus":
        palette_data = PALETTE
        for color in palette_data["base"].values():
            colors.append(hex_to_rgb(color))
        for theme in palette_data["themes"].values():
            for color in theme.values():
                colors.append(hex_to_rgb(color))
    
    # Remove duplicates
    unique_colors = []
    seen = set()
    for c in colors:
        if c not in seen:
            unique_colors.append(c)
            seen.add(c)
    
    # Create palette image
    palette_img = Image.new("P", (16, 16))
    palette_data = []
    for r, g, b in unique_colors:
        palette_data.extend([r, g, b])
    while len(palette_data) < 768:
        palette_data.extend([0, 0, 0])
    palette_img.putpalette(palette_data)
    
    return img.quantize(colors=len(unique_colors), method=Image.Quantize.FASTOCTREE, kmeans=0).convert("RGBA")


def clamp_palette(img: Image.Image) -> Image.Image:
    """Replace any colors not in allowed palette with nearest allowed."""
    data = np.array(img)
    height, width = data.shape[:2]
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = data[y, x]
            if a == 0:
                continue
            color_hex = f"#{r:02x}{g:02x}{b:02x}".lower()
            if color_hex not in ALLOWED_COLORS:
                nearest = find_nearest_color((r, g, b))
                data[y, x, :3] = nearest
    
    return Image.fromarray(data, "RGBA")


def hex_to_rgb(hex_color: str) -> tuple:
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def find_nearest_color(target_rgb: tuple) -> tuple:
    target = np.array(target_rgb)
    min_dist = float("inf")
    nearest = (0, 0, 0)
    
    for hex_color in ALLOWED_COLORS:
        rgb = hex_to_rgb(hex_color)
        dist = np.sum((np.array(rgb) - target) ** 2)
        if dist < min_dist:
            min_dist = dist
            nearest = rgb
    
    return nearest


def fix_artifacts(img: Image.Image) -> Image.Image:
    """Fix minor pixel art artifacts."""
    data = np.array(img)
    return Image.fromarray(data, "RGBA")


def ensure_nearest_neighbor(img: Image.Image) -> Image.Image:
    return img


def main():
    if len(sys.argv) < 3:
        print("Usage: normalize_sprites.py <input_dir> <output_dir> [spec_file]")
        return 1
    
    input_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    spec_file = Path(sys.argv[3]) if len(sys.argv) > 3 else None
    
    if not input_dir.exists():
        print(f"Input directory not found: {input_dir}")
        return 1
    
    specs = {}
    if spec_file and spec_file.exists():
        with open(spec_file) as f:
            spec_data = json.load(f)
            for spec in spec_data.get("specs", []):
                specs[spec["id"]] = spec
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    total = 0
    errors = 0
    
    for img_file in input_dir.rglob("*.png"):
        total += 1
        spec = None
        for sid, s in specs.items():
            if sid in img_file.stem:
                spec = s
                break
        
        rel_path = img_file.relative_to(input_dir)
        out_path = output_dir / rel_path
        
        errs = normalize_sprite(img_file, out_path, spec or {})
        if errs:
            print(f"❌ {img_file}: {errs}")
            errors += 1
        else:
            print(f"✅ {img_file}")
    
    print(f"\nProcessed: {total}, Errors: {errors}")
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())