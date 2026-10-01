"""The deterministic half of the AI art pipeline.

These are the steps that decide pixels, so they are the steps that get tested.
A model output is not required to test any of it: `cut_out`, `fit` and
`fit_palette` are pure functions of an image and a manifest entry, and the whole
point is that the same input gives the same output.

The two regressions worth naming:

- `fit` used to read `a["anchor"]["x"]` unconditionally. Six Head over Heels
  tilesets have no anchor, so the first tileset in the manifest raised
  `KeyError` and the script died before generating anything.
- `cut_out` used to compare against one corner pixel. A model asked for a flat
  magenta field will not always return exactly one magenta, and the halo that
  leaves is visible in the game.
"""

from __future__ import annotations

import importlib.util
import pathlib
import sys

import pytest
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "ai_sprites", ROOT / "scripts" / "ai_sprites.py")
ai = importlib.util.module_from_spec(spec)
sys.modules["ai_sprites"] = ai
spec.loader.exec_module(ai)

MAGENTA = (255, 0, 255)
TEAL = (0, 200, 180)


def solid(size, colour, alpha=255):
    return Image.new("RGBA", size, (*colour, alpha))


@pytest.fixture
def palette():
    return ai.load_json(ROOT / "games" / "headoverheels" / "style" / "palette.json")


@pytest.fixture
def manifest():
    return ai.manifest()["assets"]


def entry(manifest, **overrides):
    base = dict(manifest[0])
    base.update(overrides)
    return base


# --- cut_out ---------------------------------------------------------------

def test_cut_out_clears_the_background_entirely():
    # A 3x3 with a single subject pixel. The corners are the background.
    image = solid((9, 9), MAGENTA)
    image.putpixel((4, 4), (*TEAL, 255))

    out = ai.cut_out(image)

    assert out.getpixel((0, 0))[3] == 0
    assert out.getpixel((4, 4))[3] == 255


def test_cut_out_survives_a_background_that_is_not_one_colour():
    # The median-corner fallback: corners disagree, so no single corner pixel is
    # a reliable key. Every corner must still end up transparent.
    image = Image.new("RGBA", (9, 9), (*MAGENTA, 255))
    for corner in [(0, 0), (8, 0), (0, 8), (8, 8)]:
        image.putpixel(corner, (250, 2, 250, 255))
    image.putpixel((4, 4), (*TEAL, 255))

    out = ai.cut_out(image)

    assert all(out.getpixel(c)[3] == 0 for c in [(0, 0), (8, 0), (0, 8), (8, 8)])


def test_cut_out_keeps_a_dim_subject_pixel():
    # A subject pixel far from the background must stay opaque. This is what
    # stops the threshold from eating the whole sprite.
    image = solid((9, 9), MAGENTA)
    image.putpixel((4, 4), (*TEAL, 255))

    assert ai.cut_out(image).getpixel((4, 4))[3] > 200


# --- first_frame -----------------------------------------------------------

def test_a_strip_is_cropped_to_one_frame(manifest):
    # Four frames side by side. Feeding the strip to img2img gets a contact sheet
    # back, which is the sprite drawn three times.
    strip = solid((64, 16), TEAL)
    asset = entry(manifest, runtime_size=[16, 16])

    assert ai.first_frame(strip, 16).size == (16, 16)


def test_a_single_frame_is_left_alone(manifest):
    single = solid((16, 16), TEAL)

    assert ai.first_frame(single, 16).size == (16, 16)


# --- fit -------------------------------------------------------------------

def test_fit_reaches_the_manifest_runtime_size(manifest):
    image = solid((32, 40), TEAL)
    asset = entry(manifest, runtime_size=[24, 24], scale=1)

    assert ai.fit(image, asset).size == (24, 24)


def test_fit_applies_the_manifest_scale(manifest):
    image = solid((32, 40), TEAL)
    asset = entry(manifest, runtime_size=[24, 24], scale=2)

    assert ai.fit(image, asset).size == (48, 48)


def test_fit_centres_a_tileset_that_has_no_anchor(manifest):
    """The regression: six HoH tilesets carry no anchor.

    `fit` read `a["anchor"]["x"]` unconditionally, so the first tileset in the
    manifest raised `KeyError` and nothing was ever generated for a tile.
    """
    tileset = entry(manifest, runtime_size=[32, 32], scale=1)
    tileset.pop("anchor", None)

    image = solid((16, 16), TEAL)
    out = ai.fit(image, tileset)

    assert out.size == (32, 32)
    # Centred means the subject's centre lands in the cell's centre.
    centre = out.getpixel((16, 16))
    assert centre[3] > 0, "a tileset sprite should be centred in its cell"


def test_fit_uses_the_anchor_when_the_manifest_has_one(manifest):
    asset = entry(manifest, runtime_size=[32, 32], scale=1,
                  anchor={"x": 0, "y": 0})

    # Anchor at the top-left: the subject's own top-left stays in the cell's.
    out = ai.fit(solid((8, 8), TEAL), asset)

    assert out.getpixel((0, 0))[3] > 0
    assert out.getpixel((31, 31))[3] == 0


def test_fit_is_deterministic(manifest):
    asset = entry(manifest, runtime_size=[24, 24], scale=1)

    first = ai.fit(solid((32, 40), TEAL), asset).tobytes()
    second = ai.fit(solid((32, 40), TEAL), asset).tobytes()

    assert first == second, "the finishing step must not vary between runs"


# --- colours / fit_palette -------------------------------------------------

def test_colours_puts_the_sprites_own_palette_first(palette, manifest):
    themed = entry(manifest, palette="egyptus")
    names = ai.colours(palette, themed)

    assert names[0] in ai.palette_entries(palette["themes"]["egyptus"])


def test_colours_falls_back_when_the_palette_names_nothing(palette, manifest):
    names = ai.colours(palette, entry(manifest, palette=""))

    assert names, "an empty palette name must still yield the shared palette"


def test_fit_palette_snaps_every_opaque_pixel(palette, manifest):
    allowed = ai.colours(palette, entry(manifest, palette="egyptus"))
    almost = tuple(min(255, c + 9) for c in allowed[0])
    image = solid((8, 8), almost)

    out = ai.fit_palette(image, palette, entry(manifest, palette="egyptus"))

    for pixel in out.getdata():
        assert tuple(pixel[:3]) in allowed, f"{pixel} is not a palette colour"


def test_fit_palette_leaves_transparent_pixels_alone(palette, manifest):
    image = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    image.putpixel((2, 2), (*TEAL, 255))

    out = ai.fit_palette(image, palette, entry(manifest))

    assert out.getpixel((0, 0))[3] == 0
    assert out.getpixel((2, 2))[3] == 255


def test_fit_palette_is_a_no_op_without_a_palette(manifest):
    image = solid((4, 4), TEAL)

    assert ai.fit_palette(image, {}, entry(manifest)).tobytes() == image.tobytes()


# --- choose_control --------------------------------------------------------

def test_the_control_comes_from_the_manifests_own_file(manifest, tmp_path):
    """Ids are dotted, files are not, so the control cannot be named after the id.

    `character.head.idle.n` lives at
    `characters/head/frames/head_idle_front_01.png`. A filename built from the id
    finds nothing, and the run proceeds with no control while claiming to be
    img2img.
    """
    asset = next(a for a in manifest if a.get("file"))
    control = ai.choose_control(asset, tmp_path)
    assert control is None, "an empty tree has no control, and must say so"

    target = tmp_path / asset["file"]
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(b"")
    assert ai.choose_control(asset, tmp_path) == target


def test_the_control_falls_back_to_the_master_sheet(manifest, tmp_path):
    asset = dict(next(a for a in manifest if a.get("master")))
    asset.pop("file", None)
    sheet = tmp_path / "characters" / "x" / "frames"
    sheet.mkdir(parents=True)
    master = sheet / f"{asset['master']}.png"
    master.write_bytes(b"")

    assert ai.choose_control(asset, tmp_path) == master


def test_no_control_is_reported_as_none_not_a_guess(manifest, tmp_path):
    assert ai.choose_control(dict(manifest[0]), tmp_path) is None


# --- manifest reality ------------------------------------------------------

def test_every_manifest_entry_can_be_fitted(manifest):
    """No entry may lack what `fit` reads.

    `runtime_size` is required. `anchor` is not, because tilesets have none —
    but the manifest must not be missing it for anything else by accident, so
    the anchor-less entries are asserted to be tilesets rather than tolerated.
    """
    for asset in manifest:
        assert "runtime_size" in asset, f"{asset['id']} has no runtime_size"
        if "anchor" not in asset:
            assert asset.get("category") == "tileset", (
                f"{asset['id']} has no anchor but is not a tileset")


def test_the_tilesets_that_actually_have_no_anchor(manifest):
    """Pins the number this fix was made for, so a new one is noticed."""
    missing = [a["id"] for a in manifest if "anchor" not in a]

    assert len(missing) == 6, f"expected 6 anchor-less tilesets, got {missing}"


# --- prompt building -------------------------------------------------------

def test_the_prompt_says_one_subject_and_a_flat_field(manifest):
    prompt = ai.base_prompt(entry(manifest, palette="castle"), "a castle guard")

    assert "single a castle guard" in prompt
    assert "solid opaque background" in prompt


def test_the_negative_excludes_contact_sheets():
    negative = ai.negative_prompt()

    assert "sprite sheet" in negative
    assert "multiple subjects" in negative


def test_spec_description_falls_back_to_the_id(tmp_path, monkeypatch):
    # No spec on disk: the prompt must still say something true rather than an
    # empty description that reads as a rendering instruction.
    monkeypatch.setattr(ai, "PROMPTS", tmp_path)

    assert "guard" in ai.spec_description("character", "guard")


# --- the ComfyUI workflow --------------------------------------------------

def test_the_workflow_is_api_format_and_filled_in(tmp_path):
    graph = ai.load_json(ai.WORKFLOW)

    assert set(graph) == {str(i) for i in range(1, 10)}
    assert graph["7"]["class_type"] == "KSampler"


def test_a_placeholder_checkpoint_is_refused_before_comfy_sees_it(tmp_path):
    """A `CHANGE_ME_` name fails deep inside Comfy with a node error that says
    nothing about which name is wrong, so it is refused here instead."""
    out = tmp_path / "workflow_api.json"
    with pytest.raises(SystemExit) as exit_info:
        ai.write_workflow("p", "n", 1, tmp_path / "control.png", out)

    assert "placeholder checkpoint" in str(exit_info.value)


def test_workflow_substitution_fills_every_placeholder(tmp_path):
    import json

    workflow = json.loads(json.dumps(ai.load_json(ai.WORKFLOW)))
    # Stand in for a real checkpoint so the substitution path is reachable.
    workflow["1"]["inputs"]["ckpt_name"] = "sd_xl_base_1.0.safetensors"
    monkeypatched = tmp_path / "workflow.json"
    monkeypatched.write_text(json.dumps(workflow))
    original = ai.WORKFLOW
    ai.WORKFLOW = monkeypatched
    try:
        out = tmp_path / "out.json"
        ai.write_workflow("A PROMPT", "A NEGATIVE", 4242, tmp_path / "ctl.png", out)
        written = ai.load_json(out)
    finally:
        ai.WORKFLOW = original

    assert written["2"]["inputs"]["text"] == "A PROMPT"
    assert written["3"]["inputs"]["text"] == "A NEGATIVE"
    assert written["7"]["inputs"]["seed"] == 4242
    assert written["4"]["inputs"]["image"] == "ctl.png"


def test_a_missing_workflow_says_which_file_and_offers_the_other_backend(tmp_path):
    ai.WORKFLOW = tmp_path / "absent.json"
    try:
        with pytest.raises(SystemExit) as exit_info:
            ai.write_workflow("p", "n", 1, tmp_path / "c.png", tmp_path / "o.json")
    finally:
        ai.WORKFLOW = ROOT / "prompts" / "comfyui_workflow_api.json"

    assert "folder" in str(exit_info.value)