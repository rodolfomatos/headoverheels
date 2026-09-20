# T011 — Hostile Analysis: Test Room TMX

## INSIGHTS CONSULTED
- SD-T004-room-system (RoomComponent, EntityFactory, TMX loading)
- SD-T005/T006/T007-entities (all entity types implemented)
- SD-T001-research (original game map layout)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] Flame_tiled supports isometric TMX with 64x32 tiles
- [KNOWN] TMX object layer properties map to entity factory
- [KNOWN] Tiled editor can create isometric maps
- [INFERRED] Need castle.tsx tileset with proper tile IDs
- [ASSUMED] Test room 16x16 tiles (1024x512 logical)
- [ASSUMED] Spawn points at (1,1) for Head, (2,2) for Heels
- [UNKNOWN] Exact tile IDs for castle theme
- [UNKNOWN] TMX property format for custom entity properties

## WHAT WASN'T SPECIFIED (that matters)
- Exact tile IDs for castle.tsx
- Whether to use Tiled editor or manual XML
- How to handle multi-layer TMX in flame_tiled
- TMX version compatibility

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **Manual TMX XML**: Rejected — Tiled editor easier, less error-prone
- **Procedural generation**: Rejected — need visual layout for testing
- **Multiple test rooms**: Rejected — single comprehensive room first

## INVITE CONTRADICTION
- What if flame_tiled doesn't support custom properties?
- What if tile IDs don't match entity factory expectations?

## DISTINGUISH CLAIM TYPES
- **Empirical**: flame_tiled docs, TMX format spec
- **Normative**: Room size, entity placement, test coverage (design)

## RISKS & SIDE EFFECTS
- TMX parsing failures at runtime
- Entity spawn position offsets
- Missing tileset references

## COST OF BEING WRONG: MEDIUM
- Test room is for development only
- Can iterate quickly with Tiled editor

## SCOPE BOUNDARIES DECLARATION
This analysis covers: Single test room TMX with all entity types, tileset reference, world.json entry.
Deliberately excludes: Multiple rooms, full campaign levels, complex puzzle layouts.