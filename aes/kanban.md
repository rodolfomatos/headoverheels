---
project: headoverheels
created: 2026-09-18
current_sprint: sprint-11
current_ticket: "T050"
---

# Kanban — headoverheels

## Backlog
| ID | Title | Priority | Status |
|----|-------|----------|--------|
| T001 | Research original game mechanics & online MSX version | high | done |
| T002 | Define core game architecture (isometric rendering, state machine) | high | done |
| T003 | Implement Head/Heels character controllers & physics | high | done |
| T004 | Build isometric level rendering engine | high | done |
| T005 | Implement puzzle mechanics (switches, conveyors, doughnuts) | high | done |
| T006 | Implement remaining puzzle mechanics (spring, fish, doughnut, bag, crown, hush puppy, monster, guardian) | high | done |
| T007 | Implement final puzzle mechanics (crown, bag, hush puppy, guardian) + InteractionSystem | high | done |
| T008 | Create modern UI/UX: menus, HUD, touch controls | high | done |
| T009 | Implement Bag system (Heels carry items) | high | done |
| T010 | Connect CharacterState notifier to CharacterComponent | high | done |
| T011 | Create test room TMX with all entity types | high | done |
| T012 | Port original level data / design new levels | medium | done |
| T013 | Audio: SFX, music, adaptive audio system | medium | done |
| T014 | Polish: animations, transitions, accessibility | low | done |
| T015 | Release build & Play Store preparation | low | done |
| T016 | Asset & Visual System Audit | high | done |
| T017 | Visual Design System | high | done |
| T018 | Character Masters | high | done |
| T019 | Character Animation Pipeline | high | done |
| T020 | Environment Masters | high | done |
| T021 | Castle Tileset | high | done |
| T022 | Entity Masters | high | done |
| T023 | Remaining Themes | medium | done |
| T024 | Validation Pipeline | medium | done |
| T025 | Atlas Pipeline | medium | pending |
| T026 | Flutter Sprite Registry | medium | pending |
| T027 | Gameplay Integration | medium | pending |
| T028 | Visual QA | low | pending |
| T029 | Final Asset Migration | low | pending |
| T030 | Builder architecture & reusable iso_core foundation | high | done |
| T031 | Editor document, storage, undo/redo & sprite import foundation | high | done |
| T032 | Builder CLI scaffold and project validation | medium | done |
| T033 | Visual isometric map editor | high | done |
| T034 | Sprite browser/animator and asset management UI | high | done |
| T035 | Migrate Head over Heels into games/headoverheels | high | done |
| T036 | TSX authoring: edit tile types/properties and export TSX | medium | done |
| T037 | World graph viewer/editor with topology validation | high | done |
| T038 | Second example game (Knight Lore) on iso_core | medium | done |
| T039 | Puzzle trigger inspector (switch/target links) in the graph tab | medium | done |

## Sprint 01 — Foundation & Research
**Goal**: Understand original game, establish core architecture, prove isometric rendering

| ID | Title | Status |
|----|-------|--------|
| T001 | Research original game mechanics & online MSX version | done |
| T002 | Define core game architecture (isometric rendering, state machine) | done |

## Sprint 02 — Core Gameplay Implementation
**Goal**: Implement Head/Heels character controllers, physics, and basic room rendering with TMX loading

| ID | Title | Status |
|----|-------|--------|
| T003 | Implement Head/Heels character controllers & physics | done |
| T004 | Build isometric level rendering engine with TMX | done |
| T005 | Implement puzzle mechanics (switches, conveyors, doughnuts) | done |

## Sprint 03 — Remaining Puzzle Mechanics
**Goal**: Implement spring, fish, doughnut firing, bag, crown, hush puppy, monster, guardian

| ID | Title | Status |
|----|-------|--------|
| T006 | Implement remaining puzzle mechanics | done |

## Sprint 04 — Final Puzzle Mechanics + InteractionSystem
**Goal**: Crown, bag, hush puppy, guardian, InteractionSystem, test room

| ID | Title | Status |
|----|-------|--------|
| T007 | Implement final puzzle mechanics + InteractionSystem | done |

## Sprint 05 — UI/UX, Touch Controls & Polish
**Goal**: Modern UI/UX, touch controls, HUD, menus, accessibility

| ID | Title | Status |
|----|-------|--------|
| T008 | Create modern UI/UX: menus, HUD, touch controls | done |
| T009 | Implement Bag system (Heels carry items) | done |
| T010 | Connect CharacterState notifier to CharacterComponent | done |
| T011 | Create test room TMX with all entity types | done |

## Sprint 06 — Level Data & Polish
**Goal**: Port original level data, implement audio, polish animations

| ID | Title | Status |
|----|-------|--------|
| T012 | Port original level data / design new levels | done |
| T013 | Audio: SFX, music, adaptive audio system | done |
| T014 | Polish: animations, transitions, accessibility | done |
| T015 | Release build & Play Store preparation | done |

## Sprint 07 — Release
**Goal**: Final polish and Play Store release

| ID | Title | Status |
|----|-------|--------|
| T015 | Release build & Play Store preparation | done |

## Sprint 08 — Asset Production
**Goal**: Complete all visual assets (tilesets, entities, characters)

| ID | Title | Status |
|----|-------|--------|
| T016 | Asset & Visual System Audit | done |
| T017 | Visual Design System | done |
| T018 | Character Masters | done |
| T019 | Character Animation Pipeline | done |
| T020 | Environment Masters | done |
| T021 | Castle Tileset | done |
| T022 | Entity Masters | done |
| T023 | Remaining Themes | done |
| T024 | Validation Pipeline | done |
| T025 | Atlas Pipeline | pending |

## Sprint 09 — Integration & Release
**Goal**: Integration, QA, Release

| ID | Title | Status |
|----|-------|--------|
| T025 | Atlas Pipeline | pending |
| T026 | Flutter Sprite Registry | pending |
| T027 | Gameplay Integration | pending |
| T028 | Visual QA | pending |
| T029 | Final Asset Migration | pending |

## Sprint 10 — Builder Platform
**Goal**: Extract a reusable isometric engine and build editor/CLI foundations

| ID | Title | Status |
|----|-------|--------|
| T030 | Builder architecture & reusable iso_core foundation | done |
| T031 | Editor document, storage, undo/redo & sprite import foundation | done |
| T032 | Builder CLI scaffold and project validation | done |
| T033 | Visual isometric map editor | done |
| T034 | Sprite browser/animator and asset management UI | done |
| T035 | Migrate Head over Heels into games/headoverheels | done |
| T049 | Replace the untracked HoH audio with synthesised cues | done |
| T051 | Publish nested assets: a pubspec entry ships only its own files | done |
| T050 | Clear the 34 analyzer warnings in the HoH code | pending |
| T052 | The Palette panel squeezes its controls out of reach | pending |

## Sprint 11 — Knight Lore Completion
**Goal**: turn the second example game into a finished product, then migrate the
first game onto the same platform

| ID | Title | Status |
|----|-------|--------|
| T040 | Spell scrolls: find, carry and cast the six spells | done |
| T041 | Treasures, chests and the six ingredients, with win state | done |
| T042 | Traps and hazards: impalers, ball chains, blocks, demons | done |
| T043 | Screens: title, status scroll, pause, victory, defeat | done |
| T044 | Procedural audio: effects and one ambient loop | done |
| T045 | Visual polish: shadows, room transitions, ambience, sundial | done |
| T046 | Editor reads both games: world and sprite manifest | done |
| T047 | Visual proof: render the game to images and inspect them | done |
| T048 | Balance pass: days, spell decay, treasure placement | done |
| T036 | TSX authoring: edit tile types/properties and export TSX | done |

## In Progress
* T050: Clear the analyzer warnings in the migrated code

## Queued (after T050)
* T052: The Palette panel squeezes its controls out of reach


## Notes
* T036 scope: the editor could read a TSX and could not write one. Now
  `TsxTileDefinition` and `TsxTilesetDefinition` are values with `copyWith`,
  `withProperty`, `withoutProperty`, `upsertTile` and `removeTile`, a
  `TsxTilesetDefinition.create` that sizes a new tileset from its sheet, a
  `toXmlString` that writes what Tiled reads, and a `TsxValidation` in the same
  shape as the world graph's. The Palette tab grew a tile inspector: edit the
  type, edit the class, add and remove properties, delete the tile, save the
  file, and author a new tileset from a sheet already in the project, whose size
  is measured from the image rather than typed. A property keeps its declared type
  when it is edited, so a number does not quietly become text.
  `test/tsx_authoring_test.dart` (18) covers the model: round trip through
  parse and write, property types, validation, and the catalog. Two layout bugs
  were fixed on the way, both real: the inspector's scroll view handed its fields
  an unbounded width, so a row of `Expanded` grew to 100 000 pixels, and
  `TsxBrowser` overflowed by 10 pixels whenever its panel was short, which the
  existing shell test caught as soon as the inspector took part of the height.
* T052 scope: with the inspector sharing the Palette panel, the save and delete
  controls sit in a 320 pixel column below a browser that wants the space. The
  inspector scrolls, the browser drops its search box under 130 pixels, and the
  buttons are inside the inspector, but driving them from a widget test is a
  fight with hit testing rather than with the code. The panel wants a proper
  layout pass: a tab of its own, or a resizable split.
* T051 scope: a pubspec entry ending in `/` ships the files directly inside that
  directory and nothing below it, so `assets/sprites/` shipped the manifest and
  none of the sprites. Both games were broken in the browser and neither build
  complained: Head over Heels published 1 of 157 files, Knight Lore 34 of 99.
  `scripts/publish_assets.py` now writes the leaf list from the tree between
  markers in each pubspec, and `make check` fails when the two disagree. Head over
  Heels publishes 122 files, which is every file except the gitignored
  `assets/sprites_normalized/` cache; Knight Lore publishes 99 of 99.
  Found while checking that T049's audio reached the web build: the 30 WAVs were
  correctly ignored by the bundler because `assets/audio/` said nothing about
  `assets/audio/music/`.
* T050 scope: `make lint` passes because the gate runs with
  `--no-fatal-infos --no-fatal-warnings`, and it reports 34 findings in the
  migrated HoH code: 3 unused imports, an unused local in
  `sprite_registry.dart`, and the rest deprecations, mostly `withOpacity` in
  `app_theme.dart` and `main_menu_screen.dart`, which Flutter wants written as
  `withValues`. None of them fail a build, and none of them are mine, so they
  are a ticket rather than a drive-by edit inside the migration commit.
* T035 scope: the root package is now `games/headoverheels`. `lib`, `assets`,
  `style`, `test`, the five platform directories, `analysis_options.yaml`,
  `.metadata` and the pubspec moved with `git mv`, so the history follows the
  files. Nothing at the top level is a package any more, so the Makefile names
  where each command runs: `setup` loops over both games and both libraries,
  `test`, `lint` and `build` run in `games/headoverheels`, `format-check` covers
  `games packages`, and `assets-check` passes the game directory to both Python
  validators. `run-headoverheels` and `build-headoverheels` join the Knight Lore
  equivalents. `EditorProject.headoverheels` now points inside `games/`, and its
  test proves every key of both projects stays inside its own game directory.
  Two things the move exposed: `format-check` had never covered `games/`, so ten
  Knight Lore files had drifted from the formatter and are now formatted; and the
  T046 test asserted the two projects differ only by the game directory, which
  stopped being true once both live under `games/`, so the invariant is now the
  stronger one: the sprite paths are parallel and no project can read the other
  game's files.
* T049 scope: the thirty sounds of Head over Heels are now computed, in
  `lib/core/audio/hoh_cues.dart`, and `tool/generate_audio.dart` writes them as
  WAVs under `assets/audio`. The synthesiser moved to `iso_core`, exported as
  `package:iso_core/audio.dart` so a generator can run it on the plain Dart VM
  without Flame, and both games share it. The thirty path constants in
  `AudioSystem` are gone: the class asks `HohCue` for a path, so a sound cannot
  be named without a file behind it, and `test/audio_test.dart` (49 tests) checks
  every cue against the file on disk, that the file is the same sound the cue
  renders, that the eight music loops do not click at the loop point, and that
  nothing under `assets/audio` is anything but a WAV this repository produces.
  The original `.ogg` tracks are not in the repository: nothing produced them and
  their names are the original game's rooms.
* T048 scope: `test/balance_test.dart` measures the game and prints it: 48 room
  changes for a run that knows the world (2.7 of the 40 days), 20 to walk every
  room, and the spell lifetimes in days from the data. Two invariants keep the
  clock meaningful, and the report is in `games/knightlore/README.md`.
  The measurements found four defects, all fixed:
  `nightFalls()` set the werewolf phase in both branches, so Magic Armour and
  Invisibility did nothing and two of the six scrolls were pointless; an instant
  spell (Flip) stayed in the active set for ever, which was the only thing the
  dead `SpellState.advance(ticks)` cleaned up, so that method went too and decay
  now happens at dawn and nowhere else; the emerald and the jewel each existed in
  two containers, and the casket shared a room with one of them, so the six
  ingredients are now one per room across five areas; and the rule that every
  container holds something was right but did not allow a spent container, which
  is now stated rather than assumed.
* T046 scope: `EditorProject` (`packages/iso_editor/lib/src/app/editor_project.dart`)
  is a name plus the paths a game keeps its files in, and the two shipped games
  are declared there as data. The shell has a picker that switches between them,
  the app reloads the sprite manifest of the game being opened, and the graph
  panel is keyed on the project so it reads the new world instead of keeping the
  old graph. `test/editor_projects_test.dart` (6 tests) reads the repository
  through an `EditorStorage`, so the paths are proved against the files the
  games actually write: it opens the Knight Lore world (15 rooms, 5 themes, no
  validation errors), checks its manifest names sheets that exist, and switches
  the picker in a widget test.
  The test found the paths were wrong: Knight Lore's files live inside
  `games/knightlore`, so every key needs the game directory, which is now what
  makes the two projects differ by one string.
* T045 scope: four things, all data or geometry rather than new state.
  `lib/src/render/ambience.dart` holds the light of each area and the shape of a
  shadow; the room view draws a shadow under every figure and washes the finished
  room with the area's colour; `sundial.dart` draws the forty day dial on the HUD
  from a pure geometry class, so a test checks the marker really travels instead
  of trusting a picture; and a room change now fades over `transitionSeconds`
  (0.22s) with the wash easing back in behind it.
  The tests found four defects, all fixed: the fade read the camera size, which
  asserts before the game is laid out and would have crashed the first frame; the
  ambience never came back after a room change, leaving the room unlit forever;
  `RoomView.bounds` was in projection space while everything is drawn in
  `screenOf` space, so the wash was offset by the origin and painted over half
  the screen; and the wash used the view's strength as the alpha, which starts
  at 1, so it was fully opaque instead of the area's own 0.35 to 0.45.
* T044 scope: the audio is synthesised, not sampled. `lib/src/audio/audio_synth.dart`
  is pure Dart (pulse, triangle, noise, glide, envelopes), `knight_lore_cues.dart`
  holds 22 cues and five seamless ambient loops, and `tool/generate_audio.dart`
  writes `assets/audio/*.wav` from that same code. `test/audio_test.dart` proves
  each cue is audible, brief, unclipped, distinct and that the committed files
  match a fresh render, so a cue cannot drift from its file.
  `test/audio_wiring_test.dart` proves the rules actually reach the sounds: a
  step, a bump, a door, a pickup, a trap, a spell per scroll, night and dawn.
  The failures the tests found: the WAV header was not in the pubspec asset list,
  so a release build shipped no audio at all; the frame hash rounded float samples
  to zero and made every sound look identical; and the loop seam test compared
  the wrong samples, which proves nothing for a square wave.
* T047 scope: `KnightLoreGame.createView()` + `RoomView.renderInto()` render a
  room off-screen; `test/visual_preview_test.dart` writes `build/preview/*.png`
  and gates on colour count, an FNV-1a frame hash per area and the bounding box
  of drawn pixels, so a cropped or blank room fails the build. The evidence found
  three real defects: the room was cropped, the tileset mixed 32 and 48 tall
  sprites (walls floated 16px above their tile), and the floor tile's inner
  diamond was drawn off centre, shearing the grid. All three are fixed.
* T033 scope: TMX/TSX import, pan/zoom dimetric canvas with tileset image preview, paint/place/erase
  tools, layer visibility, object inspector, document save/load, TMX export, TSX palette browser and
  file-picker gateways. Known gap: no per-layer tile selection.

## Done
* T001: Research original game mechanics & online MSX version
* T002: Define core game architecture
* T003: Implement Head/Heels character controllers & physics
* T004: Build isometric level rendering engine
* T005: Implement puzzle mechanics (switches, conveyors, doughnuts)
* T006: Implement remaining puzzle mechanics (spring, fish, doughnut, monster)
* T007: Implement final puzzle mechanics + InteractionSystem
* T008: Create modern UI/UX: menus, HUD, touch controls
* T009: Implement Bag system (Heels carry items)
* T010: Connect CharacterState notifier to CharacterComponent
* T011: Create test room TMX with all entity types
* T012: Port original level data / design new levels
* T013: Audio: SFX, music, adaptive audio system
* T014: Polish: animations, transitions, accessibility
* T015: Release build & Play Store preparation
* T016: Asset & Visual System Audit
* T017: Visual Design System
* T018: Character Masters
* T019: Character Animation Pipeline
* T020: Environment Masters
* T021: Castle Tileset
* T022: Entity Masters
* T023: Remaining Themes
* T024: Validation Pipeline
* T030: Builder architecture & reusable iso_core foundation
* T031: Editor document, storage, undo/redo & sprite import foundation
* T032: Builder CLI scaffold and project validation
* T033: Visual isometric map editor (palette/TSX browser, file gateways, canvas preview)
* T034: Sprite browser/animator and asset management UI (manifest editor, frame import, delete)
* T037: World graph viewer/editor with topology validation (Graph tab, world.json round trip)
* T039: Puzzle trigger inspector in the graph tab (targetId and target room editing)
* T040: Spell scrolls — catalogue, chests that hold one item each, casting with 1-9
* T043: Screens — title, pause, status scroll, victory and defeat, with the
  screen state machine in the game so it is testable without widgets
* T042: Traps and hazards — balls block, spikes/blocks/demons catch, a trap fires once
  per visit and costs a day, with a route check that no room becomes unwalkable
* T041: Treasures and the six ingredients — containers open once, statues hold items, the
  wizard never repeats a delivered ingredient, and a full playthrough test wins the game
* T038: Second example game, Knight Lore: rules, world, room maps, generated art, Flame loop,
  HUD, keyboard input and a working web build