---
project: headoverheels
created: 2026-09-18
current_sprint: sprint-10
current_ticket: "T034"
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

## In Progress
* T034: sprite browser/animator and asset management UI — manifest editor, filters, frame
  append/import, delete and frame mismatch validation landed; awaiting commit
* T036: TSX authoring (edit tile `type`/properties, write TSX)

## Notes
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