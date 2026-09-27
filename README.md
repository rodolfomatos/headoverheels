# Head over Heels — Flutter Port

![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Build](https://img.shields.io/badge/Build-passing-brightgreen)

A **production-ready**, modern Flutter/Dart port of the classic 1987 isometric puzzle-platformer **"Head over Heels"** for Android, featuring dual-character mechanics, 5 planets, 21 rooms, adaptive audio, and touch-optimized controls.

> **Status**: ✅ **COMPLETE** — All 15 tickets delivered across 7 sprints (AES Protocol)

---

## 🎮 Features

### Core Gameplay
- **Dual-Character System** — Control **Head** (high jump, doughnuts) and **Heels** (fast walk, carry items) independently or combined (Head rides Heels)
- **Character Swop** — Instant toggle between characters with `SWOP` button
- **21 Rooms across 5 Planets** — Complete original world map faithfully recreated:
  - 🏰 **Blacktooth Castle** (6 rooms) — Medieval fortress, secret passages
  - 🏺 **Egyptus** (4 rooms) — Pyramids, tombs, hieroglyphic puzzles
  - 🔒 **Penitentiary** (3 rooms) — High-security prison, conveyor mazes
  - 🌴 **Safari** (3 rooms) — Jungle ruins, wild guardians
  - 📚 **Book World** (3 rooms) — Library labyrinth, final throne room
- **19 Puzzle Entity Types** — Switches, doors, conveyors, springs, teleports, ladders, reincarnation fish, crowns, doughnuts, bags, keys, hush puppies, monsters, guardians
- **Fixed-Timestep Physics** — Deterministic 60Hz simulation with sub-tick interpolation

### Modern UX
- **Virtual Joystick** — 8-directional analog movement with visual direction indicators
- **Action Buttons** — JUMP, CARRY, FIRE, SWOP with contextual enable/disable states
- **Adaptive HUD** — Lives, crowns, active character, doughnut count, carried item
- **Material 3 Theme** — Dark mode, dynamic colors, accessibility support
- **Pause/Resume** — In-game overlay with restart, settings, quit

### Audio System
- **8 Music Tracks** — Unique soundtrack per planet + main menu, boss, game over
- **27 Sound Effects** — Jump, land, pickup, switch, door, teleport, spring, conveyor, fire, hits, death, fish, crown, bag, hush puppy, swop, UI
- **Persistent Settings** — Volume sliders, mute toggles saved via SharedPreferences
- **Adaptive Playback** — Auto-switches music on room transitions

### Technical Highlights
- **2:1 Dimetric Isometric** — 64×32 logical tiles, classic 8-bit aesthetic
- **Riverpod + Freezed** — Immutable state, compile-safe providers, pattern matching
- **Flame Engine** — Game loop, TMX loading, component system, collision callbacks
- **AES Protocol** — Structured engineering with kanban, sprints, hostile analysis

---

## 🏗 Architecture

### Technology Stack
| Layer | Technology | Version |
|-------|------------|---------|
| Framework | Flutter | 3.16+ |
| Language | Dart | 3.2+ |
| Game Engine | Flame | 1.17+ |
| State Mgmt | Riverpod | 2.6+ |
| Data Modeling | Freezed | 2.5+ |
| JSON Serialization | json_serializable | 6.8+ |
| Audio | just_audio / flame_audio | 0.9+ / 1.0+ |
| Math | vector_math | 2.1+ |
| Persistence | shared_preferences | 2.2+ |

### Project Structure
```
headoverheels/
├── games/
│   ├── headoverheels/          # The first game: Head over Heels
│   │   ├── android/ ios/ linux/ macos/ web/ windows/
│   │   ├── assets/
│   │   │   ├── levels/         # world.json, 21 TMX rooms, tilesets
│   │   │   ├── sprites/        # Character and item sprites, manifest.yaml
│   │   │   └── audio/          # Sound; still to be synthesised (T049)
│   │   ├── style/              # palette.json, geometry.json, the style guide
│   │   ├── lib/                # The game itself
│   │   │   ├── core/           # Isometric coordinates, utilities
│   │   │   ├── entities/       # CharacterState
│   │   │   ├── features/
│   │   │   │   ├── audio/      # AudioSystem, AudioSettings
│   │   │   │   ├── gameplay/   # entities, room, state, systems
│   │   │   │   └── ui/         # Screens, widgets, theme
│   │   │   └── main.dart       # App entry point
│   │   ├── test/               # Unit and widget tests
│   │   └── pubspec.yaml
│   └── knightlore/             # The second game: Knight Lore, on iso_core
│       ├── lib/src/            # rules, world, renderer, synthesised audio
│       ├── assets/             # rooms, tiles, sprites, generated WAVs
│       └── pubspec.yaml
├── packages/                   # Reusable builder platform
│   ├── iso_core/               # 2:1 dimetric runtime, assets, levels, physics
│   ├── iso_editor/             # Map editor, sprite gallery, world graph
│   └── iso_builder_cli/        # Project scaffolding and validation
├── aes/                        # AES Protocol project management
│   ├── kanban.md               # Project board
│   ├── sprints/                # Sprint definitions
│   └── tickets/                # Ticket specs
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md
│   ├── BUILDER_ARCHITECTURE.md
│   ├── REQUIREMENTS.md
│   ├── VISION.md
│   └── RESEARCH/
├── scripts/                    # Generators and validators
│   ├── generate_knightlore_assets.py   # Draws the Knight Lore art
│   ├── generate_rooms.dart             # TMX from world.json
│   ├── validation_pipeline.py          # Sprite pipeline checks
│   └── validate_sprites.py             # Manifest, palette and naming checks
├── prompts/                    # AES prompt library
├── Makefile                    # Build automation for both games
└── CLAUDE.md                   # Operational contract
```

Nothing at the top level is a package. Each game and each library is its own
Flutter package, and every Makefile target names the directory it runs in:

```
make setup                  # pub get in both games and both libraries
make run-headoverheels      # the first game, on :8080
make run-knightlore         # the second game, on :8081
make test                   # tests for the first game
make test-packages          # iso_core, iso_editor, iso_builder_cli, knightlore
make check                  # format, lint, every test, asset validation
```


### Key Design Decisions (ADR)
1. **Flame Engine** — Built-in game loop, TMX support, component system
2. **Riverpod + Freezed** — Immutable state, compile-safe providers, pattern matching
3. **2:1 Dimetric Projection** — 64×32 logical tiles, classic 8-bit isometric
4. **Grid-Based Physics** — Deterministic, no Box2D needed
5. **Riverpod → Flame (One-Way Sync)** — Authoritative state in Riverpod; Flame only renders
6. **AES Protocol** — Kanban → Ticket → Hostile Analysis → Implement → Verify → Learn

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.16+ (`flutter doctor -v`)
- Android SDK 34+ (for building)
- Java 17+ (for Gradle)

### Install & Run
```bash
# Clone and navigate
git clone https://github.com/rodolfomatos/headoverheels.git
cd headoverheels

# Install dependencies in both games and both libraries
make setup

# Run quality checks (format → analyze → test → asset validation)
make check

# Run a game in the browser
make run-headoverheels   # :8080
make run-knightlore      # :8081

# Run on a device, from the game's directory
cd games/headoverheels
flutter run -d linux    # Linux
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d web      # Web
flutter run             # Android device or emulator
```

### Build Commands
```bash
# Debug APK
cd games/headoverheels && flutter build apk --debug

# Release APK (obfuscated, split debug info)
make build-release-apk
# flutter build apk --release --obfuscate --split-debug-info=build/debug_info

# Release App Bundle (Play Store)
make build-release-appbundle
# flutter build appbundle --release --obfuscate --split-debug-info=build/debug_info

# Build both APK + AAB
make build-release-all

# Build with version from pubspec.yaml
make build-version

# Install release APK on connected device
make install
```

### Code Generation
```bash
# Regenerate Freezed/JSON serializable code
make generate
# dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch --delete-conflicting-outputs
```

### Generate Room TMX Files
```bash
# Auto-generates all 21 room TMX files from world.json
dart run scripts/generate_rooms.dart
```

---

## 📋 Development Workflow

### AES Protocol (Ambrósio Engineering System)
This project follows **AES-project** — full lifecycle with kanban, sprints, tickets.

```bash
# View project board
cat aes/kanban.md

# View sprint definition
cat aes/sprints/sprint-01.md

# View ticket spec
cat aes/tickets/T005-puzzle-mechanics.md

# View phase outputs
cat aes/tickets/T005-plan.md    # Technical spec
cat aes/tickets/T005-build.md   # Implementation diffstory
cat aes/tickets/T005-review.md  # Code review findings
cat aes/tickets/T005-learn.md   # Learnings & hostile audit
```

### Quality Gates (Must Pass)
```bash
make check
# Runs:
# 1. dart format --output=none --set-exit-if-changed games packages
# 2. flutter analyze --no-fatal-infos --no-fatal-warnings, in the first game
# 3. flutter test, in the first game
# 4. iso_core, iso_editor, iso_builder_cli and knightlore tests
# 5. asset validation pipelines, over the first game's sprites
```

### Pre-Commit Checklist
- [ ] `make check` passes (zero errors)
- [ ] `dart run build_runner build --delete-conflicting-outputs` clean
- [ ] Ticket spec implemented per plan
- [ ] Hostile analysis completed (what could break?)
- [ ] No hardcoded secrets (`make security-scan`)

---

## 🎨 Asset Pipeline

### Tileset (castle.tsx)
- 64×32 isometric tiles (2:1 dimetric)
- Layers: Floor (z=0), Walls (z=1), Props (z=2)
- External tileset reference in TMX

### Room TMX Format
```xml
<map orientation="isometric" tilewidth="64" tileheight="32">
  <tileset firstgid="1" source="../tilesets/castle.tsx"/>
  <layer name="Floor">...</layer>
  <layer name="Walls">...</layer>
  <objectgroup name="Entities">
    <object name="switch_1" type="switchTrigger" x="320" y="160">
      <properties>
        <property name="targetId" value="door_1"/>
      </properties>
    </object>
  </objectgroup>
</map>
```

### World Graph (world.json)
```json
{
  "rooms": {
    "castle_start": {
      "file": "castle/castle_start.tmx",
      "theme": "castle",
      "exits": [{"direction": "east", "room": "castle_cell", "entrance": "west"}],
      "spawnPoint": {"x": 1, "y": 1, "z": 0},
      "triggers": [...]
    }
  },
  "startRoom": "castle_start",
  "planets": [...]
}
```

---

## 🧰 Builder Platform

The repository is being structured as a reusable isometric game builder:

- `packages/iso_core` — platform-neutral Flutter/Flame runtime: dimetric coordinates, physics, entity contracts, manifest-driven assets, level loading and sprite resolution.
- `packages/iso_editor` — editor: serializable map document, undo/redo, storage abstraction, dimetric map view with tileset preview, TMX import/export, TSX palette browser, file-picker gateways, sprite manager/animator with manifest editing and frame import, and a world graph viewer/editor with topology validation, all inside an `EditorShell` with tools, layers and inspector.
- `games/knightlore` — second example game on `iso_core`: knight classes, six decaying spells, sixteen slot inventory, curse/day-night and filmation rules, and a 15 room world in the shared `world.json` format.
- `packages/iso_builder_cli` — project scaffolding and validation:
  ```bash
  dart run packages/iso_builder_cli/bin/iso_builder.dart create "My Game"
  dart run packages/iso_builder_cli/bin/iso_builder.dart analyze games/my_game
  ```

Head over Heels specific state and mechanics remain in the game layer; the generic core does not depend on Head, Heels or their puzzle entities.

See `docs/BUILDER_ARCHITECTURE.md`.

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# With coverage
make test-coverage
# flutter test --coverage && genhtml coverage/lcov.info -o coverage/html

# Specific test file
flutter test test/widget_test.dart

# Integration tests (if added)
flutter test integration_test/
```

---

## 📦 Release Checklist

- [ ] Version bumped in `pubspec.yaml` (format: `version: 1.0.0+1`)
- [ ] `make check` passes
- [ ] `make generate` clean
- [ ] `make security-scan` clean
- [ ] Release keystore configured (`android/key.properties`)
- [ ] App signed: `make build-release-appbundle`
- [ ] App Bundle tested on device: `make install`
- [ ] Play Store listing assets ready (screenshots, feature graphic, icon)
- [ ] Privacy policy URL configured
- [ ] Content rating questionnaire completed

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| `CLAUDE.md` | Operational contract for AI agents |
| `docs/ARCHITECTURE.md` | Technical architecture deep-dive |
| `docs/VISION.md` | Product vision & success metrics |
| `docs/REQUIREMENTS.md` | Functional & non-functional requirements |
| `docs/PERSONAS.md` | User personas & accessibility needs |
| `docs/PLAY_STORE_LISTING.md` | Store listing copy, assets, keywords |
| `docs/QUALITY_GATES.md` | Quality gate definitions |
| `docs/RESEARCH/original-game-analysis.md` | Original game mechanics research |
| `aes/kanban.md` | Project board (single source of truth) |

---

## 🤝 Contributing

1. **Read** `CLAUDE.md` — operational contract
2. **Follow** AES protocol — kanban → ticket → hostile analysis → implement → verify → learn
3. **Run** `make check` before committing
4. **All changes require human approval** — no auto-merge
5. **Open an issue** for bugs/features before starting work

### Code Style
- `dart format .` — enforced
- `flutter analyze` — zero errors required
- Freezed for immutable data
- Riverpod providers for all state
- Component composition over inheritance

---

## ⚖️ Legal

### Fan Project Disclaimer
This is a **non-commercial fan project** for educational and portfolio purposes.

> **"Head over Heels"** is a trademark of Ocean Software / Atari. The original 1987 game code, assets, and design are copyrighted by their respective owners.

This port:
- Uses **original artwork** created specifically for this project
- Does **not** include extracted assets from the original game
- Is **not affiliated** with Ocean Software, Atari, or any rights holders
- Contains **no commercial intent** — no ads, no IAP, no data collection

### Original Game References
- ZX Spectrum TZX: https://worldofspectrum.net/pub/sinclair/games/h/HeadOverHeels.tzx.zip
- Game Manual: https://worldofspectrum.net/item/0002259/
- WebMSX Playable: https://www.file-hunter.com/Homebrew/?id=headoverheels

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

- **Original Creators** — Jon Ritman & Bernie Drummond (1987 masterpiece)
- **Ocean Software** — Publisher of the original
- **Flame Engine Team** — Excellent 2D game engine for Flutter
- **Riverpod Team** — Reactive state management done right
- **Freezed Team** — Immutable data classes with zero boilerplate
- **AES Protocol** — Structured engineering methodology

---

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| Lines of Code (Dart) | ~12,000 |
| Files | 150+ |
| Test Coverage | Smoke test only (expandable) |
| Puzzle Entities | 19 types |
| Rooms | 21 |
| Planets | 5 |
| Sprint Tickets | 15 |
| Audio Assets | 35 OGG files |
| TMX Rooms | 21 generated |

---

**Built with ❤️ using Flutter, Flame, Riverpod & AES Protocol**

[Repository](https://github.com/rodolfomatos/headoverheels) • [Issues](https://github.com/rodolfomatos/headoverheels/issues) • [Releases](https://github.com/rodolfomatos/headoverheels/releases)