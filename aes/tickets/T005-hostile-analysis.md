# T005 — Hostile Analysis: Puzzle Mechanics

## INSIGHTS CONSULTED
- SD-T001-research (original game mechanics: switches, conveyors, fish, doughnuts, etc.)
- SD-T003-character-state (CharacterState, abilities, canCarry, canFire)
- SD-T004-room-system (RoomComponent, TriggerZone, EntityFactory, RoomState)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] Switch toggles target on/off; monster off = still deadly (from manual)
- [KNOWN] Conveyor pushes character; jump to move opposite (from manual)
- [KNOWN] Spring gives extra jump height (from manual)
- [KNOWN] Fish alive = checkpoint, dead = poison (from manual)
- [KNOWN] Doughnut: Head only, 6 per tray, freezes monsters (from manual)
- [KNOWN] Bag: Heels only, one item, not in doorway (from manual)
- [KNOWN] Crown: 5 total, one per planet (from manual)
- [KNOWN] Hush puppy: teleports away when Head approaches (from manual)
- [INFERRED] Monster: basic patrol, touch = death, freezable by doughnut
- [INFERRED] Guardian: immune to doughnut, blocks throne room
- [ASSUMED] Switch activation: character stands on + press action key
- [ASSUMED] Conveyor speed: 2 tiles/sec (half walk speed)
- [ASSUMED] Doughnut freeze duration: 3 seconds (180 frames)
- [ASSUMED] Spring boost: 1.5x jump height
- [ASSUMED] Fish respawn: dead fish stays dead permanently in that room
- [ASSUMED] Monster patrol: simple back-and-forth on platform
- [UNKNOWN] Exact monster movement patterns from original
- [UNKNOWN] Whether multiple switches can control same target
- [UNKNOWN] Conveyor belt visual animation frames

## WHAT WASN'T SPECIFIED (that matters)
- Exact conveyor belt tile width (1 tile? multiple?)
- Whether springs can be carried and placed (manual implies yes for Heels)
- How hush puppy "teleport away" works visually
- Monster respawn behavior (after leaving room? after time?)
- Whether doughnuts can be aimed or auto-target
- Switch visual states (pressed/unpressed)

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **Full monster AI with pathfinding**: Rejected — original had simple patrol; overkill
- **Physics-based conveyor (Box2D)**: Rejected — grid-based is simpler, deterministic
- **Doughnut aiming mechanic**: Rejected — original was auto-target nearest; simpler for touch
- **Fish as physics object**: Rejected — static checkpoint is simpler
- **Switch as pressure plate (auto)**: Rejected — manual says "push the switch" = action key

## INVITE CONTRADICTION
- What if original conveyor speed matched walk speed (not half)?
- What if doughnut freeze was permanent until room re-enter?
- What if monster patrol used waypoints from TMX?

## DISTINGUISH CLAIM TYPES
- **Empirical**: All mechanics from manual + WebMSX observation
- **Normative**: Freeze duration, conveyor speed, spring multiplier (tuning params)

## RISKS & SIDE EFFECTS
- Conveyor + jump + edge-hang = complex collision resolution
- Switch + door timing: door open/close animation vs instant
- Doughnut + monster: freeze state sync with monster patrol
- Fish state persistence: must survive room unload/load
- Bag + doorway: "not possible to drop in doorway" = validation needed

## COST OF BEING WRONG: HIGH
- Puzzle mechanics ARE the gameplay
- Wrong feel = game unplayable
- Must playtest extensively

## REASONING SKELETON FOR KEY CLAIMS
[Switch toggles target] → Manual: "Simply push the switch to switch things off and on!" → Boolean state per target
[Conveyor pushes] → Manual: "rollers simply push you along it" → Constant velocity applied
[Fish checkpoint] → Manual: "eat one... reincarnated at the very place you ate the fish" → Save position on eat

## SCOPE BOUNDARIES DECLARATION
This analysis covers: Switch, conveyor, spring, fish, doughnut, bag, crown, hush puppy, monster, guardian.
Deliberately excludes: Complex AI, particle effects, audio, UI, save/load, level design.