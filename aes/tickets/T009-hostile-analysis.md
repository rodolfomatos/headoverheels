# T009 — Hostile Analysis: Bag System

## INSIGHTS CONSULTED
- SD-T001-research (original game mechanics: "bag may be used to carry small objects", "essential for Heels", "cannot drop in doorway")
- SD-T003-character-state (CharacterState has canCarry, carriedItem)
- SD-T008-ui (HUD shows bag icon, touch controls have carry button)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] Bag: Heels only, essential for progression, one item slot
- [KNOWN] Pickup: Stand on item + CARRY key → item in bag
- [KNOWN] Drop: Heels + CARRY key (no item in bag) → spawn item at position
- [KNOWN] Doorway restriction: "not possible to drop an object in a doorway"
- [KNOWN] Only Heels/Combined can carry (canCarry getter)
- [INFERRED] Bag is found early in game (castle start area)
- [INFERRED] Bag persists across room transitions (in CharacterState)
- [INFERRED] Items: keys, crowns, other small objects
- [ASSUMED] Doorway detection: check adjacent tiles for door triggers
- [ASSUMED] Item spawn: center of current tile when dropped
- [ASSUMED] Only one item can be carried at a time
- [UNKNOWN] Exact doorway detection algorithm (check 4 adjacent tiles?)
- [UNKNOWN] Whether bag entity persists after pickup or is removed
- [UNKNOWN] Item types beyond key/crown (food? tools? springs?)

## WHAT WASN'T SPECIFIED (that matters)
- Visual representation of bag on Heels character
- Whether bag can be dropped voluntarily vs only via action key
- Item stacking or multiple items (manual says "small objects" plural but "one item" mechanics)
- Item interaction with other entities (e.g., placing spring on conveyor)

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **Multiple item slots**: Rejected — original has single slot, simpler
- **Bag as world entity after pickup**: Rejected — bag becomes part of Heels ability
- **Automatic pickup**: Rejected — manual says "press CARRY key" to pickup
- **Drop anywhere**: Rejected — doorway restriction is explicit

## INVITE CONTRADICTION
- What if bag can hold multiple items (original manual: "small objects" plural)?
- What if doorway check uses entity collision instead of tile check?
- What if dropped items can be picked up again immediately?

## DISTINGUISH CLAIM TYPES
- **Empirical**: All mechanics from manual + WebMSX observation
- **Normative**: Doorway detection algorithm, item spawn position (tuning)

## RISKS & SIDE EFFECTS
- Doorway detection false positives/negatives
- Item spawn inside walls/entities
- Bag state persistence across room transitions
- Interaction with other systems (swop, combined form)

## COST OF BEING WRONG: HIGH
- Bag is "essential for Heels to get far" (manual)
- Core progression blocker if broken

## REASONING SKELETON FOR KEY CLAIMS
[Bag essential] → Manual: "impossible to get far without it" → progression gate
[Doorway restriction] → Manual: "not possible to drop an object in a doorway" → validation needed
[Heels only] → Manual: "only Heels may carry anything" → canCarry gate

## SCOPE BOUNDARIES DECLARATION
This analysis covers: BagEntity, CharacterState bag integration, pickup/drop logic, doorway validation, HUD update.
Deliberately excludes: Multiple items, item combining, complex inventory UI.