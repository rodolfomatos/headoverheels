# Head over Heels - Original Game Analysis

**Research Date**: 2026-09-18  
**Ticket**: T001  
**Sources Analyzed**:
- Original ZX Spectrum TZX tape image (Speedlock protected)
- WebMSX online playable version (KonamiSCC cartridge)
- Official game instructions (English + French)
- Game maps (4 high-res images)
- World of Spectrum metadata

---

## Game Overview

**Title**: Head over Heels  
**Authors**: Jon Ritman & Bernie Drummond  
**Publisher**: Ocean Software Ltd (1987)  
**Platforms**: ZX Spectrum 48K/128K, Amstrad CPC, Commodore 64/128, MSX  
**Genre**: Isometric puzzle-platformer with dual-character mechanics

---

## Core Gameplay Mechanics

### Dual-Character System
- **Head (Headus Mouthion)**: Descended from flying reptile, rudimentary wings
  - Jumps up to **2x own height**
  - Can **guide himself through air** (mid-air control)
  - **Only character who can FIRE** (hooter/doughnuts)
  - **Slow movement speed**
  
- **Heels (Footus Underium)**: Arms disappeared, powerful legs
  - Jumps **1x own height**
  - **Runs very fast**
  - **Only character who can CARRY** objects (requires bag)
  - Cannot fire

- **Combined (Head on Heels)**:
  - All abilities merged
  - Swop key cycles: Heels → Head&Heels → Head → Head&Heels (when joined)
  - Swop key cycles: Head → Heels (when separate)
  - Cannot swop in doorways

### Controls (Spectrum Default)
| Action | Keys | Joystick |
|--------|------|----------|
| LEFT | O, 6 | Left |
| RIGHT | P, 7 | Right |
| DOWN | A, 8 | Down |
| UP | Q, 9 | Up |
| JUMP | Space, Symbol Shift, M, N, B | Fire |
| CARRY | Space, Enter, L, K, J | - |
| FIRE | Shift, Z, X, C, V | - |
| SWOP | S, D, F, G | - |
| PAUSE | H (hold) | - |

**Key insight**: Space = Jump + Carry (both actions with one key)

---

## Puzzle Elements

### 1. Reincarnation Fish (Checkpoints)
- **Alive**: Wriggling - acts as checkpoint/save point
- **Dead**: Decomposes quickly, poisonous - kills on touch
- When eaten: Remembers player state, respawns at that location on death
- **Critical**: Must check fish is alive before eating

### 2. Cuddly Stuffed White Rabbits (Power-ups)
Four types, temporary enhancement (status display at bottom):
1. **Two extra lives** (Life pill icon)
2. **Iron Pills** - Invulnerability (Shield icon)
3. **Jump higher bunny** - Only works on **Heels** (Spring icon)
4. **Go faster bunny** - Only works on **Head** (Flash icon)

**Wrong character pickup = wasted power!**

### 3. Hooter & Doughnuts (Head only)
- Head fires doughnuts at monsters
- Freezes monsters while they "lick doughnuts off faces"
- **Tray = 6 doughnuts** (rare, don't waste)
- Doughnut count shown at bottom-left

### 4. Bag (Heels only)
- Essential for progression
- Carries one small object per room
- Object displayed at bottom-right
- Pick up: Stand on object + CARRY key
- **Cannot drop in doorways**

### 5. Crowns (Win condition)
- 5 crowns total (one per planet: Egyptus, Penitentiary, Safari, Book World, Blacktooth)
- Collecting crown = revolution on that planet
- Planet screen shows collected crowns in bright color

### 6. Teleports
- Activate on standing (warning siren)
- Press JUMP to teleport
- **Not all two-way** - some chained one-way

### 7. Springs
- Extra jump height when jumping from them
- Can be carried (by Heels) and placed for extra height

### 8. Switches
- Push to toggle on/off
- **WARNING**: Switching off deadly monster stops movement but **still deadly to touch**

### 9. Conveyor Belts
- Push player along direction
- Opposite direction = must **jump** along

### 10. Hush Puppies
- Sleeping creatures (never wake)
- Used as tables/building blocks
- **Teleport away** when Head/race approaches
- Don't return until coast clear

### 11. Emperor's Guardian (Blacktooth Castle)
- Blocks throne room door
- **Doesn't like doughnuts** (immune)
- Only "true hero" may pass

---

## Level Structure

### Planets / Areas (5 total)
1. **Blacktooth Castle** - Starting area, market, mountains, teleport to moon stations
2. **Moonbase HQ** - Main teleport center, 3 lunar space stations
3. **Egyptus** - Pyramid/mummy theme, bandaged corpses
4. **Penitentiary** - Prison planet, mountainous, "The Pit" (deadly fall)
5. **Safari** - Jungle, wooden forts, traps
6. **Book World** - Western library, cowboy theme

**Total rooms**: 300+ locations  
**Room connections**: Doors, teleports (some one-way chains)

### Room Types
- Standard puzzle rooms
- Ladder climbing (Head must learn)
- Conveyor belt corridors
- Switch puzzles
- Monster avoidance (doughnut-freezing)
- Precision jumping (edge-hanging technique)

---

## Technical Specifications (ZX Spectrum)

### Display
- **Resolution**: 256x192 (Spectrum standard)
- **Isometric projection**: 2:1 dimetric (common for 8-bit isometric)
- **Color**: 8 colors × 2 brightness (Spectrum attribute clash)
- **Tile size**: ~16x16 or 16x8 pixels (isometric)

### Memory
- **48K/128K** compatible
- **128K**: Enhanced sound (AY-3-8912)
- Speedlock protection (custom loader)

### Performance
- **Frame rate**: 50Hz (PAL) / 60Hz (NTSC) - tied to interrupt
- **Game loop**: Fixed timestep per frame
- **Scrolling**: Screen-by-screen (room-based), no smooth scroll

---

## WebMSX Emulator Analysis

**URL**: https://www.file-hunter.com/Homebrew/?id=headoverheels  
**Emulator**: WebMSX (wmsx) v6.0.8  
**Format**: KonamiSCC Sound Mapper Cartridge  
**Video**: 60Hz native  
**Canvas**: 544x456 (id: `wmsx-screen-canvas`)

**Globals exposed**:
- `WMSX` / `wmsx` - Main emulator object
- `WMSXFullScreenSetup`
- Game loading from `games/HeadOverHeels.zip`

**Observed behavior**:
- Auto-loads KonamiSCC cartridge
- Title screen → attract mode → gameplay
- 60Hz output (smoother than Spectrum 50Hz)

---

## Asset Inventory Needed

### Sprites (per character)
- Head: idle, walk (8-dir), jump (arc frames), climb, fire, carry, combined
- Heels: idle, walk (8-dir), jump, run, carry, combined
- Combined: all merged animations

### Environment Tiles
- Isometric blocks (floor, wall, corner, edge)
- Ladders
- Springs
- Switches (on/off)
- Conveyor belts (animated)
- Teleports (animated)
- Doors (locked/unlocked)
- Hush puppies (sleeping/teleporting)

### Items
- Reincarnation fish (alive/dead)
- Rabbits (4 types)
- Doughnut trays (6-count)
- Bag
- Crowns (5)
- Iron pills

### UI
- Status display (bottom): lives, doughnuts, bag contents, power-up icons
- Character icons (Head/Heels lit state)
- Planet/crown progress screen
- Menus (main, keys, sound, sensitivity)

### Audio
- AY music (Guy Stevens) - 3 sound levels
- SFX: jump, land, teleport, switch, conveyor, doughnut fire, monster freeze, death, reincarnation

---

## Key Design Insights for Port

### 1. Isometric Movement
- 8-directional grid-based
- **Edge-hanging**: Can move slightly over brick edge before falling
- **Running jump**: Extra distance when moving + jumping
- **Head air control**: Can guide mid-jump

### 2. Character Asymmetry
- Core design pillar: Head and Heels have **complementary, non-overlapping** abilities
- Forces player to switch, separate, recombine
- Puzzles designed around this asymmetry

### 3. State Machine Complexity
Each character has:
- Separate position, velocity, animation state
- Inventory (bag for Heels, doughnuts for Head)
- Power-up timers
- Combined/separate mode
- Control ownership (who player controls)

### 4. Room-Based Architecture
- 300+ rooms, each self-contained puzzle
- Persistent state across rooms (collected items, eaten fish)
- Teleport network (some one-way)
- Door connections (bidirectional)

### 5. Difficulty Curve
- **Beginner path**: Escape Blacktooth → Freedom (minimum crowns)
- **Completionist**: Liberate all 4 slave planets + Blacktooth crown
- **Hints system**: In-game tips (15 hints in manual)

---

## Implementation Recommendations

### Rendering
- **Flame engine** (recommended): Built-in isometric support, game loop, components
- **CustomPainter alternative**: Full control, more boilerplate
- **Tile size**: 64x32 logical (scales to 128x64 @ 2x, 256x128 @ 4x)
- **Atlas**: Single sprite sheet per theme (castle, pyramid, jungle, etc.)

### Physics
- **Grid-based** with sub-tile interpolation for smooth movement
- **Jump arcs**: Parabolic, character-specific height/duration
- **No Box2D needed** - deterministic grid physics

### State Management
- **Riverpod**: Providers for GameState, CharacterState, RoomState, Inventory
- **Freezed**: Immutable data classes for all game entities
- **Serialization**: JSON for save/load, TMX for levels

### Input Abstraction
```dart
abstract class GameInput {
  Vector2 moveDirection;  // -1..1 for 8-dir
  bool jumpPressed;
  bool carryPressed;
  bool firePressed;
  bool swopPressed;
  bool pausePressed;
}
```
Implementations: TouchVirtualStick, Gamepad, Keyboard

### Level Format
- **Tiled (TMX)** for room layout + object layers
- **Custom JSON** for room connections, teleport network, global state
- **Procedural**: Room templates with variant parameters

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Touch controls feel wrong for isometric | High | High | Prototype virtual stick + context buttons early; test with real users |
| 300+ rooms = content scope creep | High | Medium | Data-driven; procedural templates; prioritize first 50 rooms |
| Character switching UX on mobile | Medium | High | Visual feedback (icons, glow); haptic on swop; auto-join assist |
| Performance (60fps, 300 rooms) | Low | High | Flame handles well; profile early; sprite atlases; object pooling |
| Asset creation (original copyrighted) | Certain | High | Create original art style inspired by, not copying; vector-based for scaling |
| Legal (Ocean/Atari trademark) | Medium | Low | Fan project, non-commercial; clear disclaimer; original IP |

---

## Next Steps (T002 - Architecture)

1. **Choose rendering**: Flame vs CustomPainter (prototype both)
2. **Define coordinate system**: Isometric grid → screen space math
3. **Design state machine**: Character states, combined mode, room transitions
4. **Select level format**: TMX + custom JSON for connections
5. **Prototype**: Single room with Head+Heels movement, swop, one puzzle element

---

## Appendix: TZX Analysis Notes

- **Format**: Speedlock protected (DJL Software)
- **Blocks**: 50+ blocks (loader, code, data, screens)
- **Bad CRCs**: Blocks 24, 46-57 (expected for Speedlock)
- **Loading screen**: Standard Spectrum loading screen
- **Code**: Z80 machine code, not directly usable for port
- **Use**: Reference for timing, memory map only

---

## Appendix: Map Analysis

Maps downloaded (4 files):
- `map1.jpg` (445KB) - Castle Blacktooth overview
- `map2.jpg` (569KB) - Extended castle/moonbase
- `map3.jpg` (471KB) - Slave planets
- `map4.png` (1.4MB) - Full world map with all connections

**Use for**: Level design reference, room connectivity, puzzle flow