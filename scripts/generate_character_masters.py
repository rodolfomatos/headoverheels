#!/usr/bin/env python3
"""
Generate character master sprites for Head over Heels 2026 reimagining.
Creates master sprite sheets for Head and Heels characters.
"""

from PIL import Image, ImageDraw
from pathlib import Path

# Output directories
OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "characters"
HEAD_DIR = OUTPUT_DIR / "head"
HEELS_DIR = OUTPUT_DIR / "heels"
DUO_DIR = OUTPUT_DIR / "duo"

for d in [HEAD_DIR, HEELS_DIR, DUO_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Color palette - Spectrum+ (2026)
# Based on VISUAL_DESIGN_SYSTEM.md
PALETTE = {
    # Spectrum DNA colors
    "black": "#000000",
    "dark_blue": "#0000D8",
    "blue": "#3030FF",
    "dark_red": "#D00000",
    "red": "#FF2020",
    "dark_green": "#008000",
    "green": "#20C020",  # Head body
    "dark_cyan": "#008080",
    "cyan": "#20D8D8",
    "dark_yellow": "#C0A000",
    "yellow": "#FFD820",  # Head wings, highlights
    "dark_magenta": "#A000A0",
    "magenta": "#E020E0",
    "grey": "#808080",
    "light_grey": "#C0C0C0",
    "white": "#FFFFFF",
    # Head specific
    "head_green": "#43A047",
    "head_wing_yellow": "#FDD835",
    "head_dark_green": "#1B5E20",
    "head_light_green": "#81C784",
    # Heels specific
    "heels_orange_red": "#E53935",
    "heels_yellow": "#FDD835",
    "heels_dark_red": "#B71C1C",
    "heels_light_red": "#EF9A9A",
    # Shadows/outlines
    "outline_dark": "#1B5E20",
    "outline_heels": "#B71C1C",
}

def draw_head(draw, x, y, w, h, facing="front"):
    """Draw Head character - green rounded head with wings"""
    cx = x + w // 2
    cy = y + h // 2
    
    # Colors
    body_color = hex_to_rgb(PALETTE["head_green"])
    wing_color = hex_to_rgb(PALETTE["head_wing_yellow"])
    dark_green = hex_to_rgb(PALETTE["head_dark_green"])
    light_green = hex_to_rgb(PALETTE["head_light_green"])
    outline = hex_to_rgb(PALETTE["outline_dark"])
    yellow = hex_to_rgb(PALETTE["yellow"])
    white = hex_to_rgb(PALETTE["white"])
    
    # Head body (rounded)
    head_radius = min(w, h) // 2 - 2
    head_center_y = cy - 2
    
    # Body circle
    draw.ellipse(
        [cx - head_radius, head_center_y - head_radius,
         cx + head_radius, head_center_y + head_radius],
        fill=body_color, outline=outline, width=1
    )
    
    # Highlight on top-left
    draw.ellipse(
        [cx - head_radius + 2, head_center_y - head_radius + 2,
         cx - head_radius + 8, head_center_y - head_radius + 8],
        fill=light_green
    )
    
    # Wings
    if facing in ["front", "side", "3/4"]:
        # Left wing
        wing_points = [
            (cx - head_radius - 2, head_center_y - 4),
            (cx - head_radius - 10, head_center_y - 12),
            (cx - head_radius - 4, head_center_y - 2),
        ]
        draw.polygon(wing_points, fill=wing_color, outline=outline)
        
        # Right wing
        wing_points = [
            (cx + head_radius + 2, head_center_y - 4),
            (cx + head_radius + 10, head_center_y - 12),
            (cx + head_radius + 4, head_center_y - 2),
        ]
        draw.polygon(wing_points, fill=wing_color, outline=outline)
    
    # Eyes
    eye_y = head_center_y - 4
    # Left eye
    draw.ellipse([cx - 8, eye_y - 3, cx - 4, eye_y + 3], fill=PALETTE["black"])
    draw.ellipse([cx - 7, eye_y - 2, cx - 5, eye_y], fill=PALETTE["white"])
    # Right eye
    draw.ellipse([cx + 4, eye_y - 3, cx + 8, eye_y + 3], fill=PALETTE["black"])
    draw.ellipse([cx + 5, eye_y - 2, cx + 7, eye_y], fill=PALETTE["white"])
    
    # Mouth (simple line)
    draw.line([cx - 4, head_center_y + 6, cx + 4, head_center_y + 6], fill=PALETTE["black"], width=1)
    
    # Shadow
    shadow_y = cy + head_radius + 4
    draw.ellipse([cx - head_radius + 2, shadow_y, cx + head_radius - 2, shadow_y + 3], 
                 fill=(0, 0, 0, 80))

def draw_heels(draw, x, y, w, h, facing="front"):
    """Draw Heels character - orange/red body, no arms, big boots"""
    cx = x + w // 2
    cy = y + h // 2
    
    body_color = hex_to_rgb(PALETTE["heels_orange_red"])
    accent_color = hex_to_rgb(PALETTE["heels_yellow"])
    dark_red = hex_to_rgb(PALETTE["heels_dark_red"])
    light_red = hex_to_rgb(PALETTE["heels_light_red"])
    outline = hex_to_rgb(PALETTE["outline_heels"])
    yellow = hex_to_rgb(PALETTE["yellow"])
    white = hex_to_rgb(PALETTE["white"])
    
    # Body - rounded rectangle
    body_w = w - 4
    body_h = h - 12
    body_x = x + 2
    body_y = y + 2
    
    # Body rectangle with rounded corners
    draw.rounded_rectangle(
        [body_x, body_y, body_x + body_w, body_y + body_h],
        radius=6, fill=body_color, outline=outline, width=1
    )
    
    # Highlight on top-left
    draw.rounded_rectangle(
        [body_x + 2, body_y + 2, body_x + 8, body_y + 8],
        radius=3, fill=light_red
    )
    
    # Legs/Boots (big and distinctive)
    boot_w = 14
    boot_h = 10
    left_boot_x = cx - boot_w - 2
    right_boot_x = cx + 4
    boot_y = cy + 12
    
    # Left boot
    draw.rounded_rectangle(
        [left_boot_x, boot_y, left_boot_x + boot_w, boot_y + boot_h],
        radius=3, fill=dark_red, outline=outline, width=1
    )
    # Boot highlight
    draw.line([left_boot_x + 2, boot_y + 2, left_boot_x + boot_w - 2, boot_y + 2], 
              fill=light_red, width=2)
    
    # Right boot
    draw.rounded_rectangle(
        [right_boot_x, boot_y, right_boot_x + boot_w, boot_y + boot_h],
        radius=3, fill=dark_red, outline=outline, width=1
    )
    draw.line([right_boot_x + 2, boot_y + 2, right_boot_x + boot_w - 2, boot_y + 2], 
              fill=light_red, width=2)
    
    # Eyes (high on face)
    eye_y = cy - 8
    # Left eye
    draw.ellipse([cx - 10, eye_y - 3, cx - 6, eye_y + 3], fill=PALETTE["black"])
    draw.ellipse([cx - 9, eye_y - 2, cx - 7, eye_y], fill=PALETTE["white"])
    # Right eye
    draw.ellipse([cx + 6, eye_y - 3, cx + 10, eye_y + 3], fill=PALETTE["black"])
    draw.ellipse([cx + 7, eye_y - 2, cx + 9, eye_y], fill=PALETTE["white"])
    
    # Shadow
    shadow_y = y + h - 4
    draw.ellipse([cx - w//2 + 4, shadow_y, cx + w//2 - 4, shadow_y + 3], 
                 fill=(0, 0, 0, 80))


def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def create_character_sheet(character_name, output_dir, draw_func, 
                           frame_w, frame_h, cols, rows, directions, animations):
    """Create a character sprite sheet with multiple animations and directions."""
    
    sheet_w = frame_w * cols
    sheet_h = frame_h * rows
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    
    frame_idx = 0
    for row, anim in enumerate(animations):
        for col, direction in enumerate(directions):
            if frame_idx >= len(animations) * len(directions):
                break
            x = col * frame_w
            y = row * frame_h
            
            # Draw the character
            draw_func(ImageDraw.Draw(sheet), x, y, frame_w, frame_h, 
                     facing=direction if direction in ["front", "side", "3/4"] else "front")
            
            frame_idx += 1
    
    output_path = Path(output_dir) / f"{character_name}_master.png"
    sheet.save(output_path)
    print(f"Created {output_path} ({sheet_w}x{sheet_h})")
    
    # Also create individual frames for flexibility
    frames_dir = Path(output_dir) / "frames"
    frames_dir.mkdir(exist_ok=True)
    
    frame_idx = 0
    for row, anim in enumerate(animations):
        for col, direction in enumerate(directions):
            if frame_idx >= len(animations) * len(directions):
                break
            x = col * frame_w
            y = row * frame_h
            frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
            frame_draw = ImageDraw.Draw(frame)
            draw_func(frame_draw, 0, 0, frame_w, frame_h, facing=direction)
            
            frame_path = frames_dir / f"{character_name}_{anim}_{direction}_{frame_idx+1:02d}.png"
            frame.save(frame_path)
            frame_idx += 1
    
    print(f"Created {frame_idx} frames in {frames_dir}")


def create_head_masters():
    """Create Head character master sprites"""
    print("Creating Head master sprites...")
    
    HEAD_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "head"
    HEAD_DIR.mkdir(parents=True, exist_ok=True)
    
    # Master sheet: 4 directions (front, side, back, 3/4) x 3 poses (idle, walk, jump)
    directions = ["front", "side", "3q", "back"]
    poses = ["idle", "walk", "jump"]
    
    frame_w, frame_h = 48, 48
    cols = len(directions)
    rows = len(poses)
    
    sheet = Image.new("RGBA", (frame_w * cols, frame_h * rows), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    
    for row, pose in enumerate(poses):
        for col, direction in enumerate(directions):
            x = col * 48
            y = row * 48
            draw_head(draw, x, y, 48, 48, facing=direction)
    
    sheet_path = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "head" / "head_master.png"
    sheet.save(sheet_path)
    print(f"Created {sheet_path}")
    
    # Individual frames
    frames_dir = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "head" / "frames"
    frames_dir.mkdir(exist_ok=True)
    
    idx = 0
    for pose in poses:
        for direction in directions:
            frame = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
            draw = ImageDraw.Draw(frame)
            draw_head(draw, 0, 0, 48, 48, facing=direction)
            frame.save(frames_dir / f"head_{pose}_{direction}_{idx+1:02d}.png")
            idx += 1
    
    print(f"Created {idx} frames for Head")


def create_heels_masters():
    """Create Heels character master sprites"""
    print("Creating Heels master sprites...")
    
    HEELS_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "heels"
    HEELS_DIR.mkdir(parents=True, exist_ok=True)
    
    directions = ["front", "side", "3q", "back"]
    poses = ["idle", "walk", "run", "jump", "carry"]
    
    frame_w, frame_h = 48, 56
    cols = len(directions)
    rows = len(poses)
    
    sheet = Image.new("RGBA", (frame_w * cols, frame_h * rows), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    
    for row, pose in enumerate(poses):
        for col, direction in enumerate(directions):
            x = col * frame_w
            y = row * frame_h
            draw_heels(draw, x, y, frame_w, frame_h, facing=direction)
    
    sheet_path = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "heels" / "heels_master.png"
    sheet.save(sheet_path)
    print(f"Created {sheet_path}")
    
    # Individual frames
    frames_dir = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "heels" / "frames"
    frames_dir.mkdir(exist_ok=True)
    
    idx = 0
    for pose in poses:
        for direction in directions:
            frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
            draw = ImageDraw.Draw(frame)
            draw_heels(draw, 0, 0, frame_w, frame_h, facing=direction)
            frame.save(frames_dir / f"heels_{pose}_{direction}_{idx+1:02d}.png")
            idx += 1
    
    print(f"Created {idx} frames for Heels")


def create_duo_composition():
    """Create Duo (Head + Heels combined) composition preview"""
    print("Creating Duo composition preview...")
    
    DUO_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "duo"
    DUO_DIR.mkdir(parents=True, exist_ok=True)
    
    # Create a composition showing Head on Heels
    frame_w, frame_h = 56, 64
    sheet = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    
    # Draw Heels at bottom
    draw_heels(draw, 4, 8, 48, 56, facing="front")
    # Draw Head on top (offset)
    draw_head(draw, 4, 0, 48, 48, facing="front")
    
    # Add shadow
    draw.ellipse([14, 60, 42, 65], fill=(0, 0, 0, 80))
    
    sheet_path = Path(__file__).parent.parent / "assets" / "sprites" / "characters" / "duo" / "duo_idle_front.png"
    sheet.save(sheet_path)
    print(f"Created {sheet_path}")


def main():
    print("Generating character master sprites...")
    
    create_head_masters()
    create_heels_masters()
    create_duo_composition()
    
    print("\n✅ Character master sprites generated!")
    print("Next steps:")
    print("1. Review generated assets")
    print("2. Integrate with SpriteRegistry")
    print("3. Update CharacterComponent to use real sprites")


if __name__ == "__main__":
    main()