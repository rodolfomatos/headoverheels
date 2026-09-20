# T003 — Hostile Analysis: Character Controllers & Physics

## INSIGHTS CONSULTED
- SD-T001-research (original game mechanics, character abilities)
- SD-T002-architecture (coordinate system, state management, Flame integration)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] Head jumps 2× own height (2 tiles), Heels jumps 1× (1 tile) — from original instructions
- [KNOWN] Heels runs 2× faster than Head (4 vs 2 tiles/sec) — from original instructions
- [KNOWN] Combined form uses Head's jump + Heels' speed intermediate (3 tiles/sec, 2 tiles jump) — inferred from combined abilities
- [INFERRED] Jump duration: Head 30 frames (0.5s), Heels 20 frames (0.33s) — extrapolated from 60Hz frame rate and tile heights
- [INFERRED] Edge-hang threshold 30% of tile width — from Hint #7 "how far Head and Heels may move over the edge of a brick before they fall"
- [INFERRED] Running jump bonus: extra distance when moving + jumping — from Hint #7 "Both Head and Heels will jump slightly further if they are running as they jump"
- [ASSUMED] Head air control 0.5, Heels 0.2 — Head has "rudimentary wings that allow Head to guide himself through the air"
- [ASSUMED] Ladder climbing: Head only, Heels cannot climb — from Hint #4 "Make sure Head learns to climb ladders, this is an essential skill"
- [ASSUMED] Sub-tile interpolation for smooth rendering at 60fps while physics runs at fixed 60Hz — standard game dev practice
- [UNKNOWN] Exact pixel-perfect jump arc formula from original Z80 code — cannot extract due to Speedlock protection

## WHAT WASN'T SPECIFIED (that matters)
- Exact jump arc equation (parabolic vs custom curve)
- Collision resolution when hitting walls mid-jump
- Whether jump height is variable (hold jump = higher) or fixed
- Coyote time / jump buffering for touch controls
- How swop works mid-air (can you swop while jumping?)
- Whether combined form has different collision bounds

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **Box2D/Flame Forge2D**: Rejected — overkill for grid-based isometric movement; adds complexity, non-deterministic
- **Pixel-perfect collision**: Rejected — original game was tile-based; sub-tile is for visual smoothness only
- **Variable jump height (hold to jump higher)**: Rejected — original had fixed jump arcs; adds complexity for touch
- **Separate physics per character class**: Rejected — DRY violation; use single physics with character-type parameters

## INVITE CONTRADICTION
- What if the original jump wasn't parabolic but used a lookup table?
- What if edge-hang is exactly 50% not 30%?
- What if combined form speed is Heels' speed (not intermediate)?
- What would disprove my reasoning? Finding original Z80 disassembly or RZX playback analysis

## DISTINGUISH CLAIM TYPES
- **Empirical**: Jump heights, walk speeds, frame durations (from manual + WebMSX observation)
- **Normative**: Air control values, edge-hang threshold, coyote time (design decisions for feel)

## RISKS & SIDE EFFECTS
- Touch virtual stick for 8-directional isometric is notoriously difficult
- Jump physics must feel "right" — wrong values make game unplayable
- State sync between Riverpod (authoritative) and Flame (render) could desync
- Swop mid-air edge cases (what if swop puts character in wall?)

## COST OF BEING WRONG: HIGH
- Core gameplay feel depends entirely on this
- If wrong, entire game feels broken; requires complete rework
- Must get user validation before proceeding to T004/T005

## REASONING SKELETON FOR KEY CLAIMS
[Head jumps 2× Heels] → Manual: "Head up to twice his own height" + "Heels can jump his own height" → Head jump = 2 tiles, Heels = 1 tile
[Heels runs 2× Head] → Manual: "Heels can also run very fast" + default controls show Heels faster → 4 vs 2 tiles/sec
[Edge-hang 30%] → Hint #7: "how far Head and Heels may move over the edge of a brick before they fall" → design decision for forgiving feel

## SCOPE BOUNDARIES DECLARATION
This analysis covers: Character state machine, movement physics, jump arcs, input abstraction, swop logic.
Deliberately excludes: Puzzle element interactions (T005), room transitions, sprite animations, audio, save/load, UI.