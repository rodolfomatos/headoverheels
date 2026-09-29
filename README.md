# An isometric platform, and two games on it

![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

A Flutter platform for 2:1 isometric games, with two games built on it and an
editor that opens either one. The first game is a port of **Head over Heels**
(1987); the second, **Knight Lore** (1984), exists to prove the platform is not
tailored to a single game.

> **State, plainly.** Knight Lore is finished: playable, with audio, and a
> visual test that renders it to images and fails if a room comes out blank or
> cropped. Head over Heels now opens its world, loads the room map, the tileset
> and the sprites, and shows the game: five tests stand the real screen up. What
> room now loads, which is T062: the patrol points in the world are lists and the
> parser wanted a string, so the first monster in the first room threw and the
> screen stayed black. Checked in a browser, on the web build, with the console
> read: the room draws its isometric floor and its entities. The black screen
> before it was the first frame waiting for every sprite in the game, 65 images
> of 316 KB decoded one at a time. A character now waits for the four images of
> its idle pose and nothing else, which brings the room on screen in 7 seconds
> where it took a minute. Four of the five planets also have no tileset of their
> own yet, which is T058. The board in `aes/kanban.md` is the authority on
> what is done and what is not.

---

## What is here

| | What it is | State |
|---|---|---|
| `packages/iso_core` | The shared runtime: isometric maths, world graph, assets, physics, and a pure-Dart sound synthesiser | 18 tests |
| `packages/iso_editor` | Map editor, sprite manager, world graph editor, tileset authoring. Opens either game | 60 tests |
| `packages/iso_builder_cli` | Project scaffolding and validation | 2 tests |
| `games/knightlore` | The second game: 15 rooms, 5 areas, the curse rules, the six ingredients, 27 synthesised sounds | 160 tests, playable |
| `games/headoverheels` | The first game: 20 rooms, 5 planets, 65 sprite sheets, 30 synthesised sounds | 83 tests, the room draws in 7 seconds |

Nothing at the top level is a package. Each game and each library is its own
Flutter package, and every Makefile target says which directory it runs in.

### The shared core

`iso_core` is the point of the repository. Both games read the same world graph
format, use the same asset manifest, project through the same isometric maths and
share one synthesiser. A ticket that moves behaviour into the core is a ticket
that makes the second game cheaper, which is how Knight Lore came to exist at
all: its rules were written against the core, not against the first game.

### Knight Lore

The rules of the original, reimplemented from the published documentation, with
no asset or level data from the original: forty days and six ingredients, the
sabreman and the werewolf, four knights that split at night, six decaying
spells, traps that catch you once and cost a day, and a room graph the editor
can read. `games/knightlore/README.md` has the balance numbers, measured and
printed by the tests rather than asserted by taste.

### Head over Heels

Twenty rooms across five planets, nineteen puzzle entity types, dual-character
mechanics and a world graph with 43 exits and 134 triggers. The game screen
watches the world, shows a loader while it arrives, reports a world that will not
load, and puts a single `HeadOverHeelsGame` on the canvas: the party, the room
and the joystick are the same objects the touch controls write to.

The crowns of a planet are the crowns of that planet: a throne room asks for
four of its own, the guardian of that throne room counts those and no others,
and the HUD shows the same number the guardian reads. The bag is worn rather
than held, and carries four items behind the one in the hand, with no
dispensary in the world to empty it at, which is T061.

The room maps draw a floor and a border again: the floors had been a sheet of
zeros, which Tiled reads as no tile at all, and the borders had been made of
floor tiles. Four tests read the numbers in the maps and would fail on either.

Two things are known to be unfinished. Only the castle has a tileset, so the
other four planets draw with the castle one until they have their own art. And
the pixel-level proof of the renderer is not a test yet: the frame was measured
at 1465 distinct colours and written to a PNG, but the test that did it never
finished, so the capture method has to change before it can guard anything.

---

## Quick start

```bash
git clone https://github.com/rodolfomatos/headoverheels.git
cd headoverheels

make setup                 # pub get in both games and both libraries
make check                 # format, lint, every test, asset validation

make run-knightlore        # the finished game, in a browser, on :8081
make run-headoverheels     # the first game, on :8080

make build-headoverheels   # release web build
make build-knightlore
```

For a device, run from the game's own directory:

```bash
cd games/headoverheels
flutter run                # Android device or emulator
flutter run -d linux       # or macos, windows, web
```

### Quality gates

```bash
make check
# 1. dart format --output=none --set-exit-if-changed games packages
# 2. flutter analyze, in the first game
# 3. flutter test, in the first game
# 4. iso_core, iso_editor, iso_builder_cli and knightlore tests
# 5. the sprite validation pipeline and the generated asset lists

make test-packages         # every package except the first game
make lint
make format
```

Two gates exist because both were needed the hard way. `assets-check` runs the
sprite validator and then checks that each game's pubspec asset list matches its
tree, because a pubspec entry ending in `/` ships only the files directly inside
that directory: without the generated list, a browser build got one file of 157
and no sprites. And `test/gameplay_compiles_test.dart` imports the gameplay layer
so that a compiler error cannot hide behind an `ignore` comment, which is how a
layer that had never compiled stayed invisible.

---

## Generating things

```bash
# Knight Lore's art, drawn from scratch
python3 scripts/generate_knightlore_assets.py

# Knight Lore's room maps, checked against the world
cd games/knightlore && flutter test test/room_maps_test.dart

# Either game's audio, computed rather than recorded
cd games/knightlore && dart run tool/generate_audio.dart
cd games/headoverheels && dart run tool/generate_audio.dart

# The asset list in a game's pubspec
python3 scripts/publish_assets.py games/knightlore            # write
python3 scripts/publish_assets.py games/knightlore --check    # verify

# Head over Heels' room maps
dart run scripts/generate_rooms.dart

# Code generation, for the first game
cd games/headoverheels && dart run build_runner build --delete-conflicting-outputs
```

### About the assets

Nothing in this repository comes from either original game. The art is drawn by
`scripts/generate_knightlore_assets.py` and by hand; the audio is computed by a
synthesiser in `iso_core`, so the WAV files under `assets/audio` are a build
product of this code rather than a recording; the rooms and puzzles were written
from the published descriptions of the games.

---

## Working on it

The board is `aes/kanban.md`: every ticket, its state, and a note under each
finished one saying what the work found. The tickets carry the detail, the
`docs/` directory carries the design, and `aes/tickets/` holds the older
specifications.

```bash
cat aes/kanban.md
cat docs/BUILDER_ARCHITECTURE.md   # the platform
cat docs/ARCHITECTURE.md           # the first game
```

A habit worth keeping: every claim in the board is checked against the code, not
against the board. An audit of five pending tickets found four were stale and one
was a real gap, and the audit itself is in the board's notes.

## Technology

| Layer | Used for |
|---|---|
| Flutter, Dart | both games and the editor |
| Flame | the game loop, components, collisions |
| Riverpod | the first game's state, the editor's dependency graph |
| Freezed, json_serializable | the first game's immutable state |
| flame_audio, just_audio | playing the synthesised sounds |
| vector_math | isometric projection |
| shared_preferences | volume and settings |
| xml, tiled | TMX and TSX maps |

---

## 📄 License

```
MIT License

Copyright (c) 2026 Rodolfo Matos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

The two games are not ours. Their rules were reimplemented from published
documentation, and no asset, level or recording from either was taken:

- **Head over Heels** — Jon Ritman and Bernie Drummond, 1987, published by
  Ocean Software
- **Knight Lore** — Chris Stamper, 1984, published by Ultimate Play The Game

And the tools this stands on: the Flame engine, Riverpod, Freezed, and the Tiled
map format.

---

## Where it stands

| | |
|---|---|
| Tests | 324 across five packages, and 169 sprite checks |
| Knight Lore | 15 rooms, 5 areas, finished and playable |
| Head over Heels | 20 rooms, 5 planets, opens and draws; the pixel proof is not a test yet |
| Sprites | 65 sheets, one manifest per game |
| Sounds | 57, every one computed by the synthesiser and loaded from the path the player hears |
| Board | 93 ticket rows, from the first audit to the editor layout work |

The plain summary: one finished game, one that compiles and cannot be played
yet, a platform underneath both, and a board that says which is which.

**Repository** · [Issues](https://github.com/rodolfomatos/headoverheels/issues) · [Releases](https://github.com/rodolfomatos/headoverheels/releases)
