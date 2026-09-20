#!/usr/bin/env python3
"""
TZX analyzer for Head over Heels ZX Spectrum original.
Extracts: loading screens, basic timing, tape structure.
Requires: tzxtools (pip install tzxtools) or fuse-emulator
"""
import os
import sys
import subprocess
from pathlib import Path

TZX_URL = "https://worldofspectrum.net/pub/sinclair/games/h/HeadOverHeels.tzx.zip"
TZX_PATH = Path(__file__).parent.parent / "docs" / "RESEARCH" / "HeadOverHeels.tzx"
OUTPUT_DIR = Path(__file__).parent.parent / "docs" / "RESEARCH" / "tzx-analysis"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def download_tzx():
    """Download the TZX file if not present."""
    if TZX_PATH.exists():
        print(f"TZX already exists at {TZX_PATH}")
        return
    
    import urllib.request
    import zipfile
    import io
    
    print(f"Downloading {TZX_URL}...")
    with urllib.request.urlopen(TZX_URL) as response:
        zip_data = response.read()
    
    with zipfile.ZipFile(io.BytesIO(zip_data)) as zf:
        # Find .tzx file in zip
        tzx_name = next((n for n in zf.namelist() if n.endswith('.tzx')), None)
        if not tzx_name:
            print("No .tzx file found in zip")
            return
        zf.extract(tzx_name, TZX_PATH.parent)
        extracted = TZX_PATH.parent / tzx_name
        if extracted != TZX_PATH:
            extracted.rename(TZX_PATH)
    print(f"Extracted to {TZX_PATH}")

def analyze_with_tzxtools():
    """Use tzxtools to analyze tape structure."""
    try:
        result = subprocess.run(
            ["tzxcat", "-i", str(TZX_PATH)],
            capture_output=True, text=True, timeout=30
        )
        output_file = OUTPUT_DIR / "tzx-info.txt"
        output_file.write_text(result.stdout)
        print(f"TZX info saved to {output_file}")
        print(result.stdout[:2000])
    except FileNotFoundError:
        print("tzxcat not found. Install with: pip install tzxtools")
    except subprocess.TimeoutExpired:
        print("tzxcat timed out")

def analyze_with_fuse():
    """Use Fuse emulator to capture screenshots/timing."""
    try:
        # Fuse can run headless and capture screenshots
        # fuse --graphics-filter=2x --machine=48 --tape=HeadOverHeels.tzx --auto-load
        result = subprocess.run([
            "fuse", 
            "--machine=48",
            "--tape", str(TZX_PATH),
            "--auto-load",
            "--graphics-filter=2x",
            # "--screen-capture", str(OUTPUT_DIR / "fuse-capture.png"),  # may not work this way
        ], capture_output=True, text=True, timeout=60)
        print("Fuse output:", result.stdout[:1000])
    except FileNotFoundError:
        print("Fuse emulator not found. Install: sudo apt install fuse-emulator-gtk")

def main():
    download_tzx()
    analyze_with_tzxtools()
    analyze_with_fuse()
    
    # Also fetch the instructions page
    import urllib.request
    instr_url = "https://worldofspectrum.net/item/0002259/"
    instr_file = OUTPUT_DIR / "instructions.html"
    try:
        urllib.request.urlretrieve(instr_url, instr_file)
        print(f"Instructions saved to {instr_file}")
    except Exception as e:
        print(f"Failed to fetch instructions: {e}")

if __name__ == "__main__":
    main()