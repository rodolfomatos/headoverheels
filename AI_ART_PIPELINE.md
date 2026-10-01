# AI art pipeline

Sprites here are drawn by hand, from measurements, out of the game's own
screenshots. That is the rule and it does not bend: no frame, tile, character or
sprite from the 1987 game enters this project, as art, as an img2img control, or
as a fine-tuning target.

A diffusion model is good at one thing here, which is proposing an image. It is
not good at the things that decide whether the game works: exact sizes, exact
anchors, one palette, the same sprite every run. So it proposes, and this
pipeline decides. Everything a model produces is a **candidate**, kept outside
`assets/`, and nothing reaches the game until somebody looks at it.

## The rule that matters

A candidate is not art. Art is what a person accepted. The two live in different
directories on purpose:

```
build/ai/<timestamp>-<id>/      the run: prompt, control, raw.png, finished.png
games/headoverheels/assets/ai/accepted/<id>.png   what a person signed off
games/headoverheels/assets/ai/state.json          which sprites are locked
```

There is no flag that writes a generated image into `assets/sprites/`. The
accept step copies one file, once, and records it.

## Backend: folder by default

`--backend folder` writes the prompt, the negative, the seed and the control
image into a directory and generates nothing. Use it when the machine that can
run the model is not this one: run the prompt through SDXL wherever you like,
save the result as `raw.png` in that directory, then accept it.

`--backend comfyui` posts the same prompt to a local ComfyUI through
`prompts/comfyui_workflow_api.json`. That file carries a placeholder checkpoint,
`CHANGE_ME_sdxl_checkpoint.safetensors`, and the script refuses to run until it
names a checkpoint that exists on your server — a node error from ComfyUI says
nothing about which name was wrong, and a clear message here does.

## The control image is img2img, and a strip is a trap

With img2img the model is asked for the same object in a different style, using
existing art as a control. Controls are frequently animation strips: one row of
frames. Handing a strip to img2img invites a contact sheet back, which is the
easiest way to get a sprite with three copies of itself in it. So a control
wider than one runtime cell is cropped to its leftmost frame before it is used.

## What the pipeline decides, so runs are comparable

| Step | Decided here | Why not left to the model |
|---|---|---|
| Trim | yes | models pad differently every run |
| Palette snap | yes | models invent shades; the project has six |
| Runtime size | yes, from the manifest | the renderer assumes it |
| Anchor | yes, from the manifest | the renderer positions on it |
| Scale | baked at 1 | the renderer scales at draw time; baking doubles it |
| Subject, style, pose | no | this is what the model is for |

Two runs of the same prompt and seed therefore differ only where the model was
allowed to be creative.

## Anchors, and the tileset exception

The anchor is the one thing here that cannot be guessed: it encodes where the
game positions a sprite relative to its tile. Six Head over Heels **tilesets**
have no anchor in the manifest, because they are painted onto the room as a
background rather than placed at a tile — those are centred in their cell.

A manifest entry without an anchor used to raise `KeyError` on the first
tileset. It is now a deliberate fallback, and the tests say which is which.

## Palette

`games/headoverheels/style/palette.json` is the only palette, and it must exist:
a sprite that skipped the palette would not match the art around it, so the script
exits rather than degrade quietly.

`games/knightlore/` has no `style/` directory at all, so this script is
Head-over-Heels-only as it stands. Giving Knight Lore a palette is the honest way
to widen it, and it has not been done yet — see the board.

## Two scripts in `scripts/` are dead

`normalize_sprites.py` and `validate_palette.py` both resolve
`Path(__file__).parent.parent / "style"`, which is `<repo>/style` — a directory
that does not exist. Neither is called by the `Makefile` or by any workflow, so
neither has run in this project's history; they are code with a path from an
earlier layout. `scripts/validate_sprites.py` is the live one, and it already
points at `GAME_ROOT / "style"`, which is why it passes.

They are left in place rather than deleted because removing them is a separate
decision, and deleting scripts nobody has read in a while is how you lose the
reason they existed.

## Running it

```bash
python3 scripts/ai_sprites.py --kind character --id character.head.idle.n
python3 scripts/ai_sprites.py --kind entity --id entity.rabbit.hop --backend comfyui
python3 scripts/ai_sprites.py --kind tile --id tileset.castle --scale 2 --lock
python3 scripts/ai_sprites.py --accept 20260930-1421
python3 -m pytest scripts/tests/test_ai_sprites.py -q
```

Ids are the manifest's, dotted and specific — `character.head.idle.n`,
`entity.rabbit.hop`, not `guard`. They are read out of `assets/sprites/manifest.yaml` and a wrong one
exits with the list it searched.

`--lock` marks a sprite so no later run replaces it, and is written to
`assets/ai/state.json` alongside the acceptance record, so the provenance of
every accepted sprite — prompt, negative, seed, control, timestamp — survives in
the project.