#!/usr/bin/env python3
"""Show what the games actually load: every sprite sheet and every sound.

Not the original games' assets, which this repository does not ship and does not
extract: the sprites are drawn by the generators in `scripts/` and the sounds are
computed by each game's `tool/generate_audio.dart`. What this does is put the
result in front of a person, laid out the way the games lay it out, so the
organisation can be looked at rather than inferred from a directory listing.

Writes `build/preview/assets/index.html`, a page that opens in a browser, and
`build/preview/assets/inventory.json` for anything that wants to read it rather
than look at it. Run with `--check` to say whether it is up to date.
"""

import argparse
import json
import struct
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).parent.parent
OUT = ROOT / "build" / "preview" / "assets"

GAMES = {
    "headoverheels": {
        "label": "Head over Heels",
        "manifest": ROOT / "games/headoverheels/assets/sprites/manifest.yaml",
        "sprites": ROOT / "games/headoverheels/assets/sprites",
        "audio": ROOT / "games/headoverheels/assets/audio",
    },
    "knightlore": {
        "label": "Knight Lore",
        "manifest": ROOT / "games/knightlore/assets/sprites/manifest.yaml",
        "sprites": ROOT / "games/knightlore/assets/sprites",
        "audio": ROOT / "games/knightlore/assets/audio",
    },
}


def size_label(num_bytes: int) -> str:
    """A size a person can read. A 48x48 sheet is a few hundred bytes, and
    rounding that to '0 KB' says less than the number does."""
    if num_bytes < 1024:
        return f"{num_bytes} B"
    if num_bytes < 1024 * 1024:
        return f"{num_bytes // 1024} KB"
    return f"{num_bytes / (1024 * 1024):.1f} MB"


def png_size(path: Path) -> tuple:
    """A PNG's size, from its own header."""
    with open(path, "rb") as handle:
        head = handle.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG")
    return struct.unpack(">II", head[16:24])


def read_manifest(path: Path) -> list:
    """The manifest's entries, read without a YAML library.

    The manifest is a flat list of records, so this is a small reader rather
    than a dependency: the point of this script is to show the files, not to
    become the thing that reads them.
    """
    entries = []
    current = {}
    in_assets = False
    nested = False
    for raw in path.read_text().split("\n"):
        line = raw.rstrip()
        if line.startswith("assets:"):
            in_assets = True
            continue
        if not in_assets or not line.strip():
            if in_assets and line and not line.startswith((" ", "-")):
                break
            continue
        stripped = line.strip()
        # A list item is `- id: ...` on one line, or a bare `-` with the record
        # on the lines after it. Knight Lore's manifest is written the second way.
        if stripped == "-":
            if current:
                entries.append(current)
            current = {}
            nested = False
            continue
        if stripped.startswith("- "):
            if current:
                entries.append(current)
            current = {}
            nested = False
            stripped = stripped[2:]
        if ":" not in stripped:
            continue
        key, _, value = stripped.partition(":")
        if not value.strip():
            # A key with nothing after it opens a block: `runtime_size:` and the
            # width and height under it. The page shows the real size, read from
            # the PNG, so the declared one is not needed here.
            nested = True
            continue
        if nested:
            # Still inside the block that was opened above.
            continue
        current[key.strip()] = _scalar(value.strip())
    if current:
        entries.append(current)
    return entries


def _scalar(value: str):
    # Knight Lore's manifest quotes its values and Head over Heels' does not.
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    if value.startswith("[") and value.endswith("]"):
        return [part.strip() for part in value[1:-1].split(",") if part.strip()]
    if value.isdigit():
        return int(value)
    if value in ("true", "false"):
        return value == "true"
    return value


def collect(game: dict) -> dict:
    entries = read_manifest(game["manifest"])
    sprites = []
    for entry in entries:
        file = game["sprites"] / entry.get("file", "")
        if not file.exists():
            continue
        width, height = png_size(file)
        sprites.append(
            {
                "id": entry.get("id", ""),
                "category": entry.get("category", ""),
                "file": entry.get("file", ""),
                "bytes": file.stat().st_size,
                "image": [width, height],
                "frames": entry.get("frames"),
                "character": entry.get("character"),
                "entity": entry.get("entity"),
                "animation": entry.get("animation"),
                "direction": entry.get("direction"),
                "frame_duration": entry.get("frame_duration"),
                "loop": entry.get("loop"),
                "runtime_size": entry.get("runtime_size"),
            }
        )
    sheets = []
    for path in sorted(game["sprites"].rglob("*.png")):
        if "manifest.yaml" in path.name:
            continue
        width, height = png_size(path)
        sheets.append(
            {
                "file": str(path.relative_to(game["sprites"])),
                "image": [width, height],
                "bytes": path.stat().st_size,
            }
        )
    # Sheets on disk that no manifest entry points at. A generator can leave
    # these behind, and a preview that hides them cannot tell anyone.
    listed = {entry["file"] for entry in entries}
    orphans = [sheet for sheet in sheets if sheet["file"] not in listed]
    sounds = []
    for path in sorted(game["audio"].rglob("*.wav")):
        sounds.append(
            {
                "file": str(path.relative_to(game["audio"])),
                "bytes": path.stat().st_size,
                "folder": path.parent.name,
            }
        )
    return {"sprites": sprites, "sheets": sheets, "sounds": sounds,
            "unlisted": orphans}


def relative_link(game: dict, relative: str) -> str:
    """A link from the page to a file, relative to the page's own directory."""
    absolute = (game["sprites"] / relative).resolve()
    return str(Path("../../..") / absolute.relative_to(ROOT.resolve()))


def audio_link(game: dict, relative: str) -> str:
    absolute = (game["audio"] / relative).resolve()
    return str(Path("../../..") / absolute.relative_to(ROOT.resolve()))


def page(inventory: dict) -> str:
    parts = [
        "<!doctype html>",
        '<html lang="en"><head><meta charset="utf-8">',
        "<title>What the games load</title>",
        """<style>
body{background:#101216;color:#cfd6e4;font:14px/1.5 system-ui,sans-serif;margin:0;padding:24px}
h1{font-size:20px;margin:0 0 4px}h2{font-size:17px;margin:32px 0 4px}
h3{font-size:14px;margin:20px 0 6px;color:#8fb7ff;font-weight:600}
p.lead{color:#8b95a8;margin:0 0 8px;max-width:70ch}
table{border-collapse:collapse;width:100%;margin:8px 0 16px}
th,td{text-align:left;padding:4px 8px;border-bottom:1px solid #23262e;vertical-align:middle}
th{color:#8b95a8;font-weight:600}
img.pixel{image-rendering:pixelated;background:#181a1f;border:1px solid #2b2f39;
  max-width:220px;max-height:110px}
code{color:#9ad}
audio{height:28px;vertical-align:middle}
.small{color:#6b7488;font-size:12px}
</style></head><body>""",
        "<h1>What the games load</h1>",
        '<p class="lead">Every sprite sheet and every sound the two games load at '
        "runtime, as the manifest describes them. None of this is the original "
        "1987 games: the sheets are drawn by the generators in "
        "<code>scripts/</code> and the sounds are computed by each game's "
        "<code>tool/generate_audio.dart</code>.</p>",
    ]
    for key, game in GAMES.items():
        data = inventory[key]
        parts.append(f"<h2>{game['label']}</h2>")
        parts.append(
            '<p class="lead">{} manifest entries, {} sheets on disk, {} sounds'
            "{}</p>".format(
                len(data["sprites"]),
                len(data["sheets"]),
                len(data["sounds"]),
                (
                    ", {} on disk that no entry points at".format(
                        len(data["unlisted"])
                    )
                    if data["unlisted"]
                    else ""
                ),
            )
        )

        if data["unlisted"]:
            unlisted = data["unlisted"]
            parts.append(f"<h3>on disk, in no manifest &mdash; {len(unlisted)}</h3>")
            parts.append(
                '<p class="lead">Drawn, on disk, and asked for by nothing. Some '
                "are the masters the sheets below were sliced from, which is what "
                "they are for. The others are art nothing loads, and that is worth "
                "knowing before anyone counts the sheets as features.</p>"
            )
            parts.append(
                "<table><tr><th>sheet</th><th>image</th></tr>"
            )
            for sheet in unlisted:
                parts.append(
                    "<tr>"
                    f'<td><code>{sheet["file"]}</code></td>'
                    f'<td><img class="pixel" src="{relative_link(game, sheet["file"])}">'
                    f'</td><td class="small">{sheet["image"][0]}&times;'
                    f'{sheet["image"][1]}, {size_label(sheet["bytes"])}</td>'
                    "</tr>"
                )
            parts.append("</table>")

        for category in sorted({s["category"] for s in data["sprites"]}):
            entries = [s for s in data["sprites"] if s["category"] == category]
            parts.append(f"<h3>{category} &mdash; {len(entries)}</h3>")
            parts.append(
                "<table><tr><th>sheet</th><th>id</th><th>animation</th>"
                "<th>direction</th><th>frames</th><th>image</th></tr>"
            )
            for entry in entries:
                parts.append(
                    "<tr>"
                    f'<td><img class="pixel" src="{relative_link(game, entry["file"])}"></td>'
                    f'<td><code>{entry["id"]}</code></td>'
                    f'<td>{entry.get("animation") or ""}</td>'
                    f'<td>{entry.get("direction") or ""}</td>'
                    f'<td>{entry.get("frames") or ""}</td>'
                    f'<td class="small">{entry["image"][0]}&times;{entry["image"][1]}, '
                    f'{size_label(entry["bytes"])}</td>'
                    "</tr>"
                )
            parts.append("</table>")

        folders = Counter(s["folder"] for s in data["sounds"])
        for folder in sorted(folders):
            sounds = [s for s in data["sounds"] if s["folder"] == folder]
            parts.append(f"<h3>{folder} &mdash; {len(sounds)}</h3>")
            parts.append("<table><tr><th>play</th><th>file</th><th>size</th></tr>")
            for sound in sounds:
                parts.append(
                    "<tr>"
                    f'<td><audio controls preload="none" src="'
                    f'{audio_link(game, sound["file"])}"></audio></td>'
                    f'<td><code>{sound["file"]}</code></td>'
                    f'<td class="small">{size_label(sound["bytes"])}</td>'
                    "</tr>"
                )
            parts.append("</table>")
    parts.append("</body></html>")
    return "\n".join(parts)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero when the page is not what this writes",
    )
    arguments = parser.parse_args()

    inventory = {key: collect(game) for key, game in GAMES.items()}
    wanted_html = page(inventory)
    wanted_json = json.dumps(inventory, indent=2, sort_keys=True)
    OUT.mkdir(parents=True, exist_ok=True)
    html_path = OUT / "index.html"
    json_path = OUT / "inventory.json"

    if arguments.check:
        problems = []
        if not html_path.exists() or html_path.read_text() != wanted_html:
            problems.append("index.html is not what this writes")
        if not json_path.exists() or json_path.read_text() != wanted_json:
            problems.append("inventory.json is not what this writes")
        for problem in problems:
            print(problem, file=sys.stderr)
        return 1 if problems else 0

    html_path.write_text(wanted_html)
    json_path.write_text(wanted_json)
    for key, game in GAMES.items():
        data = inventory[key]
        print(
            f"{game['label']}: {len(data['sprites'])} entries, "
            f"{len(data['sheets'])} sheets, {len(data['sounds'])} sounds"
        )
    print(f"wrote {html_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
