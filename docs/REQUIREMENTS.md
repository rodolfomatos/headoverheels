# Requirements — Head over Heels (Flutter Port)

## Functional Requirements

### Core Gameplay
- **FR-01**: Dual-character system — player controls Head and Heels, can switch between them
- **FR-02**: Character abilities — Head: higher jump, shoots doughnuts; Heels: faster run, carries objects, uses bag
- **FR-03**: Character combination — when together, abilities merge (Head on Heels' shoulders)
- **FR-04**: Isometric movement — 8-directional grid-based movement with smooth interpolation
- **FR-05**: Jumping physics — parabolic arcs, variable height based on character, landing detection
- **FR-06**: Puzzle elements — pressure switches, conveyor belts, doughnut dispensers, reincarnation fish, doors/keys
- **FR-07**: Room-based levels — 300+ rooms connected via doors, each room a self-contained puzzle
- **FR-08**: Collectibles — crowns, doughnuts, other items with persistence across sessions
- **FR-09**: Lives/continue system — reincarnation fish as checkpoints, game over on life depletion
- **FR-10**: Win condition — collect all crowns, reach final room

### Input & Controls
- **FR-11**: Touch controls — virtual analog stick (left), context action buttons (right)
- **FR-12**: Gamepad support — standard Bluetooth/USB controllers
- **FR-13**: Keyboard support — for desktop/web testing (WASD + space + action keys)
- **FR-14**: Control customization — button layout, sensitivity, left/right handed modes

### UI & UX
- **FR-15**: Main menu — New Game, Continue, Settings, Credits
- **FR-16**: In-game HUD — lives, crowns collected, current character, mini-map (optional)
- **FR-17**: Pause menu — Resume, Restart Room, Settings, Quit
- **FR-18**: Settings — Audio, Controls, Accessibility, Graphics, Language
- **FR-19**: Onboarding — interactive tutorial for first-time players
- **FR-20**: Save/Load — auto-save on room transition, manual save slots

### Accessibility
- **FR-21**: Colorblind modes — Protanopia, Deuteranopia, Tritanopia, Monochrome
- **FR-22**: High contrast mode — UI and game elements
- **FR-23**: Screen reader support — semantic labels, live regions for game state
- **FR-24**: Motor accessibility — auto-jump assist, reduced precision requirements, hold-to-move
- **FR-25**: Text scaling — respects system font size, minimum 14sp

### Technical
- **FR-26**: Asset pipeline — sprite sheets loaded from JSON atlas, runtime streaming for large levels
- **FR-27**: Level format — TMX (Tiled) or custom JSON with room definitions
- **FR-28**: Audio — background music (adaptive), SFX (pooled), volume controls per category

## Non-Functional Requirements

### Performance
- **NFR-01**: 60 FPS sustained on Android API 24+ (Snapdragon 710 / Kirin 810 / equivalent)
- **NFR-02**: Cold start < 3s to playable state
- **NFR-03**: APK size < 100MB (assets compressed, code shrunk)
- **NFR-04**: Memory < 200MB RSS during gameplay
- **NFR-05**: Battery drain < 5%/hour on typical device

### Quality
- **NFR-06**: Unit test coverage ≥ 80% for core logic (game loop, physics, state machine)
- **NFR-07**: Widget test coverage ≥ 70% for UI flows
- **NFR-08**: Zero `flutter analyze` warnings (strict mode)
- **NFR-09**: Zero critical/severe findings in `flutter analyze --fatal-infos`

### Maintainability
- **NFR-10**: Clean Architecture — `lib/core`, `lib/features`, `lib/entities`, `lib/services`
- **NFR-11**: Dependency injection via Riverpod/Provider — no service locators
- **NFR-12**: Immutable state — Freezed for value objects, no mutable globals
- **NFR-13**: Documentation — public APIs dartdoc'd, architecture decisions in ADRs

### Compatibility
- **NFR-14**: Android API 24+ (Android 7.0 Nougat)
- **NFR-15**: ARM64 and ARM32 (flutter build handles both)
- **NFR-16**: Portrait and landscape (landscape primary for gameplay)

### Security & Privacy
- **NFR-17**: No network permissions required (offline-first)
- **NFR-18**: No analytics/telemetry without explicit opt-in
- **NFR-19**: Local storage only (SharedPreferences + file system)

## Constraints

- **Language**: Dart 3.x / Flutter 3.x (stable channel)
- **Deployment**: Android (Google Play), future iOS/Web/Desktop
- **Dependencies**: Minimize native deps; prefer pure Dart packages
  - State: `flutter_riverpod` or `bloc`
  - Rendering: `flame` (game engine) or pure `CustomPainter`
  - Audio: `audioplayers` or `just_audio`
  - Serialization: `freezed` + `json_serializable`
  - DI: `riverpod` (built-in)
- **Assets**: Original game assets are copyrighted — must create original/replacement assets
- **Legal**: "Head over Heels" trademark owned by Ocean/Atari — this is a fan project, not commercial