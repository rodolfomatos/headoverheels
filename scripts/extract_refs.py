#!/usr/bin/env python3
"""
Extract reference crops from maps/manual for prompt references.
"""

from PIL import Image
from pathlib import Path

MAPS_DIR = Path(__file__).parent.parent / "docs" / "RESEARCH"
REFS_DIR = Path(__file__).parent.parent / "prompts" / "references"

def crop_region(image: Image.Image, box: tuple, name: str):
    """Crop a region and save."""
    cropped = image.crop(box)
    out_path = REFS_DIR / name
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(out_path)
    print(f"✅ Extracted: {name} ({cropped.size})")

def main():
    REFS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Load map images
    maps = {}
    for i in range(1, 5):
        for ext in ['.jpg', '.png']:
            path = MAPS_DIR / f"map{i}{ext}"
            if path.exists():
                maps[f"map{i}"] = Image.open(path)
                print(f"Loaded {path}")
                break
    
    if not maps:
        print("No map images found in docs/RESEARCH/")
        return
    
    # Character references from map1 (castle entrance)
    if "map1" in maps:
        img = maps["map1"]
        # Castle entrance area - roughly center-top
        crop_region(img, (200, 100, 300, 250), "characters/head_reference.png")
        crop_region(img, (150, 200, 250, 350), "characters/heels_reference.png")
        # Combined mode area
        crop_region(img, (300, 150, 400, 300), "characters/combined_reference.png")
    
    # Tileset references from maps
    if "map1" in maps:
        img = maps["map1"]
        crop_region(img, (50, 50, 150, 150), "tilesets/castle_floor_sample.png")
        crop_region(img, (200, 200, 300, 300), "tilesets/castle_wall_sample.png")
    
    if "map2" in maps:
        img = maps["map2"]
        crop_region(img, (100, 100, 200, 200), "tilesets/egyptus_pyramid_sample.png")
        crop_region(img, (300, 50, 400, 150), "tilesets/moonbase_panel_sample.png")
    
    if "map3" in maps:
        img = maps["map3"]
        crop_region(img, (100, 100, 200, 200), "tilesets/penitentiary_cell_sample.png")
        crop_region(img, (250, 250, 350, 350), "tilesets/safari_jungle_sample.png")
    
    if "map4" in maps:
        img = maps["map4"]
        crop_region(img, (200, 200, 300, 300), "tilesets/bookworld_library_sample.png")
        crop_region(img, (100, 100, 400, 400), "tilesets/world_overview.png")
    
    # Extract from manual if available
    for i in [1, 2]:
        path = MAPS_DIR / f"instructions{i}.txt"
        if path.exists():
            print(f"Manual text available: {path}")
            # Could extract images from HTML too
    
    print("\n✅ Reference extraction complete!")
    print(f"📁 Output: {REFS_DIR}")

if __name__ == "__main__":
    main()