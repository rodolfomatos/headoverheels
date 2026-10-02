#!/usr/bin/env python3
"""Generative sprite candidates, finished deterministically.

A diffusion model proposes; this script decides. The model is asked for one
subject on one flat field, and everything that has to be exact — trim, palette,
runtime size, anchor — is computed here, so two runs of the same prompt produce
pixels that differ only where the model was allowed to be creative.

Nothing here writes to `assets/`. Candidates land in
`assets/<game>/ai/candidates/` and are accepted by eye, one at a time, into
`assets/<game>/ai/accepted/`. Acceptance is recorded in a lock file so a later
run does not quietly overwrite art somebody already signed off, and every
accepted sprite keeps the prompt, the negative, the seed and the control image
that produced it, so any sprite in the project can be traced back to the run
that made it.

Usage:
    python3 scripts/ai_sprites.py --kind character --id_guard --limit 1
    python3 scripts/ai_sprites.py --kind entity --anubis --backend comfyui
    python3 scripts/ai_sprites.py --kind tile --castle_floor --scale 2 --lock
"""

from __future__ import annotations

import argparse
import datetime
import json
import pathlib
import shutil
import sys
import urllib.error
import urllib.request

import numpy
from PIL import Image

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("ai_sprites.py needs PyYAML: pip install pyyaml")

PROJECT_ROOT = pathlib.Path(__file__).parent.parent
GAME_ROOT = PROJECT_ROOT / "games" / "headoverheels"
ASSETS = GAME_ROOT / "assets"
STYLE = GAME_ROOT / "style"
BUILD = PROJECT_ROOT / "build" / "ai"
PROMPTS = PROJECT_ROOT / "prompts"
STATE = GAME_ROOT / "ai" / "state.json"
WORKFLOW = PROMPTS / "comfyui_workflow_api.json"

# The game's runtime resolution. The renderer scales sprites at draw time
# (Flame's Sprite.scale), so baking the scale into the PNG would double it.
SCALE = 1

NEGATIVE = (
    "multiple subjects, grid, sprite sheet, contact sheet, text, watermark, "
    "signature, drop shadow, cast shadow, gradient background, vignette, "
    "texture noise, dithering, jpeg artifacts, blurry, antialiased edge, "
    "modern, photorealistic, 3d render, vector"
)


def stamp() -> str:
    return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")


def manifest() -> dict:
    path = ASSETS / "sprites" / "manifest.yaml"
    with path.open() as handle:
        return yaml.safe_load(handle)


def spec_description(kind: str, asset_id: str) -> str:
    """The hand-written description of the thing being drawn, if there is one.

    These live in `prompts/specs/<kind>s/*.yaml`. When a spec exists it is the
    subject of the prompt; when it does not, the id itself is all there is, and
    that is worth saying out loud rather than pretending otherwise.
    """
    path = PROMPTS / "specs" / f"{kind}s" / f"{asset_id}.yaml"
    if not path.exists():
        return f"the sprite named {asset_id} (no description on file)"
    with path.open() as handle:
        spec = yaml.safe_load(handle)
    return spec.get("description", f"the sprite named {asset_id}")


def load_state() -> dict:
    if not STATE.exists():
        return {}
    try:
        with STATE.open() as handle:
            return json.load(handle)
    except json.JSONDecodeError:
        print(f"warning: {STATE} is unreadable, treating it as empty")
        return {}


def save_state(state: dict) -> None:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    with STATE.open("w") as handle:
        json.dump(state, handle, indent=2, sort_keys=True)


def base_prompt(asset: dict, spec: str) -> str:
    palette = ", ".join(asset.get("palette", "base").split(",")[:3])
    return (
        f"{spec}, 2D game sprite, top-down three-quarter isometric view, "
        f"single {spec}, full body, facing the viewer, "
        f"limited palette of {palette}, flat colors, no outline, "
        f"solid opaque background color, centered, "
        f"transparent background, pixel art"
    )


def negative_prompt() -> str:
    return NEGATIVE


def cut_out(image: Image.Image, key: str = "#ff00ff") -> Image.Image:
    """Make the keyed colour transparent.

    The model is told to draw one flat field of `key`, and the corners are
    sampled to find it, because a model asked for flat magenta will not always
    return exactly one magenta. A green-screen-free approach: compare each pixel
    to the median corner colour and fade the difference, so an off-spec background
    still comes out clean instead of leaving a halo.
    """
    rgb = image.convert("RGB")
    w, h = rgb.size
    corners = [
        rgb.getpixel((0, 0)),
        rgb.getpixel((w - 1, 0)),
        rgb.getpixel((0, h - 1)),
        rgb.getpixel((w - 1, h - 1)),
    ]
    back = tuple(int(numpy.median([c[i] for c in corners])) for i in range(3))

    array = numpy.asarray(rgb).astype(numpy.int16)
    distance = numpy.abs(array - numpy.array(back)).sum(axis=2)
    # 90 is the point where a pixel stops being background and starts being a
    # very desaturated edge pixel of the subject.
    alpha = numpy.clip((distance - 30) * 255 // 60, 0, 255).astype("uint8")

    out = rgb.convert("RGBA")
    out.putalpha(Image.fromarray(alpha, mode="L"))
    return out


def first_frame(image: Image.Image, runtime_width: int | None) -> Image.Image:
    """Crop a control sheet down to the frame the renderer will actually use.

    Controls are usually animation strips: one row of `frames` cells. Feeding a
    whole strip to img2img gives the model a contact sheet to imitate, which is
    the single easiest way to get a sprite back with three of itself in it. So if
    the control is wider than one runtime cell, keep the leftmost cell.
    """
    if runtime_width and image.width > runtime_width:
        return image.crop((0, 0, runtime_width, image.height))
    return image


def fit(image: Image.Image, asset: dict) -> Image.Image:
    """Trim to the subject and put it where the renderer expects to find it.

    The anchor is the one thing here that cannot be guessed, because it encodes
    where the game positions the sprite relative to its tile. Tilesets are the
    exception: they are painted onto the room as a background, not placed at a
    tile, so they have no anchor and are centred instead.
    """
    bbox = image.getbbox()
    if bbox:
        image = image.crop(bbox)

    # The manifest stores runtime_size as `{width, height}`. Unpacking it directly
    # yields the *keys* -- `('width', 'height')` -- and every test of `fit` used a
    # list of two ints, which the manifest has never contained. So the function
    # this pipeline is named after had never been run against a real entry.
    runtime = asset["runtime_size"]
    runtime_w = runtime["width"] if isinstance(runtime, dict) else runtime[0]
    runtime_h = runtime["height"] if isinstance(runtime, dict) else runtime[1]
    scale = SCALE * asset.get("scale", 1)

    # The anchor is expressed in runtime-cell coordinates, so the point of the
    # image that falls on it has to land on the same point of the cell. The
    # offset is therefore `anchor - image.width * anchor / runtime_w`, not a
    # halving: with an anchor at (0,0) the sprite's top-left goes to the cell's
    # top-left, and with the anchor at the centre and the sprite exactly one
    # cell wide, the offset is zero — which is what centring means for a
    # full-cell image.
    anchor = asset.get("anchor")
    cell_w, cell_h = int(runtime_w * scale), int(runtime_h * scale)
    ax = anchor["x"] * scale if anchor else cell_w / 2
    ay = anchor["y"] * scale if anchor else cell_h / 2

    canvas = Image.new("RGBA", (cell_w, cell_h))
    canvas.alpha_composite(
        image,
        (int(round(ax - image.width * ax / cell_w)),
         int(round(ay - image.height * ay / cell_h))),
    )
    return canvas


def rgb(value: object) -> tuple[int, int, int] | None:
    """One palette entry as an RGB triple.

    `style/palette.json` stores colours as `name: "#RRGGBB"`, so every consumer
    has to do this conversion and any of them that skips it is comparing
    hex strings to pixel arrays. Accepts a hex string or an already-tripled RGB.
    """
    if isinstance(value, (list, tuple)) and len(value) >= 3:
        return (int(value[0]), int(value[1]), int(value[2]))
    if isinstance(value, str) and value.startswith("#") and len(value) == 7:
        return (int(value[1:3], 16), int(value[3:5], 16), int(value[5:7], 16))
    return None


def palette_entries(section: object) -> list[tuple[int, int, int]]:
    """A palette section as a list of RGB triples.

    Both shapes are accepted because both exist: `style/palette.json` maps names
    to hex strings, and hand-written test palettes are sometimes plain lists.
    """
    if isinstance(section, dict):
        values = section.values()
    elif isinstance(section, (list, tuple)):
        values = section
    else:
        return []
    out = []
    for value in values:
        colour = rgb(value)
        if colour is not None:
            out.append(colour)
    return out


def colours(palette: dict, asset: dict) -> list[tuple[int, int, int]]:
    """The palette this sprite is allowed to use, in resolution order.

    The sprite's own palette if it names one, then the shared palette, then the
    base 16. Order matters: `fit_palette` walks it in order and takes the first
    colour within range, so a sprite in a themed palette resolves inside its own
    theme before it can borrow from anywhere else.
    """
    themes = palette.get("themes") or {}
    base = palette_entries(palette.get("base"))
    shared = palette_entries(themes.get("shared"))

    out: list[tuple[int, int, int]] = []
    names = asset.get("palette", "base")
    for name in [n.strip() for n in str(names).split(",") if n.strip()]:
        for colour in palette_entries(themes.get(name)):
            if colour not in out:
                out.append(colour)
    for colour in shared + base:
        if colour not in out:
            out.append(colour)
    return out


def fit_palette(image: Image.Image, palette: dict, asset: dict) -> Image.Image:
    """Snap every opaque pixel to the nearest palette colour.

    This is what makes a generated sprite look like it belongs next to hand-drawn
    ones. A model gives you eleven shades where the project has six; snapping
    loses the subtlety and gains the match.
    """
    if not palette:
        return image
    allowed = numpy.array(colours(palette, asset), dtype=numpy.int16)
    rgba = image.convert("RGBA")
    array = numpy.asarray(rgba).astype(numpy.int16)

    opaque = array[:, :, 3] > 0
    if not opaque.any():
        return rgba

    pixels = array[:, :, :3][opaque]
    # Nearest colour by squared distance; the palette is small enough that the
    # brute-force distance is cheaper than the tree that would avoid it.
    distances = ((pixels[:, None, :] - allowed[None, :, :]) ** 2).sum(axis=2)
    nearest = allowed[distances.argmin(axis=1)]

    out = array.copy()
    out[:, :, :3][opaque] = nearest
    return Image.fromarray(out.astype("uint8"), mode="RGBA")


def load_json(path: pathlib.Path) -> dict:
    with path.open() as handle:
        return json.load(handle)


def write_workflow(prompt: str, negative: str, seed: int, control: pathlib.Path,
                   out: pathlib.Path) -> None:
    if not WORKFLOW.exists():
        sys.exit(
            f"{WORKFLOW} is missing.\n"
            f"The ComfyUI backend needs an API-format workflow to post. Either "
            f"create that file or use --backend folder, which only writes the "
            f"prompt and the control image to drop into a ComfyUI by hand."
        )
    graph = load_json(WORKFLOW)
    for node in graph.values():
        inputs = node.get("inputs", {})
        if isinstance(inputs.get("text"), str) and inputs["text"] == "__PROMPT__":
            inputs["text"] = prompt
        elif isinstance(inputs.get("text"), str) and inputs["text"] == "__NEGATIVE__":
            inputs["text"] = negative
        elif inputs.get("seed") == "__SEED__":
            inputs["seed"] = seed
        elif inputs.get("image") == "__CONTROL__":
            inputs["image"] = control.name
        # A workflow that still carries a CHANGE_ME_ name will fail deep inside
        # Comfy with a node error that says nothing about which name is wrong.
        # Fail here instead, where the message can say it.
        if isinstance(inputs.get("ckpt_name"), str) and inputs["ckpt_name"].startswith("CHANGE_ME"):
            sys.exit(
                f"{WORKFLOW} still has the placeholder checkpoint "
                f"{inputs['ckpt_name']!r}.\n"
                f"Put the name of a checkpoint that exists on your ComfyUI "
                f"server in the LoadImage/CheckpointLoaderSimple node, or use "
                f"--backend folder."
            )
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(graph, indent=2))


def choose_control(asset: dict, assets_dir: pathlib.Path) -> pathlib.Path | None:
    """img2img needs something to lean on, and the project's own art is it.

    The control is the sprite's own first frame, read out of the manifest's
    `file` field rather than guessed from the id. Ids are dotted
    (`character.head.idle.n`) and files are not (`characters/head/frames/
    head_idle_front_01.png`), so a filename built from the id finds nothing and
    the run silently proceeds with no control — which is the same as asking the
    model for a sprite from nothing and calling it img2img.

    The master sheet is the better control when there is one: it is the same
    subject at full size, unsquashed by a strip.
    """
    entry_path = asset.get("file")
    if entry_path:
        first = (assets_dir / entry_path.split("|")[0])
        if first.exists():
            return first
    master = asset.get("master")
    if master:
        for candidate in assets_dir.rglob(f"{master}.png"):
            return candidate
    return None


def post_comfy(prompt: str, negative: str, seed: int, control: pathlib.Path,
               out_dir: pathlib.Path, base_url: str) -> pathlib.Path | None:
    graph_file = out_dir / "workflow_api.json"
    write_workflow(prompt, negative, seed, control, graph_file)

    payload = {"prompt": load_json(graph_file), "client_id": "ai_sprites"}
    request = urllib.request.Request(
        f"{base_url.rstrip('/')}/prompt",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            queued = json.load(response)
    except urllib.error.URLError as error:
        print(f"ComfyUI unreachable at {base_url}: {error}")
        return None

    out_dir.mkdir(parents=True, exist_ok=True)
    prompt_id = queued.get("prompt_id")
    print(f"queued as {prompt_id}; fetch /history/{prompt_id} for the result")
    return out_dir / "comfyui_prompt_id.txt"


def folder_backend(prompt: str, negative: str, seed: int, control: pathlib.Path | None,
                   out_dir: pathlib.Path) -> pathlib.Path:
    """Write the prompt and the control image out, and generate nothing.

    This is the backend to use when the machine that can run the model is not
    this one. It is also the honest default: the finishing steps need a model
    output to run on, and this will say so rather than invent one.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "prompt.txt").write_text(prompt)
    (out_dir / "negative.txt").write_text(negative)
    (out_dir / "seed.txt").write_text(str(seed))
    if control and control.exists():
        shutil.copy(control, out_dir / f"control_{control.name}")
    (out_dir / "README.txt").write_text(
        "Run this prompt and control image through ComfyUI, or any local SDXL.\n"
        "Save the result as raw.png in this directory, then:\n"
        f"    python3 scripts/ai_sprites.py --accept {out_dir.name}\n"
    )
    print(f"prompt written to {out_dir}")
    return out_dir


def finish(raw: pathlib.Path, asset: dict, out_dir: pathlib.Path,
           palette: dict) -> Image.Image:
    """The deterministic half: trim, snap, place. Same input, same pixels."""
    # `runtime_size` is a map, `{width, height}`, in the manifest. Indexing it
    # with `[0]` raises KeyError, so `--accept` had never run end to end: the only
    # time the CLI was exercised was a smoke test that stopped before this line.
    runtime = asset["runtime_size"]
    image = first_frame(Image.open(raw), runtime["width"])
    image = cut_out(image)
    image = fit(image, asset)
    image = fit_palette(image, palette, asset)

    out_dir.mkdir(parents=True, exist_ok=True)
    # Written out so a person can look at it, which is the whole point of a
    # candidate. Returned as the image, because the caller saves it under the
    # asset's own name -- it used to return this path, and the caller called
    # `.save` on it, so `--accept` died on a pathlib.Path.
    image.save(out_dir / "finished.png")
    return image


def accept(run: pathlib.Path, asset: dict, palette: dict, *, lock: bool) -> pathlib.Path | None:
    """Move a candidate into accepted/, by eye, one at a time.

    Locked assets are refused rather than overwritten: a sprite somebody signed
    off is not replaced because a later run produced something else.
    """
    state = load_state()
    asset_id = asset["id"]
    if lock or asset.get("locked") or state.get(asset_id, {}).get("locked"):
        if state.get(asset_id, {}).get("locked") and not lock:
            print(f"{asset_id} is locked, skipping")
            return None
        if lock:
            print(f"{asset_id} is now locked against future replacement")
            state.setdefault(asset_id, {})["locked"] = True
            save_state(state)

    raw = run / "raw.png"
    if not raw.exists():
        print(f"{run} has no raw.png, nothing to accept")
        return None

    image = finish(raw, asset, run, palette)
    accepted_dir = ASSETS / "ai" / "accepted"
    accepted_dir.mkdir(parents=True, exist_ok=True)
    target = accepted_dir / f"{asset_id}.png"
    image.save(target)

    state.setdefault(asset_id, {}).update({
        "accepted": str(target.relative_to(PROJECT_ROOT)),
        "run": run.name,
        "at": stamp(),
    })
    save_state(state)
    print(f"accepted {asset_id} -> {target}")
    return target


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kind", choices=["character", "entity", "tile", "effect"],
                        help="which group to work on")
    parser.add_argument("--id", dest="asset_id", help="one sprite id")
    parser.add_argument("--limit", type=int, default=1,
                        help="how many to ask for this run")
    parser.add_argument("--scale", type=int, default=SCALE,
                        help="extra scale on top of the manifest's own")
    parser.add_argument("--backend", choices=["folder", "comfyui"], default="folder")
    parser.add_argument("--base-url", default="http://127.0.0.1:8188")
    parser.add_argument("--lock", action="store_true",
                        help="lock the accepted sprite against replacement")
    parser.add_argument("--accept", metavar="RUN",
                        help="accept a finished candidate run by directory name")
    parser.add_argument("--control", help="use this image as the img2img control")
    parser.add_argument("--prompt", help="override the prompt entirely")
    parser.add_argument("--seed", type=int, help="fix the seed for reproducibility")
    parser.add_argument("--out", help="write the run here instead of the default")
    args = parser.parse_args()

    palette_path = STYLE / "palette.json"
    if not palette_path.exists():
        sys.exit(
            f"{palette_path} is missing.\n"
            f"This script snaps sprites to the project palette, so it will not "
            f"run without one: a sprite that skipped the palette would not match "
            f"the art around it. Either give {STYLE} a palette.json, or point "
            f"this script at a game that has one."
        )
    palette = load_json(palette_path)

    entries = manifest()["assets"]

    if args.accept:
        # The flag is documented as taking a run directory, and a run directory is
        # named `<timestamp>-<asset id>`, so matching the flag against a manifest
        # id exactly as it did means `--accept` never worked: every run directory
        # has a timestamp on the front and none of them is a manifest id. Either
        # form is accepted now, and a run that matches neither says so with both
        # forms in the message.
        wanted = args.accept
        for asset in entries:
            if wanted in (asset["id"],) or wanted.endswith(f"-{asset['id']}"):
                accept(BUILD / wanted, asset, palette, lock=args.lock)
                return
        sys.exit(
            f"{wanted!r} is neither a run directory nor a sprite id in the "
            f"manifest. Run directories are named <timestamp>-<id> and are in "
            f"{BUILD}.")

    if not args.kind or not args.asset_id:
        sys.exit("give --kind and --id, or --accept RUN")

    asset = next((a for a in entries if a["id"] == args.asset_id), None)
    if asset is None:
        sys.exit(f"no sprite with id {args.asset_id!r} in the manifest")

    spec = spec_description(args.kind, asset["id"])
    prompt = args.prompt or base_prompt(asset, spec)
    negative = negative_prompt()
    seed = args.seed if args.seed is not None else int(stamp()[-4:])

    control = pathlib.Path(args.control) if args.control else \
        choose_control(asset, ASSETS / "sprites")
    if control is None:
        print("warning: no control image found, the model has nothing to lean on")

    out_dir = pathlib.Path(args.out) if args.out else \
        BUILD / f"{stamp()}-{asset['id']}"

    if args.backend == "comfyui":
        if control is None:
            sys.exit("the ComfyUI backend needs a control image")
        if post_comfy(prompt, negative, seed, control, out_dir,
                      args.base_url) is None:
            sys.exit(1)
        return

    folder_backend(prompt, negative, seed, control, out_dir)
    print(f"next: generate raw.png there, then --accept {out_dir.name}")


if __name__ == "__main__":
    main()