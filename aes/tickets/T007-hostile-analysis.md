# T007 — Hostile Analysis: Final Puzzle Mechanics + InteractionSystem

## INSIGHTS CONSULTED
- SD-T001-research (original game mechanics for crown, bag, hush puppy, guardian)
- SD-T003-character-state (CharacterState: canCarry, canFire, doughnutCount, carriedItem)
- SD-T005/T006-puzzle-framework (PuzzleEntity base, SwitchEntity, MonsterEntity, EntityFactory)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] Crown: 5 total, one per planet (Egyptus, Penitentiary, Safari, Book World, Blacktooth)
- [KNOWN] Bag: Heels only, essential for progression, cannot drop in doorway
- [KNOWN] Hush Puppy: sleeps, teleports away when Head approaches
- [KNOWN] Guardian: blocks throne room, immune to doughnuts, defeated by 4 crowns
- [INFERRED] Crown collection: adds to GameState.collectedCrowns, triggers win check
- [INFERRED] Bag: single slot, CarriedItem type (key, crown, other), pickup on action key
- [INFERRED] Hush Puppy: detection radius ~3 tiles (Head only), teleports to random safe tile
- [INFERRED] Guardian: special monster subclass, overrides freeze(), checks crown count
- [ASSUMED] InteractionSystem: central collision dispatch, calls onEnter/onExit/onInteract
- [ASSUMED] RoomState: needs bagItem, crownCollected, hushPuppyState fields
- [ASSUMED] Test room: single TMX with one of each entity type
- [UNKNOWN] Exact Hush Puppy teleport algorithm (random safe tile vs fixed points)
- [UNKNOWN] Guardian defeat condition: "true hero" = all 4 crowns? all 5?
- [UNKNOWN] Bag item drop: can Heels drop item voluntarily? only in valid locations?

## WHAT WASN'T SPECIFIED (that matters)
- Bag item types beyond key/crown (food? tools?)
- Hush Puppy behavior when no safe tiles available
- Guardian visual distinction from regular monsters
- Crown visual effect on collection
- Whether bag persists across room transitions (yes, in CharacterState)

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **Bag as separate entity on ground**: Rejected — original has bag as pickup for Heels, not a world entity
- **Crown as room-trigger**: Rejected — crown is collectible item, not door trigger
- **Hush Puppy as physics body**: Rejected — instant teleport is simpler, matches original
- **Guardian as separate system**: Rejected — extends MonsterEntity with immunity override
- **InteractionSystem as event bus**: Rejected — direct collision callbacks are simpler

## INVITE CONTRADICTION
- What if bag can hold multiple items (original: "small objects" plural)?
- What if Guardian requires all 5 crowns, not 4?
- What if Hush Puppy teleports to fixed points rather than random?

## DISTINGUISH CLAIM TYPES
- **Empirical**: All mechanics from manual + WebMSX observation
- **Normative**: Detection radius, teleport algorithm, crown count for guardian (tuning)

## RISKS & SIDE EFFECTS
- Bag + doorway: must validate drop location (check adjacent tiles for doorway)
- Guardian immunity: must override freeze() in doughnut collision path
- Hush Puppy: must find safe tile (not wall, not conveyor, not hazard)
- Crown collection: must sync with GameState for win condition

## COST OF BEING WRONG: HIGH
- These are the final core mechanics
- Win condition depends on crown system
- Bag is "essential for Heels to get far" (manual)

## REASONING SKELETON FOR KEY CLAIMS
[Crown win] → Manual: "Find a crown and start a revolution... 5 crowns total" → 5 crowns = win
[Bag essential] → Manual: "impossible to get far without it" → Heels cannot progress without bag
[Hush Puppy teleport] → Manual: "teleport themselves away" → instant position change
[Guardian immune] → Manual: "doesn't like doughnuts... only true hero may pass" → doughnut immunity + crown check

## SCOPE BOUNDARIES DECLARATION
This analysis covers: Crown, Bag, HushPuppy, Guardian, InteractionSystem, test room TMX.
Deliberately excludes: Animations, audio, UI/HUD, level design, save/load persistence.