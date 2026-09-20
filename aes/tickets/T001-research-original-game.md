---
ticket: T001
title: Research original game mechanics & online MSX version
sprint: sprint-01
priority: high
status: done
created: 2026-09-18
---

# T001 — Research Original Game Mechanics & Online MSX Version

## Context
Head over Heels (1987) is an isometric puzzle-platformer with dual-character mechanics (Head and Heels). Need to deeply understand:
- Movement physics (isometric grid, jumping arcs)
- Character abilities (Head: jumps higher, shoots doughnuts; Heels: runs faster, carries objects)
- Puzzle elements (switches, conveyors, doughnuts, reincarnation fish)
- Level structure and progression
- Original ZX Spectrum / MSX technical constraints

Resources:
- **Original ZX Spectrum TZX**: https://worldofspectrum.net/pub/sinclair/games/h/HeadOverHeels.tzx.zip
- **Game instructions/manual**: https://worldofspectrum.net/item/0002259/
- **Online MSX version** (playable): https://www.file-hunter.com/Homebrew/?id=headoverheels

The online MSX version is playable in browser - perfect for Playwright analysis. The TZX can be analyzed with tools like `tzxtools` or Fuse emulator for authentic timing.

## Acceptance Criteria
- [ ] Playwright script captures gameplay video of MSX version
- [ ] Documented: movement physics, jump arcs, character abilities
- [ ] Documented: all puzzle element types and behaviors
- [ ] Documented: level format / room transitions
- [ ] Asset inventory: sprites, tiles, UI elements needed
- [ ] Technical constraints identified for Flutter port

## Scope
**In scope:**
- Automated Playwright analysis of online MSX version
- Manual playthrough for design feel
- Documentation in `docs/RESEARCH/original-game-analysis.md`
- Asset extraction plan

**Out of scope:**
- Actual Flutter implementation
- Level editor creation
- Audio implementation

## Dependencies
- Playwright installed (`flutter pub add -d playwright` or standalone Node)
- Network access to file-hunter.com

## Rollback
N/A - research only

## Known Risks
- Online version may differ from original ZX Spectrum
- MSX version may have different timing/physics
- Site may block automated access

## Notes
Use Playwright to:
1. Navigate to the MSX version
2. Record gameplay sessions
3. Extract frame-by-frame analysis of movement
4. Catalog all interactive elements
5. Measure timing (jump duration, walk speed, etc.)