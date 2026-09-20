#!/usr/bin/env python3
"""
Sprite Generation Pipeline - Auto-expand Jinja2 templates → API-ready prompt files.
"""
import jinja2
import yaml
from pathlib import Path
import sys

TEMPLATES_DIR = Path(__file__).parent.parent / "prompts" / "templates"
SPECS_DIR = Path(__file__).parent.parent / "prompts" / "specs"
OUTPUT_DIR = Path(__file__).parent.parent / "prompts" / "generated"

def load_spec(spec_path):
    with open(spec_path, 'r') as f:
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
    
    if len(sys.argv) > 1 and sys.argv[1] == "--pilot":
        # Pilot batch only
        spec_files = [
            SPECS_DIR / "characters" / "head.yaml",
            SPECS_DIR / "tilesets" / "castle.yaml",
            SPECS_DIR / "entities" / "fish.yaml",
        ]
    else:
        spec_files = list(SPECS_DIR.rglob("*.yaml"))
    
    generated = 0
    for spec_file in spec_files:
        if not spec_file.exists():
            print(f"⚠️  Spec not found: {spec_file}")
            continue
            
        spec = load_spec(spec_file)
        template_name = f"{spec['category']}.j2"
        template_path = TEMPLATES_DIR / template_name
        
        if not template_path.exists():
            print(f"⚠️  Template not found: {template_name}")
            continue
        
        prompt = render_template(template_name, spec)
        
        out_file = OUTPUT_DIR / f"{spec['id']}.prompt.txt"
        out_file.write_text(prompt)
        print(f"✅ Generated: {out_file}")
        generated += 1
    
    print(f"\n📊 Total generated: {generated}")

if __name__ == "__main__":
    main()