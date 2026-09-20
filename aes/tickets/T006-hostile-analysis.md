# T006 — Hostile Analysis: Remaining Puzzle Mechanics

## INSIGHTS CONSULTED
- SD-T001-research (original game mechanics for all elements)
- SD-T005-puzzle-framework (PuzzleEntity base, SwitchEntity, ConveyorEntity, EntityFactory)
- SD-T003-character-state (CharacterState, canCarry, canFire, doughnutCount)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] Spring: 1.5x jump height boost (from manual "extra height")
- [KNOWN] Fish: alive = checkpoint, dead = poison (from manual)
- [KNOWN] Doughnut: Head only, 6 max, freezes monsters 3s (180 frames)
- [KNOWN] Bag: Heels only, one item, not in doorway
- [KNOWN] Crown: 5 total, win condition
- [KNOWN] Hush puppy: teleports away when Head approaches
- [KNOWN] Monster: patrols, touch = death, freezable by doughnut
- [KNOWN] Guardian: immune to doughnut, blocks throne room
- [INFERRED] Doughnut projectile: homing, seeks nearest monster
- [INFERRED] Monster patrol: simple back-and-forth on platform
- [ASSUMED] Doughnut freeze duration: 180 frames (3s @ 60Hz)
- [ASSUMED] Spring boost: 1.5x jump velocity multiplier
- [ASSUMED] Hush puppy detection radius: 3 tiles
- [ASSUMED] Monster patrol: waypoints from TMX object properties
- [UNKNOWN] Exact doughnut homing algorithm (linear? curved?)
- [UNKNOWN] Monster respawn behavior (room re-enter? time?)
- [UNKNOWN] Hush puppy teleport destination (random safe spot?)

## WHAT WASN'T SPECIFIED (that matters)
- Doughnut aiming: auto-target nearest vs manual aim
- Fish respawn: permanent dead vs room re-enter reset
- Monster AI complexity: simple patrol vs chase
- Hush puppy visual state (sleeping vs awake)
- Crown distribution per planet

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **Manual doughnut aiming**: Rejected — original was auto-target; touch unfriendly
- **Complex monster AI (A*)**: Rejected — original had simple patrol; overkill
- **Fish as physics object**: Rejected — static checkpoint is simpler
- **Hush puppy as physics body**: Rejected — instant teleport is simpler
- **Guardian as regular monster + flag**: Rejected — special behavior warrants own class

## INVITE CONTRADICTION
- What if doughnut freeze was permanent until room re-enter?
- What if monster patrol used waypoints from TMX path nodes?
- What if hush puppy teleport had cooldown?

## DISTINGUISH CLAIM TYPES
- **Empirical**: All mechanics from manual + WebMSX observation
- **Normative**: Freeze duration, spring multiplier, detection radius (tuning)

## RISKS & SIDE EFFECTS
- Doughnut homing + monster movement = complex collision
- Fish state persistence = must survive room unload/load
- Monster freeze = patrol state must pause/resume correctly
- Bag + doorway = "not possible to drop in doorway" validation
- Guardian immunity = special case in doughnut collision

## COST OF BEING WRONG: HIGH
- These ARE the core puzzle mechanics
- Wrong feel = game unplayable
- Must playtest extensively

## REASONING SKELETON FOR KEY CLAIMS
[Spring 1.5x] → Manual: "extra height" → multiplier on jump velocity
[Fish checkpoint] → Manual: "reincarnated at the very place you ate the fish" → save position
[Doughnut 6 max] → Manual: "tray of six doughnuts" → counter 0-6
[Bag one item] → Manual: "impossible to get far without it" → single slot

## SCOPE BOUNDARIES DECLARATION
This analysis covers: Spring, Fish, Doughnut, Bag, Crown, HushPuppy, Monster, Guardian, InteractionSystem.
Deliberately excludes: Complex AI, particle effects, audio, UI, save/load, level design.