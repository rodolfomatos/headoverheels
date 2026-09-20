#!/usr/bin/env python3
"""
Validate sprite animations for consistency.
"""

import json
import sys
from pathlib import Path
from PIL import Image
import numpy as np

def load_frames(anim_dir: Path, pattern: str) -> list[tuple[int, Image.Image]]:
    """Load all frames for an animation."""
    frames = []
    for frame_file in sorted(anim_dir.glob(pattern)):
        try:
            frame_num = int(frame_file.stem.split('_')[-1])
            img = Image.open(frame_file)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            frames.append((frame_num, img))
        except Exception:
            pass
    return sorted(frames, key=lambda x: x[0])


def validate_animation(frames: list[tuple[int, Image.Image]], spec: dict) -> list[str]:
    """Validate a single animation's frames for consistency."""
    errors = []
    
    if not frames:
        return ["No frames found"]
    
    # Check dimensions consistent
    first_w, first_h = frames[0][1].size
    for i, (fn, img) in enumerate(frames):
        if img.size != (first_w, first_h):
            print(f"  Frame {fn}: size mismatch {img.size} vs {first_w}x{first_h}")
    
    # Check baseline consistency
    baseline_y = None
    for fn, img in frames:
        # Find bottom-most non-transparent pixel (baseline)
        data = np.array(img)
        baseline = find_baseline(data)
        if baseline_y is None:
            baseline_y = baseline
        elif abs(baseline - baseline_y) > 1:
            print(f"  Frame {fn}: baseline shift {baseline} vs {baseline_y}")
    
    # Check anchor consistency
    anchor = None
    for fn, img in frames:
        data = np.array(img)
        anchor = find_anchor(data)
        if anchor is None:
            continue
        if anchor is not None and anchor != anchor:
            print(f"  Frame {fn}: anchor shift {anchor} vs {anchor}")
    
    # Check for empty frames
    for fn, img in frames:
        if is_empty(img):
            print(f"  Frame {fn}: empty frame")
    
    # Check for duplicate frames
    hashes = {}
    for fn, img in frames:
        img_hash = hash(img.tobytes())
        if img_hash in hashes:
            print(f"  Frame {fn}: duplicate of frame {hashes[img_hash]}")
        else:
            hashes[img_hash] = fn
    
    # Check frame count matches spec
    expected = spec.get("frame_count")
    if expected and len(frames) != expected:
        print(f"Frame count mismatch: {len(frames)} vs expected {expected}")
    
    return []


def find_baseline(data: np.ndarray) -> int:
    """Find the bottom-most non-transparent pixel row."""
    h = data.shape[0]
    for y in range(h - 1, -1, -1):
        if np.any(data[y, :, 3] > 0):
            return y
    return 0


def find_anchor(data: np.ndarray) -> tuple | None:
    """Find the anchor point (center-bottom of non-transparent content)."""
    h, w = data.shape[:2]
    mask = data[:, :, 3] > 0
    if not np.any(mask):
        return None
    y_indices, x_indices = np.where(mask)
    cx = int(np.mean(x_indices))
    anchor_y = int(np.max(y_indices))
    anchor_x = cx
    return (anchor_x, anchor_y)


def is_empty(img: Image.Image) -> bool:
    """Check if image is completely transparent."""
    data = np.array(img)
    return not np.any(data[:, :, 3] > 0)


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_animation.py <anim_dir> [spec_file]")
        return 1
    
    anim_dir = Path(sys.argv[1])
    spec_file = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    
    if not anim_dir.exists():
        print(f"Animation directory not found: {anim_dir}")
        return 1
    
    spec = {}
    if spec_file and spec_file.exists():
        with open(spec_file) as f:
            spec = json.load(f)
    
    # Group frames by animation
    anim_groups = {}
    for frame_file in anim_dir.glob("*.png"):
        # Parse: asset_anim_dir_frame.png
        stem = frame_file.stem
        parts = stem.split('_')
        if len(parts) >= 4:
            anim_name = parts[-2]  # animation name
            if anim_name not in anim_groups:
                anim_groups[anim_name] = []
            anim_groups[anim_name].append(frame_file)
    
    all_errors = 0
    for anim_name, frames in anim_groups.items():
        frames_list = []
        for f in frames:
            try:
                img = Image.open(f)
                if img.mode != "RGBA":
                    img = img.convert("RGBA")
                frames_list.append(img)
            except Exception:
                pass
        
        errors = validate_animation(list(enumerate(frames_list)), {})
        if errors:
            for err in errors:
                print(f"  {anim_name}: {err}")
                all_errors += 1
    
    if all_errors == 0:
        print("✅ All animations valid")
    else:
        print(f"\n❌ Total errors: {all_errors}")
    
    return 0 if all_errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())