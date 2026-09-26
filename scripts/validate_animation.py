#!/usr/bin/env python3
"""
Validate sprite animations for consistency.
Manifest-driven: reads assets/sprites/manifest.yaml and validates
animation consistency (baseline, anchor, scale, loop, frame count).

Scans build/normalized/ for actual frame files.
"""

import sys
import yaml
import re
from pathlib import Path
from PIL import Image
import numpy as np
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets" / "sprites"
BUILD_DIR = PROJECT_ROOT / "build" / "normalized"
MANIFEST_PATH = ASSETS_DIR / "manifest.yaml"

TOLERANCE = 1  # pixels


def load_manifest():
    """Load asset manifest."""
    with open(MANIFEST_PATH) as f:
        data = yaml.safe_load(f)
    return data.get("assets", [])


def find_baseline(data: np.ndarray) -> int:
    """Find the bottom-most non-transparent pixel row."""
    h = data.shape[0]
    for y in range(h - 1, -1, -1):
        if np.any(data[y, :, 3] > 0):
            return y
    return 0


def find_anchor(data: np.ndarray) -> tuple | None:
    """Find the anchor point (center-x, bottom-y of non-transparent content)."""
    mask = data[:, :, 3] > 0
    if not np.any(mask):
        return None
    y_indices, x_indices = np.where(mask)
    cx = int(np.mean(x_indices))
    anchor_y = int(np.max(y_indices))
    return (cx, anchor_y)


def is_empty(img: Image.Image) -> bool:
    """Check if image is completely transparent."""
    data = np.array(img)
    return not np.any(data[:, :, 3] > 0)


# Direction code to file suffix mapping
DIR_SUFFIX = {
    "n": "front",
    "ne": "3q",
    "e": "side",
    "se": "side",  # mirrored
    "s": "back",
    "sw": "side",  # mirrored
    "w": "side",   # mirrored
    "nw": "3q",    # mirrored
}


def scan_animation_frames(char: str, anim: str, direction: str) -> list[Path]:
    """Scan build directory for frames matching character/animation/direction."""
    suffix = DIR_SUFFIX.get(direction, direction)
    pattern = f"{char}_{anim}_{suffix}"
    
    frames = []
    # Check frames subdirectory
    char_dir = BUILD_DIR / "characters" / char / "frames"
    if char_dir.exists():
        for f in char_dir.glob("*.png"):
            if f.name.startswith(pattern) and f.name.endswith(".png"):
                frames.append(f)
    # Check character root directory (for duo, etc.)
    char_root = BUILD_DIR / "characters" / char
    if char_root.exists():
        for f in char_root.glob("*.png"):
            if f.name.startswith(pattern) and f.name.endswith(".png"):
                frames.append(f)
    return sorted(frames)


def validate_animation_frames(anim_id: str, frame_paths: list[Path], spec: dict) -> list[str]:
    """Validate a list of frame files for animation consistency."""
    errors = []
    
    if not frame_paths:
        return [f"{anim_id}: No frames found in build directory"]
    
    frame_imgs = []
    for frame_path in frame_paths:
        try:
            img = Image.open(frame_path)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            frame_imgs.append((frame_path.name, img))
        except Exception as e:
            errors.append(f"{anim_id}: Failed to load {frame_path}: {e}")
    
    if not frame_imgs:
        return [f"{anim_id}: No valid frames"]
    
    # Check dimensions consistent
    first_w, first_h = frame_imgs[0][1].size
    for fname, img in frame_imgs:
        if img.size != (first_w, first_h):
            errors.append(f"{anim_id}: Frame {fname} size mismatch {img.size} vs {first_w}x{first_h}")
    
    # Check baseline consistency
    baseline_y = None
    for fname, img in frame_imgs:
        data = np.array(img)
        baseline = find_baseline(data)
        if baseline_y is None:
            baseline_y = baseline
        elif abs(baseline - baseline_y) > TOLERANCE:
            errors.append(f"{anim_id}: Frame {fname} baseline shift {baseline} vs {baseline_y}")
    
    # Check anchor consistency
    anchor = None
    for fname, img in frame_imgs:
        data = np.array(img)
        frame_anchor = find_anchor(data)
        if anchor is None:
            anchor = frame_anchor
        elif anchor is not None and frame_anchor is not None:
            dx = frame_anchor[0] - anchor[0]
            dy = frame_anchor[1] - anchor[1]
            if abs(dx) > TOLERANCE or abs(dy) > TOLERANCE:
                errors.append(f"{anim_id}: Frame {fname} anchor shift {frame_anchor} vs {anchor} (dx={dx}, dy={dy})")
    
    # Check for empty frames
    for fname, img in frame_imgs:
        if is_empty(img):
            errors.append(f"{anim_id}: Frame {fname} is empty")
    
    # Check for duplicate frames
    hashes = {}
    for fname, img in frame_imgs:
        img_hash = hash(img.tobytes())
        if img_hash in hashes:
            errors.append(f"{anim_id}: Frame {fname} duplicate of {hashes[img_hash]}")
        else:
            hashes[img_hash] = fname
    
    # Check frame count matches spec (if we have enough frames)
    expected = spec.get("frames")
    if expected and len(frame_imgs) != expected:
        # Only error if we have more frames than expected (missing is OK for WIP)
        if len(frame_imgs) > expected:
            errors.append(f"{anim_id}: Frame count {len(frame_imgs)} exceeds expected {expected}")
    
    # Check loop seamlessness (first and last frame should be similar for looping animations)
    if spec.get("loop", False) and len(frame_imgs) >= 2:
        first_data = np.array(frame_imgs[0][1])
        last_data = np.array(frame_imgs[-1][1])
        if not np.array_equal(first_data[:, :, 3], last_data[:, :, 3]):
            errors.append(f"{anim_id}: Loop seamlessness check failed (first/last alpha differ)")
    
    return errors


def main():
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
    
    print(f"🔍 Validating {len(anim_specs)} animation groups from manifest...")
    
    total_errors = 0
    
    for (char, anim, direction), spec in anim_specs.items():
        frame_paths = scan_animation_frames(char, anim, direction)
        
        anim_id = f"character.{char}.{anim}.{direction}" if direction else f"character.{char}.{anim}"
        
        errors = validate_animation_frames(anim_id, frame_paths, spec)
        
        if errors:
            print(f"❌ {anim_id} ({len(frame_paths)} frames)")
            for err in errors:
                print(f"   {err}")
            total_errors += len(errors)
        else:
            print(f"✅ {anim_id} ({len(frame_paths)} frames)")
    
    print(f"\nTotal animation groups: {len(anim_specs)}, Total errors: {total_errors}")
    return 0 if total_errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())