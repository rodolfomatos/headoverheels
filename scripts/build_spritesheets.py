#!/usr/bin/env python3
"""
Build spritesheets from individual frames.
"""

import json
import sys
from pathlib import Path
from PIL import Image
from collections import defaultdict

def build_spritesheet(frames_dir: Path, output_path: Path, spec: dict) -> bool:
    """Build a spritesheet from individual frames."""
    frames = []
    
    # Find all frames matching the pattern
    for frame_file in sorted(frames_dir.glob("*.png")):
        try:
            img = Image.open(frame_file)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
            # Extract frame number from filename
            stem = frame_file.stem
            frame_num = int(stem.split('_')[-1])
            frames.append((frame_num, img))
        except Exception as e:
            print(f"Warning: Could not load {frame_file}: {e}")
    
    if not frames:
        print(f"No frames found in {frames_dir}")
        return False
    
    frames.sort(key=lambda x: x[0])
    
    # Determine layout
    cols = spec.get("cols", 8)
    rows = (len(frames) + cols - 1) // cols
    
    frame_w = frames[0][1].width
    frame_h = frames[0][1].height
    
    sheet_w = frame_w * cols
    sheet_h = frame_h * rows
    
    # Create spritesheet
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    for i, (fn, frame) in enumerate(frames):
        col = i % cols
        row = i // cols
        x = col * frame_w
        y = row * frame_h
        sheet.paste(frame, (x, y))
    
    # Save spritesheet
    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path, "PNG", optimize=True)
    
    # Generate metadata
    meta = {
        "frame_width": frames[0][1].width,
        "frame_height": frames[0][1].height,
        "cols": cols,
        "rows": rows,
        "total_frames": len(frames),
        "animations": {}
    }
    
    # Group by animation
    anim_groups = defaultdict(list)
    for fn, _ in frames:
        anim_name = f"{fn:02d}"
        anim_groups[anim_name].append(fn)
    
    for anim, frames_list in anim_groups.items():
        meta["animations"][anim] = {
            "frames": frames_list,
            "frame_count": len(frames_list)
        }
    
    # Save metadata
    meta_path = output_path.with_suffix(".json")
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)
    
    print(f"✅ Built spritesheet: {output_path} ({sheet_w}x{sheet_h}, {len(frames)} frames)")
    return True


def main():
    if len(sys.argv) < 3:
        print("Usage: build_spritesheets.py <frames_dir> <output_path> [spec_file]")
        return 1
    
    frames_dir = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    spec_file = Path(sys.argv[3]) if len(sys.argv) > 3 else None
    
    spec = {}
    if spec_file and spec_file.exists():
        with open(spec_file) as f:
            spec = json.load(f)
    
    success = build_spritesheet(frames_dir, output_path, spec)
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())