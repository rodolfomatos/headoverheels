# T004 — Hostile Analysis: Isometric Level Rendering Engine with TMX

## INSIGHTS CONSULTED
- SD-T002-architecture (Flame + flame_tiled, coordinate system, layer structure)
- SD-T003-character-state (CharacterState, position in grid coords)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] Flame's `flame_tiled` supports isometric maps (documented)
- [KNOWN] TMX format stores isometric maps with tilewidth/tileheight
- [INFERRED] Object layer parsing requires custom property handling for puzzle elements
- [ASSUMED] 16x16 tile rooms = 1024x512 logical pixels = manageable for mobile GPU
- [ASSUMED] Camera lerp factor 0.1 for smooth follow (standard platformer feel)
- [ASSUMED] Z-ordering: background(0) → floor(1) → objects(2) → characters(3) → effects(4)
- [UNKNOWN] Whether flame_tiled correctly handles isometric tile flipping/rotation
- [UNKNOWN] Performance of multiple IsometricTileMapComponents vs single large map

## WHAT WASN'T SPECIFIED (that matters)
- Exact TMX tileset format (single image vs collection of images)
- How to handle animated tiles (conveyor belts, teleport effects)
- Room streaming (load adjacent rooms vs all at once)
- Lighting/fog of war (original had none)

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **Custom TMX parser**: Rejected — flame_tiled is maintained, tested, handles edge cases
- **Single giant map for all rooms**: Rejected — memory, loading time; rooms are disconnected
- **Custom isometric renderer**: Rejected — Flame's IsometricTileMapComponent exists
- **3D rendering (Impeller)**: Rejected — overkill, no isometric helpers

## INVITE CONTRADICTION
- What if flame_tiled's isometric support is broken for 2:1 dimetric?
- What if object layer parsing doesn't preserve custom properties?
- What if camera smoothing causes motion sickness?

## DISTINGUISH CLAIM TYPES
- **Empirical**: flame_tiled supports isometric (package docs)
- **Normative**: Z-ordering scheme, camera lerp factor, room size

## RISKS & SIDE EFFECTS
- TMX parsing failures at runtime (malformed maps)
- Z-fighting between layers at tile boundaries
- Memory spikes when loading new rooms
- Coordinate system mismatch between TMX (top-left origin) and our grid (bottom-left)

## COST OF BEING WRONG: MEDIUM
- Rendering engine is core but can be iterated on
- If flame_tiled fails, fallback to custom parser (2-3 days)
- Wrong Z-ordering = visual bugs, not game-breaking

## REASONING SKELETON FOR KEY CLAIMS
[Flame_tiled for TMX] → Architecture decision T002 → flame_tiled is standard Flame package
[Z-ordering layers] → Isometric requires painter's algorithm → Background→Floor→Objects→Chars→Effects
[Camera lerp 0.1] → Standard platformer feel → Smooth but responsive

## SCOPE BOUNDARIES DECLARATION
This analysis covers: TMX loading, isometric rendering, camera, room transitions, object spawning.
Deliberately excludes: Puzzle behavior logic (T005), character animations, particle effects, audio.