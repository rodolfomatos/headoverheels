#!/usr/bin/env python3
"""
Build spritesheets from individual frames.
Manifest-driven: reads assets/sprites/manifest.yaml and builds
spritesheets for each animation group.
"""

import sys
import yaml
import json
from pathlib import Path
from PIL import Image

PROJECT_ROOT = Path(__file__).parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets" / "sprites"
BUILD_DIR = PROJECT_ROOT / "build" / "normalized"
OUTPUT_DIR = PROJECT_ROOT / "build" / "spritesheets"
MANIFEST_PATH = ASSETS_DIR / "manifest.yaml"

# Direction code to file suffix mapping
DIR_SUFFIX = {
    "n": "front",
    "ne": "3q",
    "e": "side",
    "se": "side",
    "s": "back",
    "sw": "side",
    "w": "side",
    "nw": "3q",
}


def load_manifest():
    with open(MANIFEST_PATH) as f:
        data = yaml.safe_load(f)
    return data.get("assets", [])


def scan_animation_frames(char: str, anim: str, direction: str) -> list[Path]:
    """Scan build directory for frames matching character/animation/direction."""
    suffix = DIR_SUFFIX.get(direction, direction)
    pattern = f"{char}_{anim}_{suffix}"
    
    frames = []
    char_dir = BUILD_DIR / "characters" / char / "frames"
    if char_dir.exists():
        for f in char_dir.glob("*.png"):
            if f.name.startswith(pattern) and f.name.endswith(".png"):
                frames.append(f)
    char_root = BUILD_DIR / "characters" / char
    if char_root.exists():
        for f in char_root.glob("*.png"):
            if f.name.startswith(pattern) and f.name.endswith(".png"):
                frames.append(f)
    return sorted(frames)


def build_spritesheet(frames: list[Path], output_path: Path, spec: dict) -> bool:
    """Build a spritesheet from individual frames."""
    if not frames:
        return False
    
    frame_imgs = []
    for frame_path in frames:
        try:
            img = Image.open(frame_path)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            frame_imgs.append(img)
        except Exception as e:
            print(f"Warning: Could not load {frame_path}: {e}")
    
    if not frame_imgs:
        return False
    
    # Determine layout - single row for now
    cols = len(frame_imgs)
    rows = 1
    
    frame_w = frame_imgs[0].width
    frame_h = frame_imgs[0].height
    
    sheet_w = frame_w * cols
    sheet_h = frame_h * rows
    
    # Create spritesheet
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    for i, frame in enumerate(frame_imgs):
        x = i * frame_w
        y = 0
        sheet.paste(frame, (x, y))
    
    # Save spritesheet
    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path, "PNG", optimize=True)
    
    # Generate metadata
    meta = {
        "frame_width": frame_w,
        "frame_height": frame_h,
        "cols": cols,
        "rows": rows,
        "total_frames": len(frame_imgs),
        "animations": {
            "default": {
                "frames": list(range(len(frame_imgs))),
                "frame_count": len(frame_imgs),
                "frame_duration": spec.get("frame_duration", 100),
                "loop": spec.get("loop", True),
            }
        }
    }
    
    # Save metadata
    meta_path = output_path.with_suffix(".json")
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)
    
    print(f"✅ Built spritesheet: {output_path.relative_to(PROJECT_ROOT)} ({sheet_w}x{sheet_h}, {len(frame_imgs)} frames)")
    return True


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    assets = load_manifest()
    
    # Get unique character animations from manifest
    anim_specs = {}
    for asset in assets:
        if asset.get("category") != "character":
            continue
        char = asset.get("character")
        anim = asset.get("animation")
        direction = asset.get("direction", "")
        key = (char, anim, direction)
        if key not in anim_specs:
            anim_specs[key] = asset
    
    print(f"🏗️ Building spritesheets for {len(anim_specs)} animation groups...")
    
    success_count = 0
    
    for (char, anim, direction), spec in anim_specs.items():
        frame_paths = scan_animation_frames(char, anim, direction)
        
        if not frame_paths:
            print(f"⚠️ No frames found for {char}.{anim}.{direction}")
            continue
        
        # Output path: build/spritesheets/characters/head/idle_n.png
        direction_suffix = direction if direction else ""
        output_name = f"{anim}_{direction_suffix}.png" if direction_suffix else f"{anim}.png"
        output_path = OUTPUT_DIR / "characters" / char / output_name
        
        success = build_spritesheet(frame_paths, output_path, spec)
        if success:
            success_count += 1
    
    print(f"\nBuilt {success_count}/{len(anim_specs)} spritesheets")
    return 0 if success_count == len(anim_specs) else 1


if __name__ == "__main__":
    sys.exit(main())