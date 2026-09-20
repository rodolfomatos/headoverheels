---
ticket: T002
title: Define core game architecture (isometric rendering, state machine)
sprint: sprint-01
priority: high
status: done
created: 2026-09-18
---

# T002 — Define Core Game Architecture

## Context
Based on T001 research, define the Flutter architecture for an isometric puzzle-platformer with dual-character mechanics.

## Acceptance Criteria
- [ ] Architecture decision record (ADR) in `docs/ARCHITECTURE.md`
- [ ] Isometric rendering approach chosen (Flutter CustomPainter vs Flame engine vs custom)
- [ ] State management pattern selected (Riverpod, Bloc, Provider, or vanilla)
- [ ] Game loop architecture defined (fixed timestep, interpolation)
- [ ] Entity-component-system or alternative for game objects
- [ ] Input abstraction for touch/gamepad/keyboard
- [ ] Level data format defined (JSON, custom binary, Tiled TMX)
- [ ] Asset pipeline strategy (sprite sheets, atlas, runtime loading)

## Scope
**In scope:**
- Technical architecture decisions with tradeoffs documented
- Proof-of-concept: render isometric tile + character movement
- Dependency selection in `pubspec.yaml`

**Out of scope:**
- Full level implementation
- Character controllers (T003)
- Puzzle mechanics (T005)

## Dependencies
- T001 (research complete)

## Rollback
Revert `pubspec.yaml` and architecture docs

## Known Risks
- Flutter's CustomPainter performance for 60fps isometric
- Flame engine adds dependency but provides game loop
- Touch controls for isometric movement are non-trivial

## Notes
Key decisions needed:
1. **Rendering**: CustomPainter (full control) vs Flame (game engine) vs Flutter 3D (impeller)
2. **State**: Riverpod (modern, compile-safe) vs Bloc (explicit, testable) vs Provider (simple)
3. **Physics**: Custom fixed-timestep vs Box2D (flame_forge2d) - likely overkill for grid-based
4. **Levels**: Tiled map editor (TMX) vs custom JSON vs procedural