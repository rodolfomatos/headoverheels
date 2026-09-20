#!/usr/bin/env python3
"""
Pack sprites into atlases using TexturePacker CLI.
"""
import subprocess
import shutil
from pathlib import Path

def check_texturepacker():
    """Check if TexturePacker is available."""
    tp_path = shutil.which("TexturePacker")
    if tp_path is None:
        # Try common install locations
        for path in [
            "/Applications/TexturePacker.app/Contents/MacOS/TexturePacker",
            "/usr/local/bin/TexturePacker",
            "C:\\Program Files\\TexturePacker\\TexturePacker.exe",
        ]:
            if Path(path).exists():
                return path
        return None
    return tp_path

def pack_atlas(input_dir, output_name, max_size=2048, scale="1", variants="1:0.5,0.25"):
    """Pack a directory of sprites into an atlas."""
    tp = check_texturepacker()
    if tp is None:
        print("❌ TexturePacker not found. Install from https://www.codeandweb.com/texturepacker")
        return False
    
    input_path = Path(input_dir)
    if not input_path.exists():
        print(f"❌ Input directory not found: {input_dir}")
        return False
    
    output_dir = Path("assets/atlases")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    cmd = [
        tp,
        "--format", "json",
        "--data", str(output_dir / f"{output_name}.json"),
        "--sheet", str(output_dir / f"{output_name}.png"),
        "--max-size", str(max_size),
        "--scale", scale,
        "--variant", variants,
        "--opt", "RGBA8888",
        "--trim-mode", "Trim",
        "--allow-free-size",
        "--disable-rotation",
        "--png-opt-level", "2",
        str(input_path)
    ]
    
    print(f"📦 Packing {output_name}...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"❌ TexturePacker failed: {result.stderr}")
        return False
    else:
        print(f"✅ Packed {output_name} → {output_dir}/{output_name}.png + .json")
        return True

def main():
    # Check TexturePacker
    tp = check_texturepacker()
    if tp is None:
        print("❌ TexturePacker not found!")
        print("   Install from: https://www.codeandweb.com/texturepacker")
        print("   Or: brew install texturepacker (macOS)")
        print("   Or: download from https://www.codeandweb.com/texturepacker/download")
        return 1
    
    print(f"🔧 Using TexturePacker: {tp}")
    
    # Pack each category
    atlases = [
        ("generated/characters", "chars"),
        ("generated/tilesets", "tiles"),
        ("generated/entities", "entities"),
        ("generated/ui", "ui"),
        ("generated/effects", "effects"),
    ]
    
    success = 0
    for input_dir, name in atlases:
        if Path(input_dir).exists():
            if pack_atlas(input_dir, name):
                success += 1
        else:
            print(f"⚠️  Skipping {name} (input dir not found)")
    
    print(f"\n📊 Successfully packed: {success}/{len(atlases)} atlases")
    return 0 if success > 0 else 1

if __name__ == "__main__":
    import sys
    sys.exit(main())