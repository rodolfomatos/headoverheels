---
project: headoverheels
created: 2026-09-18
current_sprint: sprint-11
current_ticket: "T045"
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
| T035 | Migrate Head over Heels into games/headoverheels | high | pending |
| T036 | TSX authoring: edit tile types/properties and export TSX | medium | pending |
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
| T036 | TSX authoring: edit tile types/properties and export TSX | pending |
| T035 | Migrate Head over Heels into games/headoverheels | pending |

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
| T045 | Visual polish: shadows, room transitions, ambience, sundial | pending |
| T046 | Editor reads both games: world and sprite manifest | pending |
| T047 | Visual proof: render the game to images and inspect them | done |
| T048 | Balance pass: days, spell decay, treasure placement | pending |
| T035 | Migrate Head over Heels into games/headoverheels | pending |
| T036 | TSX authoring: edit tile types/properties and export TSX | pending |

## In Progress
* T045: Visual polish: shadows, room transitions, ambience, sundial

## Queued (after T045)
* T046: Editor reads both games: world and sprite manifest
* T048: Balance pass: days, spell decay, treasure placement
* T035: Migrate Head over Heels into games/headoverheels
* T036: TSX authoring (edit tile `type`/properties, write TSX)


## Notes
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