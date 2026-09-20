# Head over Heels — Sprite Generation System

**Status**: 🟡 Planning / Pilot Phase  
**Purpose**: Generate original, legally-safe sprites inspired by (not copying) the 1987 classic  
**Target**: ~400 assets across characters, tilesets, entities, UI, effects

---

## 📐 System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPRITE GENERATION PIPELINE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  REFERENCES          PROMPTS              GENERATION            │
│  ──────────          ───────              ──────────            │
│  • map1-4.png        → Style Guide    →  │  Character Gen     │  │
│  • manual scans      → Templates      →  │  Tileset Gen       │  │
│  • castle.tsx        → Asset Specs    →  │  Entity Gen        │  │
│  • analysis.md       → API Calls      →  │  UI/Icon Gen       │  │
│                                                                 │
│  VALIDATION          PACKING             DELIVERY              │
│  ──────────          ───────             ────────              │
│  • dims/palette      → TexturePacker   →  • @1x @2x @4x       │
│  • naming            → Atlases         →  • Flutter assets    │
│  • consistency       → mipmaps         →  • web/desktop too   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎨 Style Guide (Canonical)

### Original Hardware Constraints (ZX Spectrum 48K)
| Property | Value |
|----------|-------|
| Resolution | 256×192 |
| Colors | 8 (black, blue, red, magenta, green, cyan, yellow, white) |
| Brightness | 2 levels (normal + bright) |
| Attribute clash | 8×8 pixel blocks share colors |
| Isometric | 2:1 dimetric (64×32 logical tiles) |
| Tile size | 64×32 px (isometric) |

### Modern Reimagining Palette ("Spectrum+")
```
#000000  #0000CD  #CD0000  #CD00CD  #00CD00  #00CDCD  #CDCD00  #FFFFFF  ← Original 8
#000000  #0000FF  #FF0000  #FF00FF  #00FF00  #00FFFF  #FFFF00  #FFFFFF  ← Bright
#1A1A2E  #16213E  #0F3460  #533483  #0F5C3E  #006D77  #8A6F00  #E8E8E8  ← Spectrum+ Dark
#2D2D44  #1F4068  #3D0C0C  #6A1B9A  #1B5E20  #004D40  #A1882D  #F5F5F5  ← Spectrum+ Mid
#4A4A6A  #2E86C1  #E53935  #AB47BC  #43A047  #26A69A  #FDD835  #FFFFFF  ← Spectrum+ Bright
#E0E0EB  #BBDEFB  #FFCDD2  #E1BEE7  #C8E6C9  #B2EBF2  #FFF9C4  #FAFAFA  ← Spectrum+ Light
```

### Design Principles
1. **Retro but readable** — clean at 4× scale, no attribute clash artifacts
2. **Palette discipline** — 16-color "Spectrum+" per theme
3. **Silhouette first** — instant recognition at 16×16 px
4. **Isometric lighting** — top-left (315°), subtle AO on vertical faces
5. **Original but legal** — inspired by, never derivative of Ocean/Atari IP

---

## 📦 Asset Inventory

| Category | Count | Spec | Priority |
|----------|-------|------|----------|
| **Characters** | 2 × 8-dir × 6 anims | 48×48, 8×4 grid | 🔴 Critical |
| **Tilesets** | 6 themes × 256 tiles | 64×32 iso | 🔴 Critical |
| **Entities** | ~30 types | 64×32 or 48×48 | 🟠 High |
| **UI/Icons** | ~20 | 32×32, 24×24 | 🟡 Medium |
| **Effects** | ~10 | 32×32, 16×16 | 🟢 Low |

### Character Animation Spec
| Character | States | Frames | Directions | Canvas |
|-----------|--------|--------|------------|--------|
| **Head** | idle, walk, jump, climb, fire, combined | 4/8/4/4/3/6 | 8 | 384×192 |
| **Heels** | idle, walk, run, jump, carry, combined | 4/8/8/4/4/6 | 8 | 384×192 |
| **Combined** | all merged | varies | 8 | 384×192 |

---

## 📁 Directory Structure

```
prompts/
├── style_guide.md                 # This document
├── templates/
│   ├── character.j2               # Jinja2 template
│   ├── tileset.j2
│   ├── entity.j2
│   ├── ui_icon.j2
│   └── effect.j2
├── references/
│   ├── characters/                # Cropped from maps/manual
│   ├── tilesets/                  # Per-theme reference crops
│   ├── entities/
│   └── ui/
├── characters/
│   ├── head.md
│   ├── heels.md
│   └── combined.md
├── tilesets/
│   ├── castle.md
│   ├── egyptus.md
│   ├── penitentiary.md
│   ├── safari.md
│   ├── bookworld.md
│   └── moonbase.md
├── entities/
│   ├── fish.md
│   ├── rabbit.md
│   ├── crown.md
│   ├── spring.md
│   ├── switch.md
│   ├── conveyor.md
│   ├── teleport.md
│   ├── door.md
│   ├── hush_puppy.md
│   ├── monster.md
│   ├── guardian.md
│   ├── bag.md
│   ├── key.md
│   ├── doughnut.md
│   └── rabbit_powerup.md
├── ui/
│   ├── hud.md
│   ├── menus.md
│   ├── icons.md
│   └── planet_screen.md
└── effects/
    ├── particles.md
    └── screen_fx.md
```

---

## 🎯 Prompt Templates

### Character Template (`templates/character.j2`)
```jinja2
Generate a character sprite sheet for **{{ name }}** from "Head over Heels" reimagining.

STYLE CONTEXT:
- Original: ZX Spectrum 48K, 8-color palette, 2:1 dimetric isometric
- Modern: "Spectrum+" 16-color palette, clean at 4× scale, no attribute clash
- Lighting: Top-left (315°), subtle ambient occlusion on vertical faces
- Legal: Inspired by Jon Ritman/Bernie Drummond's 1987 design — NOT a copy

CHARACTER: {{ character_id }}
{{ description }}

SPECS:
- Frame size: {{ frame_width }}×{{ frame_height }} px
- Directions: {{ directions }} ({{ dir_list }})
- Animations: {{ animations }}
- Frame counts: {{ frame_counts }}
- Canvas layout: {{ canvas_grid }} ({{ total_w }}×{{ total_h }})

ANIMATION DETAILS:
{% for anim in animation_details %}
- {{ anim.name }}: {{ anim.frames }} frames, {{ anim.timing }}, {{ anim.notes }}
{% endfor %}

TECHNICAL:
- Output: PNG with alpha, power-of-2 texture preferred
- Naming: {{ naming_pattern }}
- Variants: @1x, @2x, @4x for Flutter
- Background: Transparent
- Constraints: {{ constraints }}

PALETTE: {{ palette_ref }}
{% if palette_override %}
OVERRIDE PALETTE:
{{ palette_override }}
{% endif %}

REFERENCE: {{ reference_notes }}
```

### Tileset Template (`templates/tileset.j2`)
```jinja2
Generate a complete isometric tileset for **{{ theme }}** theme.

STYLE CONTEXT:
- Original: ZX Spectrum castle.tsx (256 tiles, 16×16 grid, 64×32 iso)
- Modern: "Spectrum+" palette, clean at 4×, power-of-2 atlas packing
- Lighting: Top-left (315°), subtle AO on vertical faces, consistent across tiles

THEME: {{ theme }}
{{ theme_description }}

SPECS:
- Tile size: 64×32 px (isometric)
- Grid: 16×16 = 256 tiles
- Source image: {{ tileset_w }}×{{ tileset_h }} (power of 2)
- Categories: {{ categories }}

TILE BREAKDOWN:
{% for cat in tile_categories %}
- {{ cat.name }} (IDs {{ cat.id_range }}): {{ cat.count }} tiles
  {{ cat.description }}
  {{ cat.animation_notes }}
{% endfor %}

TECHNICAL:
- Output: Single PNG {{ tileset_w }}×{{ tileset_h }} + JSON manifest
- Tile naming: {{ naming_pattern }}
- Variants: @1x (64×32), @2x (128×64), @4x (256×128)
- Packing: TexturePacker, max 2048×2048
- Background: Transparent

PALETTE: {{ theme_palette }}
{% if palette_override %}
THEME PALETTE OVERRIDE:
{{ palette_override }}
{% endif %}

REFERENCE: {{ reference_notes }}
```

### Entity Template (`templates/entity.j2`)
```jinja2
Generate entity sprite for **{{ entity_name }}**.

STYLE CONTEXT: (same as character template)

ENTITY: {{ entity_id }}
{{ description }}

SPECS:
- Base size: {{ base_w }}×{{ base_h }} px
- Animations: {{ animations }}
- Frames per anim: {{ frame_counts }}
- Directions: {{ directions }}

ANIMATION DETAILS:
{% for anim in animation_details %}
- {{ anim.name }}: {{ anim.frames }} frames, {{ anim.loop }}, {{ anim.timing }}
{% endfor %}

TECHNICAL:
- Output: PNG with alpha
- Naming: {{ naming_pattern }}
- Variants: @1x, @2x, @4x
- Constraints: {{ constraints }}

PALETTE: {{ palette_ref }}

REFERENCE: {{ reference_notes }}
```

---

## 🔧 Generation Pipeline Scripts

### `scripts/generate_prompts.py`
```python
#!/usr/bin/env python3
"""
Auto-expand Jinja2 templates → API-ready prompt files.
"""
import jinja2
import yaml
from pathlib import Path

TEMPLATES_DIR = Path("prompts/templates")
SPECS_DIR = Path("prompts/specs")
OUTPUT_DIR = Path("prompts/generated")

def load_spec(spec_path):
    with open(spec_path) as f:
        return yaml.safe_load(f)

def render_template(template_name, spec):
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(TEMPLATES_DIR),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    template = env.get_template(template_name)
    return template.render(**spec)

def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    for spec_file in SPECS_DIR.glob("*.yaml"):
        spec = load_spec(spec_file)
        template_name = f"{spec['category']}.j2"
        prompt = render_template(template_name, spec)
        
        out_file = OUTPUT_DIR / f"{spec['id']}.prompt.txt"
        out_file.write_text(prompt)
        print(f"Generated: {out_file}")

if __name__ == "__main__":
    main()
```

### `scripts/validate_sprites.py`
```python
#!/usr/bin/env python3
"""
Validate generated sprites against specs.
"""
from PIL import Image
import json
from pathlib import Path

def validate_sprite(filepath, spec):
    img = Image.open(filepath)
    errors = []
    
    # Dimensions
    if img.size != (spec['width'], spec['height']):
        errors.append(f"Wrong size: {img.size} vs {spec['width']}×{spec['height']}")
    
    # Palette check (if strict)
    if spec.get('strict_palette'):
        colors = img.getcolors(maxcolors=16)
        if colors and len(colors) > spec['max_colors']:
            errors.append(f"Too many colors: {len(colors)} > {spec['max_colors']}")
    
    # Naming
    expected = spec['naming_pattern'].format(**spec)
    if filepath.name != expected:
        errors.append(f"Wrong name: {filepath.name} vs {expected}")
    
    return errors

def main():
    spec_file = Path("prompts/specs/validation_spec.yaml")
    if not spec_file.exists():
        print("No validation spec found")
        return
    
    with open(spec_file) as f:
        specs = yaml.safe_load(f)
    
    for spec in specs:
        files = list(Path("generated").glob(spec['glob']))
        for f in files:
            errs = validate_sprite(f, spec)
            if errs:
                print(f"❌ {f}: {errs}")
            else:
                print(f"✅ {f}")

if __name__ == "__main__":
    main()
```

### `scripts/pack_atlas.py`
```python
#!/usr/bin/env python3
"""
Pack sprites into atlases using TexturePacker CLI.
"""
import subprocess
from pathlib import Path

def pack_atlas(input_dir, output_name, max_size=2048):
    cmd = [
        "TexturePacker",
        "--format", "json",
        "--data", f"assets/atlases/{output_name}.json",
        "--sheet", f"assets/atlases/{output_name}.png",
        "--max-size", str(max_size),
        "--scale", "1",
        "--variant", "1:0.5,0.25",  # @1x, @2x, @4x
        "--opt", "RGBA8888",
        "--trim-mode", "Trim",
        "--allow-free-size",
        "--disable-rotation",
        str(Path(input_dir))
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ TexturePacker failed: {result.stderr}")
    else:
        print(f"✅ Packed {output_name}")

if __name__ == "__main__":
    pack_atlas("generated/characters", "chars")
    pack_atlas("generated/tilesets", "tiles")
    pack_atlas("generated/entities", "entities")
    pack_atlas("generated/ui", "ui")
```

---

## 🚀 Execution Plan

### Phase 1: Pilot (Week 1)
1. Extract reference crops from `map1-4.png`, manual → `prompts/references/`
2. Build style embedding (CLIP) from references
3. Create Jinja2 templates + YAML specs for pilot batch
4. **Pilot batch**: 1 character (Head) + 1 tileset (Castle) + 1 entity (Fish)
4. Review → iterate on style
5. Lock style guide

### Phase 2: Full Generation (Week 2-3)
1. Generate all prompt files from templates
5. Batch generation per category (characters → tilesets → entities → UI)
6. Validation pass (dims, palette, naming)
6. Atlas packing → Flutter assets

### Phase 3: Integration (Week 3)
7. Replace placeholder assets in Flutter project
8. Test in-game
9. Iteration on problematic assets

---

## 📋 YAML Spec Format (Example)

### Character Spec (`specs/characters/head.yaml`)
```yaml
id: head
category: character
template: character.j2
name: "Head"
character_id: head
description: |
  Headus Mouthion - descended from flying reptile, rudimentary wings.
  Proud, curious, vulnerable alone. Rounded head, small wings, expressive eyes.
  Colors: Green body (Spectrum bright green), yellow wings.

frame_width: 48
frame_height: 48
directions: 8
dir_list: "N, NE, E, SE, S, SW, W, NW"
animations: ["idle", "walk", "jump", "climb", "fire", "combined"]
frame_counts: {"idle": 4, "walk": 8, "jump": 4, "climb": 4, "fire": 3, "combined": 6}
canvas_grid: "8×4"
total_w: 384
total_h: 192

animation_details:
  - name: idle
    frames: 4
    timing: "200ms/frame, subtle breathing"
    notes: "subtle wing flutter, eye blink"
  - name: walk
    frames: 8
    timing: "100ms/frame"
    notes: "smooth 8-dir, wing-assisted steps"
  - name: jump
    frames: 4
    timing: "150ms/frame, parabolic arc"
    notes: "rising, peak, falling, landing"
  - name: climb
    frames: 4
    timing: "200ms/frame"
    notes: "wing-assisted ladder climb"
  - name: fire
    frames: 3
    timing: "100ms/frame"
    notes: "doughnut throw, recoil"
  - name: combined
    frames: 6
    timing: "200ms/frame"
    notes: "Head on Heels shoulders, shared anim"

canvas_grid: "8×4"
total_w: 384
total_h: 192

naming_pattern: "character_head_{dir}_{frame:02d}.png"
constraints: "transparent_bg, isometric_grid, loopable_walk"
palette_ref: "spectrum_plus"
palette_override: |
  Primary: #43A047 (green body)
  Accent: #FDD835 (yellow wings)
  Outline: #1B5E20 (dark green)
  Highlight: #81C784 (light green)

reference_notes: "Based on map1.jpg castle entrance character, manual page 3 illustration"
```

---

## ✅ Validation Checklist

### Per Asset
- [ ] Dimensions match spec exactly
- [ ] Palette ≤ 16 colors (theme-specific)
- [ ] Transparent background
- [ ] Naming convention followed
- [ ] Animations loop seamlessly
- [ ] Directions visually consistent
- [ ] Silhouette readable at 16×16
- [ ] No attribute clash artifacts

### Per Atlas
- [ ] Max 2048×2048
- [ ] Power-of-2 dimensions
- [ ] @1x, @2x, @4x variants
- [ ] JSON manifest with frame data
- [ ] No texture bleeding (1px padding)

---

## 🚀 Quick Start

```bash
# 1. Install dependencies
pip install jinja2 pyyaml pillow
npm install -g texturepacker  # or download binary

# 2. Extract references
python scripts/extract_refs.py  # crops from maps/manual

# 3. Generate pilot prompts
python scripts/generate_prompts.py --pilot

# 4. Review pilot batch, lock style
# 5. Full generation
python scripts/generate_prompts.py --all

# 6. Validate
python scripts/validate_sprites.py

# 7. Pack atlases
python scripts/pack_atlas.py

# 8. Copy to Flutter
cp -r assets/atlases/* /opt/headoverheels/headoverheels/assets/atlases/
```

---

## 📄 License & Legal

- **Generated assets**: Original work, MIT licensed (same as project)
- **Reference use**: Fair use for style analysis only
- **No Ocean/Atari IP** — clean-room inspired reimagining
- **Attribution**: "Inspired by Head over Heels (1987, Ocean Software)"

---

## 📅 Timeline

| Week | Milestone |
|------|-----------|
| 1 | Pilot batch + style lock |
| 2 | Characters + tilesets |
| 3 | Entities + UI + integration |
| 4 | Polish + Flutter integration |

---

*Last updated: 2026-09-20*  
*Next: Extract reference crops → build pilot batch*