#!/usr/bin/env python3
"""
Generate Entity Master sprites for Head over Heels 2026 reimagining.
Creates master sprites for all 13 entity types.
"""

from PIL import Image, ImageDraw
from pathlib import Path
import math
import random

# Output directories
GAME = Path(__file__).parent.parent / "games" / "headoverheels"
OUTPUT_DIR = GAME / "assets" / "sprites" / "entities"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Color palette - Spectrum+ (2026) - Entity colors
PALETTE = {
    # Entity colors
    "entity_fish": (0, 188, 212),
    "entity_fish_glow": (77, 208, 225),
    "entity_rabbit": (76, 175, 80),
    "entity_crown": (253, 216, 53),
    "entity_spring": (255, 152, 0),
    "entity_switch": (33, 150, 243),
    "entity_conveyor": (255, 109, 0),
    "entity_teleport": (0, 188, 212),
    "entity_door": (62, 39, 35),
    "entity_monster": (198, 40, 40),
    "entity_guardian": (55, 71, 79),
    "entity_hush_puppy": (141, 110, 99),
    "entity_bag": (141, 110, 99),
    "entity_key": (255, 214, 0),
    "entity_doughnut": (255, 152, 0),
}

ENTITIES = {
    "fish": {"size": (64, 32), "color": "entity_fish", "animations": ["alive", "dead", "eaten"]},
    "rabbit": {"size": (32, 32), "color": "entity_rabbit", "animations": ["hop", "collected"]},
    "crown": {"size": (32, 32), "color": "entity_crown", "animations": ["rotate", "collected"]},
    "spring": {"size": (48, 48), "color": "entity_spring", "animations": ["idle", "compressed", "extended"]},
    "switch": {"size": (48, 48), "color": "entity_switch", "animations": ["off", "on"]},
    "conveyor": {"size": (64, 32), "color": "entity_conveyor", "animations": ["east", "west", "north", "south"]},
    "teleport": {"size": (64, 64), "color": "entity_teleport", "animations": ["idle", "active"]},
    "door": {"size": (64, 64), "color": "entity_door", "animations": ["locked", "unlocked", "open"]},
    "monster": {"size": (64, 64), "color": "entity_monster", "animations": ["walk", "freeze", "death"]},
    "guardian": {"size": (96, 96), "color": "entity_guardian", "animations": ["patrol", "attack"]},
    "hush_puppy": {"size": (48, 48), "color": "entity_hush_puppy", "animations": ["sleep", "teleport", "alert"]},
    "bag": {"size": (32, 32), "color": "entity_bag", "animations": ["idle", "collected"]},
    "key": {"size": (24, 24), "color": "entity_key", "animations": ["idle", "collected"]},
    "doughnut": {"size": (16, 16), "color": "entity_doughnut", "animations": ["idle", "thrown"]},
}


def create_entity_masters():
    """Create entity master sprites for all entity types."""
    print("Creating entity master sprites...")
    
    for entity_name, entity_data in ENTITIES.items():
        size = entity_data["size"]
        color = PALETTE[entity_data["color"]]
        animations = entity_data["animations"]
        
        # Create master sheet: 8 columns (directions/frames) x 4 rows (animations)
        sheet_w = entity_data["size"][0] * 8
        sheet_h = entity_data["size"][1] * 4
        sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
        
        for i, anim in enumerate(animations):
            for frame in range(4):  # 4 frames per animation
                # The sheet is 8 columns by 4 rows and each animation gets one
                # row. `i * 4 + frame // 8` put animation two at row 4, which is
                # past the bottom of a four-row sheet: PIL pasted it nowhere and
                # rows 1 to 3 stayed empty, so an entity's second animation was
                # absent from the very file it was generated into.
                col = frame % 8
                row = i
                x = col * size[0]
                y = row * size[1]
                
                frame_img = Image.new("RGBA", size, (0, 0, 0, 0))
                fd = ImageDraw.Draw(frame_img)
                fd.rectangle([0, 0, size[0], size[1]], fill=color)
                
                # Add simple animation variation for movement animations
                if anim in ("walk", "run", "patrol"):
                    offset = (frame % 2) * 2
                    fd.ellipse([size[0]//2 - 4 + offset, size[1]//2 - 4, 
                               size[0]//2 + 4 + offset, size[1]//2 + 4], fill=(255, 255, 255))
                elif anim == "swim":
                    offset = (frame % 3) * 2
                    fd.ellipse([size[0]//2 - 4 + offset, size[1]//2 - 4, 
                               size[0]//2 + 4 + offset, size[1]//2 + 4], fill=(255, 255, 255))
                elif anim == "rotate":
                    angle = frame * 45
                    fd.line([size[0]//2, size[1]//2, 
                            size[0]//2 + int(8 * math.cos(frame * 0.785)), 
                            size[1]//2 + int(8 * math.sin(frame * 0.785))], 
                           fill=(255, 255, 255), width=2)
                
                sheet.paste(frame_img, (x, y))
        
        entity_dir = OUTPUT_DIR / entity_name
        entity_dir.mkdir(parents=True, exist_ok=True)
        sheet.save(entity_dir / f"{entity_name}_master.png")
        print(f"Created {entity_name}_master.png")


def main():
    print("Generating Entity Master sprites...")
    
    create_entity_masters()
    
    print("\n✅ Entity Master sprites generated!")
    print("Next: T023 Remaining Themes")


if __name__ == "__main__":
    import math
    import random
    main()