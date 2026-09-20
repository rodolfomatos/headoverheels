---
ticket: T008
title: Create modern UI/UX: menus, HUD, touch controls
sprint: sprint-05
priority: high
status: in-progress
created: 2026-10-16
---

# T008 — Create Modern UI/UX: Menus, HUD, Touch Controls

## Context
Implement the modern UI/UX for Head over Heels on Android, including main menu, HUD, touch controls, and accessibility features.

## Acceptance Criteria
- [ ] Main Menu: New Game, Continue, Settings, Credits
- [ ] HUD: Lives, Crowns collected, Current character, Doughnut count, Bag item
- [ ] Touch Controls: Virtual joystick (left), Action buttons (right: Jump, Carry, Fire, Swop)
- [ ] Pause Menu: Resume, Restart Room, Settings, Quit
- [ ] Settings: Audio, Controls, Accessibility, Graphics, Language
- [ ] Accessibility: Colorblind modes, High contrast, Screen reader support, Motor assists
- [ ] Game Over / Win screens
- [ ] Responsive layout for different screen sizes

## Scope
**In scope:**
- Flutter widget-based UI (Material 3)
- Touch-friendly controls (48dp minimum touch targets)
- Virtual joystick with dead zone
- Context-sensitive action buttons
- Accessibility features (WCAG 2.1 AA)
- Screen reader semantics

**Out of scope:**
- Complex animations (simple transitions OK)
- Particle effects in UI
- Multiplayer UI

## Dependencies
- T003 (character state for HUD data)
- T004 (room system for pause/resume)
- T006/T007 (entity interactions for HUD)

## Known Risks
- Virtual joystick feel on touch screens
- Touch target sizes for accessibility
- Screen reader support for game state
- Landscape vs portrait handling (game is landscape)

## Notes
Reference: `docs/REQUIREMENTS.md` FR-11 through FR-25
Design system: `docs/DESIGN.md` (to be created)