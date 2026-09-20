# Personas — Head over Heels (Flutter Port)

## Primary User: Retro Gaming Enthusiast ("Alex")

**Profile:** 30-45, grew up with 8-bit computers (Spectrum, C64, Amstrad). Plays on phone during commute/lunch. Values authenticity but expects modern polish. Owns Bluetooth controller but mostly uses touch.

**Goals:**
- Experience Head over Heels authentically without emulator setup
- Play in short sessions (5-15 min) with reliable save/resume
- Feel the original's puzzle satisfaction on touch screen
- Share progress/screenshots with retro community

**Pain Points:**
- Emulators require ROM hunting, config, on-screen keyboard overlay
- Touch controls in emulators are miserable (virtual keyboard)
- No cloud save across devices
- Battery drain from emulator overhead

---

## Secondary User: Accessibility-First Player ("Sam")

**Profile:** 25-40, motor impairment (tremor, limited dexterity) or color vision deficiency. Plays mobile games but abandons those with poor accessibility. Uses system accessibility features (switch control, voice control, high contrast).

**Goals:**
- Play a classic puzzle-platformer without barriers
- Use system accessibility services (TalkBack, Switch Access)
- Customize controls to their physical capabilities
- Not feel "othered" by separate "accessible mode"

**Pain Points:**
- Most retro ports ignore accessibility entirely
- Virtual joysticks require steady thumb — impossible with tremor
- Color-coded puzzles (doughnuts, switches) fail for colorblind
- No remappable controls, no assist modes

---

## Tertiary User: Game Design Student ("Jordan")

**Profile:** 20-28, studying game design or CS. Analyzes mechanics, level design, state machines. Wants to understand *why* Head over Heels works. May read source code.

**Goals:**
- Study dual-character asymmetry as mechanic
- Analyze isometric puzzle design patterns
- Reference clean, documented Flutter game architecture
- Experiment with mechanics in a real codebase

**Pain Points:**
- Original source lost; only disassemblies exist
- Modern ports often messy (spaghetti code, no tests)
- Hard to isolate single mechanics for study
- No documentation of design intent

---

## Maintainer Persona ("You / Contributor")

**Profile:** Engineer maintaining this codebase long-term. Values clean architecture, testability, and low friction for changes.

**Goals:**
- Keep code clean, documented, and testable
- Ensure `make check` catches regressions fast
- Onboard new contributors in < 30 min
- Evolve architecture without rewrites

**Tools:**
- AES (Ambrósio Engineering System) — kanban, sprints, tickets
- `make check` — test + lint + format gate
- `flutter analyze --fatal-infos` — strict static analysis
- Riverpod/Bloc — explicit, testable state management
- Freezed — immutable data, pattern matching
- Flame or CustomPainter — rendering abstraction