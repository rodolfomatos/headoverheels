#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

import numpy as np
import yaml
from PIL import Image

# The game is a package under games/, so the sprite directory is an argument and
# the style files sit next to it. The Makefile passes both in.
PROJECT_ROOT = Path(__file__).parent.parent
GAME_ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else PROJECT_ROOT / "games" / "headoverheels"
DEFAULT_ASSETS_DIR = GAME_ROOT / "assets" / "sprites"
STYLE_DIR = GAME_ROOT / "style"
MANIFEST_NAME = "manifest.yaml"
SOURCE_TYPES = {"master", "source"}
FRAME_NAME = re.compile(r"^[a-z][a-z0-9_]*_\d{2,3}\.png$")
SOURCE_NAME = re.compile(r"^[a-z][a-z0-9_]*\.png$")
ASSET_ID = re.compile(r"^[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+$")

with open(STYLE_DIR / "palette.json") as handle:
    PALETTE = json.load(handle)
with open(STYLE_DIR / "geometry.json") as handle:
    GEOMETRY = json.load(handle)

BASE_COLORS = {value.lower() for value in PALETTE["base"].values()}
THEME_COLORS = {
    name: {value.lower() for value in colors.values()}
    for name, colors in PALETTE["themes"].items()
}
SHARED_COLORS = THEME_COLORS.get("shared", set())
EXTENDED_COLORS = THEME_COLORS.get("extended", set())
TILE_SIZE = (
    GEOMETRY["tile_geometry"]["logical_width"],
    GEOMETRY["tile_geometry"]["logical_height"],
)


def load_assets(assets_dir: Path):
    manifest = assets_dir / MANIFEST_NAME
    if not manifest.exists():
        raise FileNotFoundError(f"Manifest not found: {manifest}")
    document = yaml.safe_load(manifest.read_text()) or {}
    return document.get("assets", [])


def allowed_colors(palette: str) -> set[str]:
    colors = set(BASE_COLORS) | SHARED_COLORS
    colors.update(THEME_COLORS.get(palette, set()))
    if palette == "extended":
        colors.update(EXTENDED_COLORS)
    return colors


def open_asset(assets_dir: Path, asset: dict) -> Image.Image:
    image = Image.open(assets_dir / asset["file"])
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    region = asset.get("source_region")
    if region:
        box = (
            int(region["x"]),
            int(region["y"]),
            int(region["x"]) + int(region["width"]),
            int(region["y"]) + int(region["height"]),
        )
        image = image.crop(box)
    return image


def validate_manifest(assets: list[dict]) -> list[str]:
    errors = []
    ids = set()
    for asset in assets:
        asset_id = asset.get("id", "")
        if not asset_id:
            errors.append("Asset with empty id")
        elif asset_id in ids:
            errors.append(f"Duplicate asset id: {asset_id}")
        else:
            ids.add(asset_id)
        if not asset.get("file"):
            errors.append(f"{asset_id or '<empty id>'}: empty file path")
        if asset.get("alpha", "opaque") not in {"opaque", "binary", "smooth"}:
            errors.append(
                f"{asset_id}: invalid alpha mode {asset.get('alpha')}"
            )
    return errors


def validate_files(assets_dir: Path, assets: list[dict]) -> list[str]:
    errors = []
    for asset in assets:
        path = assets_dir / asset.get("file", "")
        if not path.exists():
            errors.append(f"{asset.get('id', '<empty id>')}: file not found: {asset.get('file', '')}")
    return errors


def validate_tiles(assets_dir: Path, assets: list[dict]) -> list[str]:
    errors = []
    for asset in assets:
        if asset.get("category") != "tile":
            continue
        try:
            image = open_asset(assets_dir, asset)
        except Exception as error:
            errors.append(f"{asset['id']}: {error}")
            continue
        expected = (
            int(asset["runtime_size"]["width"]),
            int(asset["runtime_size"]["height"]),
        )
        if image.size != expected:
            errors.append(f"{asset['id']}: region {image.size} != expected {expected}")
            continue
        if image.size != TILE_SIZE:
            continue
        data = np.array(image)
        y, x = np.mgrid[0:TILE_SIZE[1], 0:TILE_SIZE[0]]
        inside = (np.abs(x - TILE_SIZE[0] / 2) / (TILE_SIZE[0] / 2)) + (
            np.abs(y - TILE_SIZE[1] / 2) / (TILE_SIZE[1] / 2)
        ) <= 1.0
        outside = (~inside) & (data[:, :, 3] > 0)
        if np.any(outside):
            coords = np.where(outside)
            errors.append(
                f"{asset['id']}: non-transparent pixels outside diamond at {list(zip(coords[1][:5], coords[0][:5]))}"
            )
    return errors


def validate_dimensions(assets_dir: Path, assets: list[dict]) -> list[str]:
    errors = []
    for asset in assets:
        if asset.get("type") in SOURCE_TYPES:
            continue
        try:
            image = open_asset(assets_dir, asset)
        except Exception as error:
            errors.append(f"{asset['id']}: {error}")
            continue
        expected = (
            int(asset["runtime_size"]["width"]),
            int(asset["runtime_size"]["height"]),
        )
        if image.size != expected:
            errors.append(f"{asset['id']}: {image.size} != expected {expected}")
    return errors


def validate_palette(assets_dir: Path, assets: list[dict]) -> list[str]:
    errors = []
    for asset in assets:
        try:
            image = open_asset(assets_dir, asset)
        except Exception:
            continue
        allowed = allowed_colors(asset.get("palette", "base"))
        data = np.array(image)
        mask = data[:, :, 3] > 0
        if not np.any(mask):
            continue
        colors = data[:, :, :3][mask]
        unique, counts = np.unique(colors, axis=0, return_counts=True)
        for color, count in zip(unique, counts):
            hex_color = "#%02x%02x%02x" % tuple(int(value) for value in color)
            if hex_color not in allowed:
                errors.append(
                    f"{asset['id']}: disallowed color {hex_color} at {int(count)} pixels"
                )
    return errors


def validate_naming(assets: list[dict]) -> list[str]:
    errors = []
    for asset in assets:
        asset_id = asset.get("id", "")
        if asset_id and not ASSET_ID.fullmatch(asset_id):
            errors.append(f"Invalid asset id: {asset_id}")
        filename = Path(asset.get("file", "")).name
        pattern = (
            SOURCE_NAME
            if asset.get("type") in SOURCE_TYPES or asset.get("source_region")
            else FRAME_NAME
        )
        if filename and not pattern.fullmatch(filename):
            errors.append(f"Invalid physical filename: {filename}")
    return errors


def validate_alpha(assets_dir: Path, assets: list[dict]) -> list[str]:
    errors = []
    for asset in assets:
        mode = asset.get("alpha", "opaque")
        if mode == "smooth":
            continue
        try:
            image = open_asset(assets_dir, asset)
        except Exception:
            continue
        alpha = np.array(image)[:, :, 3]
        if mode == "opaque":
            invalid = (alpha > 0) & (alpha < 255)
        else:
            invalid = (alpha > 0) & (alpha < 255) & (alpha != 128)
        count = int(np.count_nonzero(invalid))
        if count > 100:
            errors.append(f"{asset['id']}: {count} pixels violate alpha mode {mode}")
    return errors


def validate_animations(assets: list[dict]) -> list[str]:
    errors = []
    groups = {}
    for asset in assets:
        if asset.get("category") == "character":
            key = (asset.get("character"), asset.get("animation"), asset.get("direction"))
            groups.setdefault(key, []).append(asset)
    for key, frames in groups.items():
        anchors = {(frame["anchor"]["x"], frame["anchor"]["y"]) for frame in frames}
        sizes = {
            (frame["runtime_size"]["width"], frame["runtime_size"]["height"])
            for frame in frames
        }
        if len(anchors) > 1:
            errors.append(f"{key}: inconsistent anchors {sorted(anchors)}")
        if len(sizes) > 1:
            errors.append(f"{key}: inconsistent sizes {sorted(sizes)}")
    return errors


def main() -> int:
    assets_dir = DEFAULT_ASSETS_DIR
    if not assets_dir.exists():
        print(f"Assets directory not found: {assets_dir}")
        return 1
    try:
        assets = load_assets(assets_dir)
    except Exception as error:
        print(str(error))
        return 1

    checks = {
        "manifest": validate_manifest(assets),
        "files": validate_files(assets_dir, assets),
        "dimensions": validate_dimensions(assets_dir, assets),
        "tiles": validate_tiles(assets_dir, assets),
        "palette": validate_palette(assets_dir, assets),
        "naming": validate_naming(assets),
        "alpha": validate_alpha(assets_dir, assets),
        "animations": validate_animations(assets),
    }

    print("Metadata-driven sprite validation\n")
    total = 0
    for name, errors in checks.items():
        total += len(errors)
        print(f"  {name:12s}: {'PASS' if not errors else 'FAIL'}")
        for error in errors:
            print(f"    - {error}")
    print(f"\nTotal errors: {total}")
    return 0 if total == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
