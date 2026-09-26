#!/usr/bin/env python3
"""
Generate environment master sprites for Head over Heels 2026 reimagining.
Creates master tiles for Castle theme and other environment assets.
"""

from PIL import Image, ImageDraw
from pathlib import Path
import random

from tileset_geometry import save_masked

# Output directories
OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "tiles"
CASTLE_DIR = OUTPUT_DIR / "castle"
EGYPTUS_DIR = OUTPUT_DIR / "egyptus"
PENITENTIARY_DIR = OUTPUT_DIR / "penitentiary"
SAFARI_DIR = OUTPUT_DIR / "safari"
BOOKWORLD_DIR = OUTPUT_DIR / "bookworld"
MOONBASE_DIR = OUTPUT_DIR / "moonbase"
PROPS_DIR = OUTPUT_DIR / "props"
ENTITIES_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "entities"

for d in [OUTPUT_DIR, CASTLE_DIR, EGYPTUS_DIR, PENITENTIARY_DIR, SAFARI_DIR, 
          BOOKWORLD_DIR, MOONBASE_DIR, PROPS_DIR, ENTITIES_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Color palette - all as RGB tuples
PALETTE = {
    # Spectrum DNA colors
    "black": (0, 0, 0),
    "dark_blue": (0, 0, 216),
    "blue": (48, 48, 255),
    "dark_red": (208, 0, 0),
    "red": (255, 32, 32),
    "dark_green": (0, 128, 0),
    "green": (32, 192, 32),
    "dark_cyan": (0, 128, 128),
    "cyan": (32, 216, 216),
    "dark_yellow": (192, 160, 0),
    "yellow": (255, 216, 32),
    "dark_magenta": (160, 0, 160),
    "magenta": (224, 32, 224),
    "grey": (128, 128, 128),
    "light_grey": (192, 192, 192),
    "white": (255, 255, 255),
    # Castle theme
    "castle_stone_dark": (45, 45, 45),
    "castle_stone_mid": (74, 74, 74),
    "castle_stone_light": (117, 117, 117),
    "castle_mortar": (62, 62, 62),
    "castle_torch_orange": (255, 109, 0),
    "castle_torch_yellow": (255, 214, 0),
    "castle_banner_red": (183, 28, 28),
    "castle_iron_grey": (55, 71, 79),
    "castle_moss_green": (46, 125, 50),
    "castle_water_blue": (21, 101, 192),
    "castle_lava_red": (211, 47, 47),
    "castle_gold": (253, 216, 53),
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
    # Outline colors
    "outline_dark": (27, 94, 32),
    "outline_heels": (183, 28, 28),
    "castle_outline": (45, 45, 45),
}


def create_castle_masters():
    """Create Castle theme master tiles"""
    print("Creating Castle theme master tiles...")
    
    TILE_W, TILE_H = 64, 32
    sheet_w, sheet_h = 1024, 512
    sheet = Image.new("RGBA", (1024, 512), (0, 0, 0, 0))
    
    # Color shortcuts
    stone_dark = PALETTE["castle_stone_dark"]
    stone_mid = PALETTE["castle_stone_mid"]
    stone_light = PALETTE["castle_stone_light"]
    mortar = PALETTE["castle_mortar"]
    torch_orange = PALETTE["castle_torch_orange"]
    torch_yellow = PALETTE["castle_torch_yellow"]
    banner_red = PALETTE["castle_banner_red"]
    iron_grey = PALETTE["castle_iron_grey"]
    moss_green = PALETTE["castle_moss_green"]
    water_blue = PALETTE["castle_water_blue"]
    lava_red = PALETTE["castle_lava_red"]
    gold = PALETTE["castle_gold"]
    outline = PALETTE["castle_outline"]
    
    def draw_tile_at(tile_x, tile_y, draw_func):
        x = tile_x * 64
        y = tile_y * 32
        tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        tile_draw = ImageDraw.Draw(tile_img)
        draw_func(tile_draw, 0, 0, 64, 32)
        sheet.paste(tile_img, (x, y), tile_img)
    
    # ========== FLOORS (IDs 0-15) ==========
    print("Creating floor tiles...")
    for i in range(16):
        tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        td = ImageDraw.Draw(tile_img)
        td.rectangle([0, 0, 64, 32], fill=PALETTE["castle_stone_mid"], outline=PALETTE["castle_outline"])
        if i == 1:  # cracked
            td.line([8, 8, 56, 24], fill=PALETTE["castle_mortar"], width=1)
            td.line([56, 8, 8, 24], fill=PALETTE["castle_mortar"], width=1)
        elif i == 2:  # worn
            random.seed(42)
            for _ in range(15):
                px = random.randint(4, 60)
                py = random.randint(4, 28)
                tile_img.putpixel((px, py), PALETTE["castle_mortar"])
        elif i == 3:  # moss
            random.seed(42)
            for _ in range(10):
                px = random.randint(4, 60)
                py = random.randint(4, 28)
                tile_draw = ImageDraw.Draw(tile_img)
                tile_draw.ellipse([px-1, py-1, px+1, py+1], fill=PALETTE["castle_moss_green"])
        elif i == 5:  # illuminated
            td.ellipse([20, 8, 44, 24], fill=PALETTE["castle_gold"])
        elif i == 15:  # edge
            tile_img.paste(PALETTE["castle_mortar"], (0, 30, 64, 32))
        sheet.paste(tile_img, (i * 64, 0))
    
    # WALLS (IDs 16-31)
    for i in range(16):
        tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        td = ImageDraw.Draw(tile_img)
        td.rectangle([0, 0, 64, 32], fill=PALETTE["castle_stone_dark"], outline=PALETTE["castle_outline"])
        if i == 0:
            td.line([0, 0, 0, 32], fill=PALETTE["castle_mortar"], width=2)
        elif i == 1:
            td.line([0, 0, 64, 0], fill=PALETTE["castle_mortar"], width=2)
            td.line([0, 0, 0, 32], fill=PALETTE["castle_mortar"], width=2)
        elif i == 2:
            td.line([64, 0, 64, 32], fill=PALETTE["castle_mortar"], width=2)
        elif i == 3:
            td.line([8, 0, 8, 32], fill=PALETTE["castle_mortar"], width=1)
        elif i == 4:
            td.rectangle([28, 8, 36, 24], fill=PALETTE["castle_mortar"])
        elif i == 5:
            td.ellipse([28, 4, 36, 12], fill=PALETTE["castle_torch_orange"])
            td.ellipse([29, 5, 35, 11], fill=PALETTE["castle_torch_yellow"])
        elif i == 8:
            td.line([0, 0, 64, 32], fill=PALETTE["castle_mortar"], width=1)
            td.line([64, 0, 0, 32], fill=PALETTE["castle_mortar"], width=1)
        elif i == 9:
            random.seed(42)
            for _ in range(5):
                px = random.randint(4, 60)
                py = random.randint(4, 28)
                tile_img.putpixel((px, py), PALETTE["castle_moss_green"])
        sheet.paste(tile_img, ((i % 16) * 64, (i // 16 + 1) * 32))
    
    # Save
    save_masked(sheet, CASTLE_DIR / "castle_masters.png")
    print(f"Created {CASTLE_DIR}/castle_masters.png")
    print("Castle masters created!")

def create_other_theme_masters():
    """Create masters for other themes"""
    themes = {
        "egyptus": {
            "palette": {
                "sand_dark": (78, 52, 46),
                "sand_mid": (141, 110, 99),
                "sand_light": (215, 204, 200),
                "stone_dark": (62, 39, 35),
                "stone_mid": (93, 64, 55),
                "stone_light": (141, 110, 99),
                "gold": (253, 216, 53),
                "hieroglyph_blue": (21, 101, 192),
                "hieroglyph_green": (46, 125, 50),
                "torch_orange": (255, 109, 0),
                "water_blue": (2, 119, 189),
                "palm_green": (46, 125, 50),
            },
            "name": "egyptus"
        },
        "penitentiary": {
            "palette": {
                "concrete_dark": (33, 33, 33),
                "concrete_mid": (66, 66, 66),
                "concrete_light": (97, 97, 97),
                "metal_dark": (38, 50, 56),
                "metal_mid": (55, 71, 79),
                "metal_light": (84, 110, 122),
                "bar_grey": (69, 90, 100),
                "warning_red": (198, 40, 40),
                "warning_yellow": (249, 168, 37),
                "glass": (129, 212, 250),
                "rust": (191, 54, 12),
            },
            "name": "penitentiary"
        },
        "safari": {
            "palette": {
                "jungle_dark": (27, 94, 32),
                "jungle_mid": (46, 125, 50),
                "jungle_light": (76, 175, 80),
                "wood_dark": (62, 39, 35),
                "wood_mid": (93, 64, 55),
                "wood_light": (141, 110, 99),
                "vine_green": (27, 94, 32),
                "flower_red": (198, 40, 40),
                "flower_yellow": (255, 214, 0),
                "water_blue": (2, 119, 189),
                "earth_brown": (78, 52, 46),
            },
            "name": "safari"
        },
        "bookworld": {
            "palette": {
                "shelf_dark": (62, 39, 35),
                "shelf_mid": (93, 64, 55),
                "shelf_light": (141, 110, 99),
                "paper_cream": (255, 248, 225),
                "paper_yellow": (255, 249, 196),
                "ink_black": (33, 33, 33),
                "ink_blue": (21, 101, 192),
                "ink_red": (183, 28, 28),
                "leather_brown": (62, 39, 35),
                "gold_leaf": (253, 216, 53),
                "dust_grey": (158, 158, 158),
            },
            "name": "bookworld"
        },
        "moonbase": {
            "palette": {
                "metal_dark": (38, 50, 56),
                "metal_mid": (55, 71, 79),
                "metal_light": (84, 110, 122),
                "panel_blue": (21, 101, 192),
                "panel_cyan": (0, 188, 212),
                "panel_white": (236, 239, 241),
                "glow_cyan": (0, 188, 212),
                "glow_blue": (41, 121, 255),
                "warning_red": (211, 47, 47),
                "regolith_grey": (120, 144, 156),
                "glass": (129, 212, 250),
            },
            "name": "moonbase"
        },
        "bookworld": {
            "palette": {
                "shelf_dark": (62, 39, 35),
                "shelf_mid": (93, 64, 55),
                "shelf_light": (141, 110, 99),
                "paper_cream": (255, 248, 225),
                "paper_yellow": (255, 249, 196),
                "ink_black": (33, 33, 33),
                "ink_blue": (21, 101, 192),
                "ink_red": (183, 28, 28),
                "leather_brown": (62, 39, 35),
                "gold_leaf": (253, 216, 53),
                "dust_grey": (158, 158, 158),
            },
            "name": "bookworld"
        }
    }
    
    for theme_key, theme_data in themes.items():
        print(f"Creating {theme_data['name']} masters...")
        create_theme_masters(theme_data)

def create_theme_masters(theme_data):
    """Create master tiles for a theme"""
    palette = theme_data["palette"]
    theme_name = theme_data["name"]
    
    TILE_W, TILE_H = 64, 32
    sheet = Image.new("RGBA", (1024, 512), (0, 0, 0, 0))
    
    theme_dir = Path(__file__).parent.parent / "assets" / "sprites" / "tiles" / theme_name
    theme_dir.mkdir(parents=True, exist_ok=True)
    
    first_color = list(palette.values())[0]
    tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    td = ImageDraw.Draw(tile_img)
    td.rectangle([0, 0, 64, 32], fill=first_color)
    td.rectangle([0, 0, 64, 32], outline=(0, 0, 0, 255), width=1)
    
    for i in range(16):
        sheet.paste(tile_img, ((i % 16) * 64, (i // 16) * 32))
    
    sheet.save(Path(__file__).parent.parent / "assets" / "sprites" / "tiles" / f"{theme_name}.png")
    print(f"Created {theme_name}.png")

def create_entity_masters():
    """Create entity master sprites"""
    print("Creating entity masters...")
    
    ENTITIES_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "entities"
    ENTITIES_DIR.mkdir(parents=True, exist_ok=True)
    
    entities = {
        "fish": {"size": (64, 32), "color": (0, 188, 212), "animations": ["alive", "dead", "eaten"]},
        "rabbit": {"size": (32, 32), "color": (76, 175, 80), "animations": ["hop", "collected"]},
        "crown": {"size": (32, 32), "color": (253, 216, 53), "animations": ["rotate", "collected"]},
        "spring": {"size": (48, 48), "color": (255, 152, 0), "animations": ["idle", "compressed", "extended"]},
        "switch": {"size": (48, 48), "color": (33, 150, 243), "animations": ["off", "on"]},
        "conveyor": {"size": (64, 32), "color": (255, 109, 0), "animations": ["east", "west", "north", "south"]},
        "teleport": {"size": (64, 64), "color": (0, 188, 212), "animations": ["idle", "active"]},
        "door": {"size": (64, 64), "color": (62, 39, 35), "animations": ["locked", "unlocked", "open"]},
        "monster": {"size": (64, 64), "color": (198, 40, 40), "animations": ["walk", "freeze", "death"]},
        "guardian": {"size": (96, 96), "color": (55, 71, 79), "animations": ["patrol", "attack"]},
        "hush_puppy": {"size": (48, 48), "color": (141, 110, 99), "animations": ["sleep", "teleport", "alert"]},
        "bag": {"size": (32, 32), "color": (141, 110, 99), "animations": ["idle", "collected"]},
        "key": {"size": (24, 24), "color": (255, 214, 0), "animations": ["idle", "collected"]},
        "doughnut": {"size": (16, 16), "color": (255, 152, 0), "animations": ["idle", "thrown"]},
    }
    
    for entity_name, entity_data in entities.items():
        size = entity_data["size"]
        color = entity_data["color"]
        animations = entity_data["animations"]
        
        sheet_w = size[0] * 8
        sheet_h = size[1] * 4
        sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
        
        for i, anim in enumerate(animations):
            for frame in range(4):
                col = frame % 8
                row = i * 4 + frame // 8
                x = col * size[0]
                y = row * size[1]
                
                frame_img = Image.new("RGBA", size, (0, 0, 0, 0))
                fd = ImageDraw.Draw(frame_img)
                fd.rectangle([0, 0, size[0], size[1]], fill=color)
                if anim in ("walk", "run"):
                    offset = (frame % 2) * 2
                    fd.ellipse([size[0]//2 - 4 + offset, size[1]//2 - 4, 
                               size[0]//2 + 4 + offset, size[1]//2 + 4], fill=(255, 255, 255))
                sheet.paste(frame_img, (x, y))
        
        entity_dir = Path(__file__).parent.parent / "assets" / "sprites" / "entities" / entity_name
        entity_dir.mkdir(parents=True, exist_ok=True)
        sheet.save(entity_dir / f"{entity_name}_master.png")
        print(f"Created {entity_name}_master.png")

def create_prop_masters():
    print("Creating prop masters...")
    
    PROPS_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "props"
    PROPS_DIR.mkdir(parents=True, exist_ok=True)
    
    props = {
        "crate": {"size": (48, 48), "color": (93, 64, 55)},
        "torch": {"size": (32, 48), "color": (255, 109, 0)},
        "banner": {"size": (32, 64), "color": (183, 28, 28)},
        "chain": {"size": (16, 48), "color": (55, 71, 79)},
        "skull": {"size": (32, 32), "color": (215, 204, 200)},
        "crate_broken": {"size": (48, 48), "color": (78, 52, 46)},
        "barrel": {"size": (32, 48), "color": (93, 64, 55)},
        "sign": {"size": (48, 32), "color": (93, 64, 55)},
        "lever": {"size": (24, 48), "color": (255, 214, 0)},
        "pressure_plate": {"size": (48, 32), "color": (255, 109, 0)},
    }
    
    for prop_name, prop_data in props.items():
        size = prop_data["size"]
        color = prop_data["color"]
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        draw.rectangle([0, 0, size[0], size[1]], fill=color, outline=(0, 0, 0, 255), width=1)
        if "crate" in prop_name:
            draw.line([0, 0, size[0], size[1]], fill=(0,0,0,128), width=1)
            draw.line([size[0], 0, 0, size[1]], fill=(0,0,0,128), width=1)
        elif "torch" in prop_name:
            draw.ellipse([size[0]//2-4, 0, size[0]//2+4, 8], fill=(255, 109, 0))
            draw.ellipse([size[0]//2-3, 1, size[0]//2+3, 7], fill=(255, 214, 0))
        
        prop_dir = Path(__file__).parent.parent / "assets" / "sprites" / "props" / prop_name
        prop_dir.mkdir(parents=True, exist_ok=True)
        img.save(prop_dir / f"{prop_name}.png")
        print(f"Created {prop_name}.png")


def main():
    print("Generating environment master sprites...")
    
    # Initialize global PALETTE for castle
    global PALETTE
    PALETTE = {
        # Spectrum DNA colors
        "black": (0, 0, 0),
        "dark_blue": (0, 0, 216),
        "blue": (48, 48, 255),
        "dark_red": (208, 0, 0),
        "red": (255, 32, 32),
        "dark_green": (0, 128, 0),
        "green": (32, 192, 32),
        "dark_cyan": (0, 128, 128),
        "cyan": (32, 216, 216),
        "dark_yellow": (192, 160, 0),
        "yellow": (255, 216, 32),
        "dark_magenta": (160, 0, 160),
        "magenta": (224, 32, 224),
        "grey": (128, 128, 128),
        "light_grey": (192, 192, 192),
        "white": (255, 255, 255),
        # Castle theme
        "castle_stone_dark": (45, 45, 45),
        "castle_stone_mid": (74, 74, 74),
        "castle_stone_light": (117, 117, 117),
        "castle_mortar": (62, 62, 62),
        "castle_torch_orange": (255, 109, 0),
        "castle_torch_yellow": (255, 214, 0),
        "castle_banner_red": (183, 28, 28),
        "castle_iron_grey": (55, 71, 79),
        "castle_moss_green": (46, 125, 50),
        "castle_water_blue": (21, 101, 192),
        "castle_lava_red": (211, 47, 47),
        "castle_gold": (253, 216, 53),
        "castle_outline": (45, 45, 45),
        "castle_mortar": (62, 62, 62),
        "castle_torch_orange": (255, 109, 0),
        "castle_torch_yellow": (255, 214, 0),
        "castle_banner_red": (183, 28, 28),
        "castle_iron_grey": (55, 71, 79),
        "castle_moss_green": (46, 125, 50),
        "castle_water_blue": (21, 101, 192),
        "castle_lava_red": (211, 47, 47),
        "castle_gold": (253, 216, 53),
        "castle_outline": (45, 45, 45),
        "castle_mortar": (62, 62, 62),
        "castle_torch_orange": (255, 109, 0),
        "castle_torch_yellow": (255, 214, 0),
        "castle_banner_red": (183, 28, 28),
        "castle_iron_grey": (55, 71, 79),
        "castle_moss_green": (46, 125, 50),
        "castle_water_blue": (21, 101, 192),
        "castle_lava_red": (211, 47, 47),
        "castle_gold": (253, 216, 53),
        "castle_outline": (45, 45, 45),
        "castle_mortar": (62, 62, 62),
        "castle_torch_orange": (255, 109, 0),
        "castle_torch_yellow": (255, 214, 0),
        "castle_banner_red": (183, 28, 28),
        "castle_iron_grey": (55, 71, 79),
        "castle_moss_green": (46, 125, 50),
        "castle_water_blue": (21, 101, 192),
        "castle_lava_red": (211, 47, 47),
        "castle_gold": (253, 216, 53),
        "castle_outline": (45, 45, 45),
    }
    
    print("Generating environment master sprites...")
    
    create_castle_masters()
    create_other_theme_masters()
    create_entity_masters()
    create_prop_masters()
    
    print("\n✅ Environment master sprites generated!")
    print("Next steps:")
    print("1. Review generated assets")
    print("2. Integrate with TileMap system")
    print("3. Update entity factories to use new sprites")


if __name__ == "__main__":
    main()
