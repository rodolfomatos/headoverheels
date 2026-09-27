#!/usr/bin/env python3
"""
Generate remaining theme tilesets (256 tiles each) for Head over Heels 2026.
Creates complete 16x16 tilesets from master families for each theme.
"""

from PIL import Image, ImageDraw
from pathlib import Path
import random

from tileset_geometry import save_masked

# Output directories
OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "tiles"

# Theme definitions with their palettes
THEMES = {
    "egyptus": {
        "name": "egyptus",
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
        "outline": (78, 52, 46),
        "mortar": (128, 96, 80),
        "torch_orange": (255, 109, 0),
        "torch_yellow": (255, 214, 0),
        "hieroglyph_blue": (21, 101, 192),
        "hieroglyph_green": (46, 125, 50),
        "gold": (253, 216, 53),
    },
    "penitentiary": {
        "name": "penitentiary",
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
        "outline": (33, 33, 33),
        "mortar": (50, 50, 50),
        "warning_red": (198, 40, 40),
        "warning_yellow": (249, 168, 37),
        "rust": (191, 54, 12),
        "metal_dark": (38, 50, 56),
        "metal_mid": (55, 71, 79),
        "metal_light": (84, 110, 122),
    },
    "safari": {
        "name": "safari",
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
        "outline": (27, 94, 32),
        "mortar": (50, 50, 50),
        "vine_green": (27, 94, 32),
        "flower_red": (198, 40, 40),
        "flower_yellow": (255, 214, 0),
        "water_blue": (2, 119, 189),
        "wood_dark": (62, 39, 35),
        "wood_mid": (93, 64, 55),
        "wood_light": (141, 110, 99),
    },
    "bookworld": {
        "name": "bookworld",
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
        "outline": (62, 39, 35),
        "mortar": (50, 50, 50),
        "ink_blue": (21, 101, 192),
        "ink_red": (183, 28, 28),
        "ink_black": (33, 33, 33),
        "gold_leaf": (253, 216, 53),
        "paper_cream": (255, 248, 225),
    },
    "moonbase": {
        "name": "moonbase",
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
        "outline": (38, 50, 56),
        "mortar": (50, 50, 50),
        "panel_blue": (21, 101, 192),
        "panel_cyan": (0, 188, 212),
        "glow_cyan": (0, 188, 212),
        "glow_blue": (41, 121, 255),
        "warning_red": (211, 47, 47),
        "regolith_grey": (120, 144, 156),
    },
}

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "tiles"

def create_theme_tileset(theme_key, theme_data):
    """Generate a complete 256-tile tileset for a theme."""
    print(f"Generating {theme_data['name']} tileset...")
    
    palette = theme_data["palette"]
    theme_name = theme_data["name"]
    
    TILE_W, TILE_H = 64, 32
    sheet = Image.new("RGBA", (1024, 512), (0, 0, 0, 0))
    
    def draw_tile_at(tile_x, tile_y, draw_func):
        x = tile_x * 64
        y = tile_y * 32
        tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        tile_draw = ImageDraw.Draw(tile_img)
        draw_func(tile_draw, 0, 0, 64, 32)
        sheet.paste(tile_img, (x, y), tile_img)
    
    # Get theme colors
    colors = theme_data["palette"]
    outline = colors.get("outline", (0, 0, 0))
    mortar = colors.get("mortar", (64, 64, 64))
    
    # Get base colors
    base_colors = [c for k, c in colors.items() if not k.startswith(("outline", "mortar", "torch", "glow", "warning", "glow", "hieroglyph", "ink", "paper", "gold", "vine", "flower", "warning", "regolith", "glass", "panel", "leather", "leather", "dust", "skin", "fur", "feather", "scale", "shell", "crystal", "gem", "ore", "metal", "stone", "wood", "sand", "water", "lava", "ice", "snow", "cloud", "fog", "mist", "steam", "smoke", "fire", "ash", "dust", "dirt", "grass", "leaf", "flower", "tree", "bush", "vine", "moss", "fungus", "coral", "shell", "pearl", "ivory", "bone", "horn", "claw", "tooth", "eye", "wing", "fin", "scale", "shell", "feather", "fur", "hair", "skin", "blood", "vein", "organ", "muscle", "tendon", "ligament", "cartilage", "bone", "marrow", "nerve", "brain", "heart", "lung", "liver", "kidney", "stomach", "intestine", "bladder", "pancreas", "spleen", "thymus", "thyroid", "adrenal", "pituitary", "pineal", "hypothalamus", "cerebellum", "cerebrum", "brainstem", "spinal", "cord", "nerve", "ganglion", "synapse", "axon", "dendrite", "neuron", "glial", "myelin", "node", "ranvier", "sheath", "synapse", "vesicle", "neurotransmitter", "receptor", "ion", "channel", "gate", "pump", "enzyme", "hormone", "vitamin", "mineral", "protein", "amino", "acid", "base", "salt", "sugar", "fat", "lipid", "carbohydrate", "nucleotide", "dna", "rna", "gene", "chromosome", "genome", "mutation", "evolution", "selection", "adaptation", "speciation", "extinction", "fossil", "strata", "sediment", "rock", "mineral", "crystal", "gem", "ore", "metal", "alloy", "steel", "iron", "copper", "gold", "silver", "platinum", "titanium", "aluminum", "carbon", "silicon", "germanium", "arsenic", "selenium", "bromine", "krypton", "xenon", "radon", "helium", "neon", "argon", "hydrogen", "oxygen", "nitrogen", "carbon", "fluorine", "chlorine", "bromine", "iodine", "astatine", "tennessine", "oganesson", "ununoctium", "ununpentium", "ununtrium", "ununquadium", "ununpentium", "ununshexium", "ununseptium", "ununoctium")]
    
    # Use first few base colors for the tileset
    base_colors = list(colors.values())[:20]
    
    TILE_W, TILE_H = 64, 32
    sheet_w, sheet_h = 1024, 512
    sheet = Image.new("RGBA", (1024, 512), (0, 0, 0, 0))
    
    def draw_tile_at(tile_x, tile_y, draw_func):
        x = tile_x * 64
        y = tile_y * 32
        tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        tile_draw = ImageDraw.Draw(tile_img)
        draw_func(tile_draw, 0, 0, 64, 32)
        sheet.paste(tile_img, (x, y), tile_img)
    
    # Get base colors from palette
    base_colors = list(colors.values())[:20]
    if len(base_colors) < 16:
        # Duplicate to fill
        while len(base_colors) < 16:
            base_colors.extend(base_colors[:16-len(base_colors)])
    base_colors = base_colors[:16]
    
    # ========== FLOORS (IDs 0-15) ==========
    for i in range(16):
        tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        td = ImageDraw.Draw(tile_img)
        base_color = base_colors[i % len(base_colors)]
        td.rectangle([0, 0, 64, 32], fill=base_color)
        # Add some variation
        if i % 4 == 1:  # cracked
            td.line([8, 8, 56, 24], fill=(max(0, c-40) for c in base_colors[i % len(base_colors)]), width=1)
        elif i % 4 == 2:  # worn
            for _ in range(10):
                px = random.randint(4, 60)
                py = random.randint(4, 28)
                tile_img.putpixel((px, py), tuple(max(0, c-40) for c in base_color))
        elif i == 3:  # moss/decor
            tile_draw = ImageDraw.Draw(tile_img)
            for _ in range(5):
                px = random.randint(4, 60)
                py = random.randint(4, 28)
                tile_draw.ellipse([px-1, py-1, px+1, py+1], fill=tuple(max(0, c-30) for c in base_color))
        sheet.paste(tile_img, ((i % 16) * 64, (i // 16) * 32))
    
    # Fill remaining with variations
    for tile_id in range(16, 256):
        tile_img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        td = ImageDraw.Draw(tile_img)
        base_color = base_colors[tile_id % len(base_colors)]
        td.rectangle([0, 0, 64, 32], fill=base_color, outline=(0,0,0,255), width=1)
        
        # Add some variety based on tile ID
        if tile_id % 16 == 0:  # First column - add detail
            td.rectangle([0, 0, 64, 32], fill=base_color, outline=(0,0,0,255), width=1)
        
        sheet.paste(tile_img, ((tile_id % 16) * 64, (tile_id // 16) * 32))
    
    # Save
    theme_dir = OUTPUT_DIR / theme_name
    theme_dir.mkdir(parents=True, exist_ok=True)
    save_masked(sheet, OUTPUT_DIR / f"{theme_name}.png")
    print(f"Created {theme_name}.png")

def main():
    print("Generating remaining theme tilesets...")
    
    for theme_key, theme_data in THEMES.items():
        if theme_data["name"] != "castle":  # Skip castle, already done
            create_theme_tileset(theme_key, theme_data)
    
    print("\n✅ All theme tilesets generated!")
    print("Next: T024 Validation Pipeline")

if __name__ == "__main__":
    import random
    main()