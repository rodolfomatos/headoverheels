# Vision — Head over Heels (Flutter Port)

## Problem

The original *Head over Heels* (1987, Ocean Software) is a landmark isometric puzzle-platformer with innovative dual-character mechanics. It's historically significant but practically unplayable today:
- No native mobile version exists
- Original controls (keyboard/joystick) don't translate to touch
- Visuals are locked to 8-bit era constraints (ZX Spectrum/MSX/Amstrad)
- No accessibility features (colorblind, motor impairment, screen readers)
- Preservation relies on emulators — barrier to entry for new players

**Who is hurt:** Retro gaming enthusiasts, game design students studying dual-character mechanics, accessibility advocates, anyone wanting to experience a classic without emulator friction.

**If not solved:** The game remains a museum piece rather than a playable experience. Design lessons (character asymmetry, isometric puzzle design, emergent gameplay from simple rules) stay buried.

## Solution

A faithful-but-modern Flutter port for Android that:
- **Preserves core design**: Dual-character switching (Head/Heels), isometric puzzle-platforming, all original puzzle elements (switches, conveyors, doughnuts, reincarnation fish)
- **Modernizes UI/UX**: Touch-first controls (virtual joystick + context actions), scalable vector assets, 60fps rendering, adaptive layouts
- **Adds accessibility**: Colorblind palettes, configurable control schemes, screen reader support, haptic feedback, difficulty assists
- **Leverages Flutter**: Single codebase for future iOS/Web/Desktop, hot reload for iteration, custom rendering via CustomPainter/Flame
- **Data-driven**: Levels in JSON/TMX, assets in sprite atlases, config-driven physics for tuning

## Value

**Impact metrics:**
- Playable on 3B+ Android devices without emulator
- Preserves game design history in accessible form
- Reference implementation for isometric games in Flutter
- Portfolio piece demonstrating game dev + Flutter expertise

**Success criteria:**
- [ ] All original rooms/mechanics functional
- [ ] 60fps on mid-range Android (Snapdragon 7xx / equivalent)
- [ ] Touch controls feel natural (not "ported keyboard")
- [ ] Accessibility audit passes (WCAG 2.1 AA baseline)
- [ ] Release build < 100MB APK
- [ ] Zero crashes in 1hr playtest sessions