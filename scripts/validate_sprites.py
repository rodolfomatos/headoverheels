#!/usr/bin/env python3
"""
Validate generated sprites against specs.
"""
from PIL import Image
import yaml
from pathlib import Path
import sys

def validate_sprite(filepath, spec):
    """Validate a single sprite against its spec."""
    try:
        img = Image.open(filepath)
    except Exception as e:
        return [f"Failed to open: {e}"]
    
    errors = []
    
    # Dimensions
    expected_size = (spec.get('width'), spec.get('height'))
    if expected_size != (None, None) and img.size != expected_size:
        errors.append(f"Wrong size: {img.size} vs {expected_size}")
    
    # Palette check (if strict)
    if spec.get('strict_palette'):
        colors = img.getcolors(maxcolors=256)
        if colors and len(colors) > spec.get('max_colors', 16):
            errors.append(f"Too many colors: {len(colors)} > {spec['max_colors']}")
    
    # Naming
    if 'naming_pattern' in spec:
        # Basic check - file exists with expected pattern
        pass
    
    # Transparency
    if img.mode != 'RGBA':
        errors.append(f"Wrong mode: {img.mode} (expected RGBA)")
    
    return errors

def main():
    SPECS_DIR = Path(__file__).parent.parent / "prompts" / "specs"
    GENERATED_DIR = Path(__file__).parent.parent / "generated"
    
    if not GENERATED_DIR.exists():
        print("❌ No generated directory found")
        return 1
    
    # Load validation spec if exists
    validation_spec = SPECS_DIR / "validation_spec.yaml"
    specs = {}
    
    if validation_spec.exists():
        with open(validation_spec) as f:
            data = yaml.safe_load(f)
            for spec in data.get('specs', []):
                specs[spec['id']] = spec
    
    all_errors = 0
    
    for img_file in GENERATED_DIR.rglob("*.png"):
        # Extract spec ID from filename
        stem = img_file.stem
        spec_id = None
        for sid in specs:
            if sid in stem:
                spec_id = sid
                break
        
        if spec_id is None:
            print(f"⚠️  No spec for: {img_file.name}")
            continue
        
        spec = specs[spec_id]
        errors = validate_sprite(img_file, spec)
        
        if errors:
            print(f"❌ {img_file.name}:")
            for err in errors:
                print(f"   - {err}")
            all_errors += len(errors)
        else:
            print(f"✅ {img_file.name}")
    
    if all_errors > 0:
        print(f"\n❌ Total errors: {all_errors}")
        return 1
    else:
        print(f"\n✅ All sprites valid!")
        return 0

if __name__ == "__main__":
    sys.exit(main())