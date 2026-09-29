---
project: headoverheels
created: 2026-09-18
current_sprint: sprint-11
current_ticket: "T050"
---

# Kanban — headoverheels

## Backlog
| ID | Title | Priority | Status |
|----|-------|----------|--------|
| T001 | Research original game mechanics & online MSX version | high | done |
| T002 | Define core game architecture (isometric rendering, state machine) | high | done |
| T003 | Implement Head/Heels character controllers & physics | high | done |
| T004 | Build isometric level rendering engine | high | done |
| T005 | Implement puzzle mechanics (switches, conveyors, doughnuts) | high | done |
| T006 | Implement remaining puzzle mechanics (spring, fish, doughnut, bag, crown, hush puppy, monster, guardian) | high | done |
| T007 | Implement final puzzle mechanics (crown, bag, hush puppy, guardian) + InteractionSystem | high | done |
| T008 | Create modern UI/UX: menus, HUD, touch controls | high | done |
| T009 | Implement Bag system (Heels carry items) | high | done |
| T010 | Connect CharacterState notifier to CharacterComponent | high | done |
| T011 | Create test room TMX with all entity types | high | done |
| T012 | Port original level data / design new levels | medium | done |
| T013 | Audio: SFX, music, adaptive audio system | medium | done |
| T014 | Polish: animations, transitions, accessibility | low | done |
| T015 | Release build & Play Store preparation | low | done |
| T016 | Asset & Visual System Audit | high | done |
| T017 | Visual Design System | high | done |
| T018 | Character Masters | high | done |
| T019 | Character Animation Pipeline | high | done |
| T020 | Environment Masters | high | done |
| T021 | Castle Tileset | high | done |
| T022 | Entity Masters | high | done |
| T023 | Remaining Themes | medium | done |
| T024 | Validation Pipeline | medium | done |
| T025 | Atlas Pipeline | medium | not needed |
| T026 | Flutter Sprite Registry | medium | split |
| T027 | Gameplay Integration | medium | compiles now |
| T028 | Visual QA: the renderer has never been drawn | high | in progress |
| T029 | Final Asset Migration | low | done |
| T030 | Builder architecture & reusable iso_core foundation | high | done |
| T031 | Editor document, storage, undo/redo & sprite import foundation | high | done |
| T032 | Builder CLI scaffold and project validation | medium | done |
| T033 | Visual isometric map editor | high | done |
| T034 | Sprite browser/animator and asset management UI | high | done |
| T035 | Migrate Head over Heels into games/headoverheels | high | done |
| T036 | TSX authoring: edit tile types/properties and export TSX | medium | done |
| T037 | World graph viewer/editor with topology validation | high | done |
| T038 | Second example game (Knight Lore) on iso_core | medium | done |
| T039 | Puzzle trigger inspector (switch/target links) in the graph tab | medium | done |

## Sprint 01 — Foundation & Research
**Goal**: Understand original game, establish core architecture, prove isometric rendering

| ID | Title | Status |
|----|-------|--------|
| T001 | Research original game mechanics & online MSX version | done |
| T002 | Define core game architecture (isometric rendering, state machine) | done |

## Sprint 02 — Core Gameplay Implementation
**Goal**: Implement Head/Heels character controllers, physics, and basic room rendering with TMX loading

| ID | Title | Status |
|----|-------|--------|
| T003 | Implement Head/Heels character controllers & physics | done |
| T004 | Build isometric level rendering engine with TMX | done |
| T005 | Implement puzzle mechanics (switches, conveyors, doughnuts) | done |

## Sprint 03 — Remaining Puzzle Mechanics
**Goal**: Implement spring, fish, doughnut firing, bag, crown, hush puppy, monster, guardian

| ID | Title | Status |
|----|-------|--------|
| T006 | Implement remaining puzzle mechanics | done |

## Sprint 04 — Final Puzzle Mechanics + InteractionSystem
**Goal**: Crown, bag, hush puppy, guardian, InteractionSystem, test room

| ID | Title | Status |
|----|-------|--------|
| T007 | Implement final puzzle mechanics + InteractionSystem | done |

## Sprint 05 — UI/UX, Touch Controls & Polish
**Goal**: Modern UI/UX, touch controls, HUD, menus, accessibility

| ID | Title | Status |
|----|-------|--------|
| T008 | Create modern UI/UX: menus, HUD, touch controls | done |
| T009 | Implement Bag system (Heels carry items) | done |
| T010 | Connect CharacterState notifier to CharacterComponent | done |
| T011 | Create test room TMX with all entity types | done |

## Sprint 06 — Level Data & Polish
**Goal**: Port original level data, implement audio, polish animations

| ID | Title | Status |
|----|-------|--------|
| T012 | Port original level data / design new levels | done |
| T013 | Audio: SFX, music, adaptive audio system | done |
| T014 | Polish: animations, transitions, accessibility | done |
| T015 | Release build & Play Store preparation | done |

## Sprint 07 — Release
**Goal**: Final polish and Play Store release

| ID | Title | Status |
|----|-------|--------|
| T015 | Release build & Play Store preparation | done |

## Sprint 08 — Asset Production
**Goal**: Complete all visual assets (tilesets, entities, characters)

| ID | Title | Status |
|----|-------|--------|
| T016 | Asset & Visual System Audit | done |
| T017 | Visual Design System | done |
| T018 | Character Masters | done |
| T019 | Character Animation Pipeline | done |
| T020 | Environment Masters | done |
| T021 | Castle Tileset | done |
| T022 | Entity Masters | done |
| T023 | Remaining Themes | done |
| T024 | Validation Pipeline | done |

## Sprint 09 — Integration & Release
**Goal**: Integration, QA, Release

| ID | Title | Status |
|----|-------|--------|
| T025 | Atlas Pipeline | not needed |
| T026 | Flutter Sprite Registry | split |
| T027 | Gameplay Integration | compiles now |
| T028 | Visual QA | pending |
| T029 | Final Asset Migration | done |
| T053 | The sprite registry should read the manifest, not repeat it | done |
| T055 | Show the game on the game screen: it is a placeholder | done |
| T056 | The bag is carried but does nothing yet | done |
| T057 | The guardian trigger does not say which planet it guards | done |
| T058 | Four of the five planets have no tileset | done |
| T059 | The pixel-level visual proof of the HoH renderer | half done: the load, not the draw |
| T061 | Nowhere to empty the bag: the world has no dispensary | done |
| T063 | The manifest promised frames the art did not have | done, characters still one pose |
| T064 | The menu calls the game a remaster for Android | done |
| T065 | The first frame waits a minute for the whole sprite registry | done |
| T066 | Entities draw coloured rectangles, not the sprites the registry loaded | done |
| T062 | The game screen is black: the first frame waits for 65 sprites | answered: the room draws |

## Sprint 10 — Builder Platform
**Goal**: Extract a reusable isometric engine and build editor/CLI foundations

| ID | Title | Status |
|----|-------|--------|
| T030 | Builder architecture & reusable iso_core foundation | done |
| T031 | Editor document, storage, undo/redo & sprite import foundation | done |
| T032 | Builder CLI scaffold and project validation | done |
| T033 | Visual isometric map editor | done |
| T034 | Sprite browser/animator and asset management UI | done |
| T035 | Migrate Head over Heels into games/headoverheels | done |
| T049 | Replace the untracked HoH audio with synthesised cues | done |
| T051 | Publish nested assets: a pubspec entry ships only its own files | done |
| T050 | Clear the analyzer warnings in the HoH code | done |
| T052 | The Palette panel squeezes its controls out of reach | done |
| T067 | Knight Lore sat on "Loading the castle" with no reason | done |
| T068 | The editor could not be run: no entry point, no icon font | done |
| T069 | The editor had no project to open | done |
| T070 | A tap missed its cell once the grid had been dragged | done |
| T071 | The assets could only be seen in a directory listing | done |
| T072 | Knight Lore's scrolls and ingredients are not drawn | done |
| T073 | Three of the six scrolls are in no chest anywhere | done |
| T074 | Knight Lore's web build never reaches a rendered room | open |

## Sprint 11 — Knight Lore Completion
**Goal**: turn the second example game into a finished product, then migrate the
first game onto the same platform

| ID | Title | Status |
|----|-------|--------|
| T040 | Spell scrolls: find, carry and cast the six spells | done |
| T041 | Treasures, chests and the six ingredients, with win state | done |
| T042 | Traps and hazards: impalers, ball chains, blocks, demons | done |
| T043 | Screens: title, status scroll, pause, victory, defeat | done |
| T044 | Procedural audio: effects and one ambient loop | done |
| T045 | Visual polish: shadows, room transitions, ambience, sundial | done |
| T046 | Editor reads both games: world and sprite manifest | done |
| T047 | Visual proof: render the game to images and inspect them | done |
| T048 | Balance pass: days, spell decay, treasure placement | done |
| T036 | TSX authoring: edit tile types/properties and export TSX | done |

## In Progress
* T028: Visual QA. The screen now shows the game (T055) and the renderer draws a
  real room, but the proof still has to be made into a test that ends: see T059.

## Queued
* T054: Gameplay tests: the rules are barely covered
* T058: Four of the five planets have no tileset
* T059: The pixel-level visual proof of the HoH renderer
* T061: Nowhere to empty the bag: the world has no dispensary
* T062: The game screen is black: the room never finishes loading
* T063: The manifest promises 4 and 8 frames; the art has one pose
* T065: The first frame waits a minute for the whole sprite registry
* T066: Entities draw coloured rectangles, not the sprites the registry loaded


## Notes
* T028, first finding, and the most serious thing found in this project. Ten
  `// ignore: undefined_identifier` comments sat over `gameRef`, a name that does
  not exist anywhere. The analyzer was clean because those comments silenced it,
  `flutter test` could not compile the layer, and the web build passed because
  nothing reachable imported it. The gameplay code has never compiled.
  The game screen makes it plain: `_buildGameCanvas` returns a container with the
  text "Game Canvas (Flame GameWidget goes here)", and `gameProvider` is declared
  and never read, so the game object is never even constructed. The game as it
  stands cannot be played, and no test noticed because none of them imported the
  gameplay layer.
  What is fixed here: the ten silences are gone, the entities reach the game
  through a typed `HasGameReference<HeadOverHeelsGame>` and ask it for
  `currentRoom` instead of hunting the component tree, and the game implements the
  four interfaces the entities notify (`BagCollector`, `CrownCollector`,
  `ItemPicker`, `GuardianDefeatedNotifier`) and forwards them to the character
  state that already exists. `PuzzleEntity` gained the `onSwitchToggled` hook a
  switch target needs, `collection` became a direct dependency because the
  entities import it, and `test/gameplay_compiles_test.dart` exists mostly to
  import the layer so a compiler error can never hide behind an ignore comment
  again. Seven tests, the analyzer clean.
  What is not: the screen still shows a placeholder, which is T055 and the
  prerequisite for the visual proof this ticket is really after. The bag is
  recorded and does nothing, T056. The guardian counts every crown because its
  trigger does not say which planet it guards, T057.
* T055, the screen, and the three real bugs only a real load could find. The
  screen watched nothing, built no game and printed "Game Canvas (Flame
  GameWidget goes here)". `gameProvider` was declared and never read, and it
  threw whenever the world had not arrived, so the game object was never
  constructed. The screen now watches `worldGraphProvider`, shows a loader, an
  error, and a `GameWidget<HeadOverHeelsGame>`; the game is built once and
  disposed on the way out; the game reads the same `InputSystem` the touch
  controls write to, so the joystick now reaches the party. Five tests in
  `test/game_screen_test.dart`, and they stand the real screen up: real world,
  real room map, real tileset, real sprites.
  Those five tests found three defects that no amount of reading would have:
  `TiledComponent.load` prefixes `assets/tiles/` by default, so every room
  resolved to `assets/tiles/assets/levels/rooms/...`, a path that has never
  existed; the loader resolves a tileset image under `assets/images/`, and
  `castle.png` sat next to its TSX in `assets/levels/tilesets/`, where nothing
  looks; and the screen read a provider inside `dispose()`, which Riverpod
  forbids. The tileset image now lives in `assets/images/`, the maps name their
  tileset from the bundle root, and the generator writes paths that resolve and
  says so when a tileset is missing.
  What is not: the renderer is still not proven by a test that ends, T059, and
  only one of the five planets has a tileset, T058.
* The audio of both games, found while chasing T059 and worth more than the
  chase. FlameAudio prefixes `assets/audio/` itself, and both games handed it a
  path that already began with it: Head over Heels asked for
  `assets/audio/audio/sfx/jump.wav` and Knight Lore for
  `assets/audio/assets/audio/step.wav`. Neither file has ever existed, so both
  games play silence, in the browser, with no error: FlameAudio reports a
  missing asset and carries on. The HoH screen test printed the failure while
  loading, and nothing had noticed, because every audio test checked the other
  half of the problem: that the WAVs exist, that they decode, that they are
  audible, that the cue list is complete. Not one of them asked for the path the
  loader is given. Each game now has that test, and the two old assertions that
  encoded the doubled prefix as a requirement are corrected.
* T057, the crown economy, which was wrong in three places at once. A throne
  room opens for the crowns of its own planet, and none of the three parts
  agreed on that. The world's guardian triggers carried no `planetId`, so
  `GuardianEntity` counted every crown the party had ever collected: four crowns
  from one planet opened all five, and the four a throne room actually asked
  for were never the ones being checked. The game had both a per-planet count
  and a global one, and the guardian read the global one. The HUD had no count
  at all: `const int crownsCollected = 2` of `const int totalCrowns = 5`, a
  number written into a widget that never moved, over a total the game does not
  use. A player picking up their fourth crown was still told `2/5`.
  The seven guardian triggers now carry the `planetId` of the room they sit in,
  the factory refuses to build a guardian that does not say which throne room it
  guards, the guardian asks `crownsFor(planetId)`, the global total is gone, and
  one notifier, `crownsProvider`, is the truth the guardian and the HUD both
  read. Five tests: two on the data, because a trigger that loses its `planetId`
  in an edit is this bug coming back, and three on the rule: the wrong planet
  does not open a throne room, the right one does, and three crowns do not.
* T056, the bag, which was carried and did nothing, and was worse than nothing.
  It was recorded as the character's hand item: `CarriedItem.other('bag')`. The
  hand carries one thing, so picking the bag up filled the only slot a character
  has with a bag nobody can use, and the key on the floor could no longer be
  picked up. The bag is worn. It is now `hasBag`, the hand is left alone, and
  the bag has four slots of its own: an item goes in the hand when the hand is
  free and in the bag when it is not. Four tests, including that the fifth item
  stays on the floor.
  What the bag cannot do yet is be emptied. The world has ten bag triggers, no
  dispensary and no swop: there is no trigger type in the whole world file for
  either, so a bag that fills stays full. That is T061, and it is level design
  rather than a bug, so it is named rather than guessed at.
* The crown bug behind T057, found while working on the bag and worth more than
  the bag. The crown factory read `trigger.properties['planet']`, a key no
  trigger in the world has, and fell back to `castle`. Every crown in the game
  was Blacktooth's: the four that opened a throne room opened the castle one,
  and no other planet could ever be finished, however many crowns the player
  carried. The data was right and the rule was right, and the code that read
  them was wrong, which is what a578399 said it had fixed and had not. The
  factory reads `planetId` now, refuses to guess, and a test builds every crown
  in the world out of the real data and checks which planet it belongs to. That
  test is the one that was missing: nothing had ever built an entity out of the
  real world and looked at it.
* T028, and it found two things, one of them the reason the game is black.
  The room maps had a floor of nothing: every tile was gid 0, which Tiled reads
  as no tile at all, so twenty rooms drew nothing but their border. And the
  border used gid 2, which is tile id 1, and tile id 1 is a cracked *floor* in
  `scripts/generate_castle_tileset.py`: the walls were floor. The generator
  writes the ids the tileset actually has now, floors on the floor and walls on
  the walls, with a worn path across the room and moss along its edges so twenty
  rooms are not twenty copies of one grid, and all twenty maps are regenerated.
  `test/room_maps_test.dart` reads the numbers in the files and would fail on
  either: no floor, no border, a walled-in room, a gid past the end of the
  tileset, or walls lined with floor tiles.
  The second thing is worse. A rendered frame of the real screen is black: the
  joystick, the buttons and the HUD are there, and the room is not. The frame
  measured 1465 distinct colours, and every one of them came from the widgets
  around the game. `HeadOverHeelsGame.onLoad` never finishes: pumping 900 frames
  gets as far as `await add(room)` and stops there, `isLoaded` stays false, and
  `currentRoom` is null. Nothing had noticed, because the game-screen tests
  assert that a `GameWidget` exists, and the screen builds one as soon as the
  world arrives whether or not the game has loaded. A test that stands the real
  screen up and checks that a *room* came up, rather than a widget, is what was
  missing. That is T062, and T028 is not closed until it is.
  What the capture needed to work at all: pumping until `isLoaded`, not a fixed
  number of frames. The world, the room map, the tileset and 65 sprite sheets
  load through awaits that only resolve when the test pumps, so a fixed count
  catches the game half-loaded.
  T062, the black screen, tracked down by rendering the screen and looking at
  the frame. Three faults stood between the world and a picture.
  `_parsePatrolPoints` cast `properties['patrolPoints']` to a `String`, and
  every patrol point in the world is a list, `[[10, 5, 0], [15, 5, 0]]`. The
  cast threw for the first monster in the first room, the room's load never
  finished, and the screen stayed black. Monsters and guardians patrolled nothing
  because of it, silently: an empty patrol list is a monster that stands still.
  The parser reads the list the world actually has, and still the string the
  editor writes.
  The sprite registry rebuilt the manifest in Dart and got it wrong three ways.
  It loaded through Flame's shared `Flame.images`, which prefixes
  `assets/images/`, so every frame asked for
  `assets/images/assets/sprites/...`: a file that has never existed. It named
  frames with the direction in the name, `head_idle_n_01.png`, where the art says
  `front`, `3q`, `side` and `back`. And the frame loop ended on the first
  failure with a `catch`, so a wrong path and the end of an animation looked the
  same: the animations came out empty, and the party had nothing to draw. Three
  of the four other loaders were `TODO`, so entities, props, tiles, UI and
  effects were never loaded at all. T053 is the fix: the registry reads
  `assets/sprites/manifest.yaml` through `iso_core`'s `AssetManifest`, the same
  manifest the editor reads, loads the file each entry names, and says so loudly
  when a file the manifest promises is not there. All 65 entries load.
  What is still not proven, and T028 stays open for it: no test in the suite
  draws a frame of this game. A widget test cannot finish the game's load, because
  the world, the map, the tileset and 65 sheets load through awaits that resolve
  only when the test pumps, and the pumping cannot happen inside the `runAsync`
  the asset decoding needs; a plain test has a real event loop but no audio
  plugin, and the game starts the planet's music while it loads. Both were tried
  and both are recorded here rather than left as folklore. So the check was done
  in a browser, on the web build, with the console read.
  In the browser the menu draws, and it is the game's own menu: `lib/main.dart`
  was still the Flutter counter demo, so the web build everybody had been
  calling green was a build of a demo. The game's menu was unreachable and the
  two routes it pushes to, `/game` and `/settings`, were not declared anywhere.
  The entry point now starts the menu, declares both routes, and answers
  `/settings` with a screen over the settings the game reads. Three tests stand
  for it, including that the app does not start on a counter any more.
  With that fixed, the browser reached the game screen. The HUD is right: three
  lives, `0/4` crowns, the party on Head, the joystick and four buttons. The
  room is still black, and the console says why: the room loads, all fifteen of
  its entities, and then the load stops in the characters, where the sprite
  registry is loading every one of the 65 sprites in the manifest, one at a
  time, before the first frame. `GameWidget` draws nothing until the game's load
  is finished, so a black room is the honest picture of a game that is still
  arriving. It is not stuck: 9 sprites in 12 seconds, which is a minute for the
  set. The room's own floor could be on screen the whole time.
  Then it was measured properly, in a browser, with the sprite requests counted
  and the screenshots looked at. The room draws: the isometric floor, its grid,
  the room's entities. So the black screen was never a camera and never a missing
  tile; it was a game that had not finished arriving, and `GameWidget` draws
  nothing until it has. The count says 63 distinct sprite files, which is all of
  them: the manifest has 65 entries and names the tileset image twice. Nothing is
  missing and nothing hangs. What a player gets is about a minute of black screen
  because the first frame waits for every sprite in the game, which is T065, and
  the entities that are on that floor are still the coloured rectangles their
  `onLoad` draws rather than the sprites the registry has been loading all this
  time, which is T066.
  T065, and the numbers behind it. The 63 sprite files are 316 KB and the server
  hands them over in 0.72 seconds, so the minute was never the network: it is the
  browser decoding 65 images one at a time, and in a headless software renderer
  that is what it costs. The design fault was real either way. The registry has
  `loadCharacter` and `loadEntity` now, a character asks for its own twelve
  sprites instead of the whole manifest, the rest arrives without holding the
  first frame, and loading is idempotent so nothing is asked for twice. Measured
  in a browser: the room was on screen at 30 seconds instead of 60. The rest of
  T065 is the same mistake one level down: a character waits for twelve
  animations when the first frame needs `idle`, which is four files. Loading that
  first and the rest in the background should bring the first frame to a few
  seconds, and it does: `loadCharacter` takes an animation and defaults to
  `idle`, which is four files, and a character subscribes to the registry so it
  picks its real animation up when the rest arrives instead of standing in idle
  for ever. Measured in the same browser, the room is on screen at 7 seconds,
  from a minute. Five tests hold the first frame to what it should wait for: that
  it is one animation of one character, that it is four files and not sixty-five,
  that no entity, prop or effect sprite is in its way, and that every file the
  manifest will ask for is really in the bundle.
* T066, the entities. Every one of them drew a coloured rectangle: a red monster,
  a brown bag, a gold crown, a grey character, a yellow spring. The art was in
  the manifest the whole time, the registry had loaded it during that minute of
  black screen, and nothing asked for it. `PuzzleEntity` asks now, through one
  method, with the entity's own name, and the state that used to be a change of
  colour became a tint on the sprite: a frozen monster goes blue, a thrown switch
  goes green, a sleeping puppy wakes green, a spring squashes under the party.
  Two names differ between the world and the manifest and the difference is
  written down in the test rather than spread through the entities: the enum says
  `switchTrigger` where the art says `switch`, and `hushPuppy` where the art says
  `hush_puppy`. A sixth test compares the world's trigger types with the
  manifest's entity names, so a room whose entity has no art fails instead of
  quietly drawing a rectangle again.
  In the browser the rectangles are gone and the sprites are there. They are also
  small and dark, which is T063: the art is one pose per direction and the
  character sprite is nearly transparent, so what a player sees on a dark floor
  needs art work rather than code.
  T063 was not what it looked like. The manifest promised four and eight frames
  for the party and for the monsters, the springs, the doors, and the art has
  one image for the party and a *strip* for everything else: a monster is eight
  frames wide, 512 pixels, at 64 a frame. The character counts came from the
  number of directions, the entity counts from the index the generator gave each
  image in the sheet, and nothing read either number.
  The first fix was wrong and the test said so: `frames: 1` everywhere, which
  would have flattened the strips. The count is computable from the PNG's own
  header, and the test computes it: a strip is as wide as the frames it claims.
  The manifest now says what the files hold, 46 entries corrected, and the
  registry builds an animation where the art is a strip, so a monster walks and a
  spring bounces. Where the art is one image, a key or a crown, it stays still,
  which is what it is.
  What is left, and it is art: the party has one pose per direction. Walking is
  a pose that does not change, so the party slides. The generator draws
  `idle`, `walk` and `jump` with the same drawing, and real frames are a cycle of
  leg positions that nobody has drawn.
* T058 was not missing art either. `assets/sprites/tiles/` has a 1024x512 sheet
  for egyptus, safari, bookworld and penitentiary, exactly as the castle has
  one, and the four planets drew the castle because the room generator could not
  find their tileset: it looked for
  `games/headoverheels/assets/levels/tilesets/<theme>.tsx` from a working
  directory of `games/headoverheels`, a path that has never existed, and fell
  back to the castle one without saying so. Every path in that script is now
  resolved from the script's own location, and a missing tileset is an error
  rather than a fallback.
  `scripts/publish_planet_tilesets.py` publishes all five: it takes the sheet,
  masks it into diamonds, and writes the tileset with the tile count and the
  column count *measured from the PNG's own header*, so a sheet that changes size
  cannot leave a tileset describing something else. `--check` is in `make check`.
  Two tests hold the result: every room draws the tileset of its own theme, and
  every tileset a room names exists and names an image that exists.
  The first version of that script wrote `assets/images/<theme>.png` into the
  tileset, and the screen tests refused to let it through: flame_tiled resolves
  a tileset's image under `assets/images/`, so it asked for
  `assets/images/assets/images/castle.png`. The third time this project has found
  that class of fault by running the game, and the second time a test caught it
  before the commit rather than after.
  T061, the dispensary. The magic bag carried four and nothing could empty it:
  the world had no dispensary, no swop, and no trigger type for either, so a bag
  that filled stayed full for ever. There is now a `dispensary` trigger, an
  entity that takes everything out of the bag and puts it on the floor of the
  room it stands in, and one dispensary in each planet's entrance: the room the
  party arrives in. That placement is a design decision, written down so a person
  can move it rather than discover it.
  The entity takes the bag out where it is rather than asking the game which room
  is current, because an entity that drops things drops them where it stands, and
  asking the game meant a dispensary in any room but the current one would drop
  nothing. Two tests hold the rule: a full bag comes out onto the floor with the
  bag still worn, and a character with no bag, or with an empty one, changes
  nothing.
* T059, the audio sink, which is the half of it that turned out to be possible.
  Knight Lore has had an `AudioSink` with a silent one for tests since T044, and
  Head over Heels had none: the game starts the planet's music while it loads,
  audioplayers has no implementation outside a device, and it throws out of an
  initialiser the load is waiting on. So the game's load could not be finished
  in a plain test, which is why a plain test could not draw a frame of it. The
  game has the same shape now, `FlameAudioSink` and `SilentAudioSink`, and the
  audio goes wherever it is told. One test: with the sounds going nowhere the
  whole load runs, the room loads, and the map it names is there.
  The other half is still open, and now for a stated reason. Drawn onto a plain
  canvas in a plain test, a loaded game renders one colour: Flame's `render`
  wants a *mounted* game, with a real viewport and a camera that has been
  through a frame, and a test has no way to give it one. Drawing through the
  widget instead does render, and that test never finishes. The browser check is
  the evidence that stands, with a frame on disk.
* T052, the panel, done the way the board said it had to be done. The work was
  listed as three steps: make the panel resizable, make the tab bar fit, then
  move the inspector into a tab of its own. The first two are here.
  The panel's width was a fixed 320 pixels, which is why its controls were out of
  reach: the width was not the window's to give. It is a number now, clamped
  between 280 and 640 and to what the window can spare with the grid keeping its
  320, and a person drags the edge between the grid and the panel. The tab bar
  scrolls, because a column of 280 pixels cannot show five words, and a bar that
  cannot fit its labels overflows by the width of the one that does not fit: that
  was the 98822 pixels of RenderFlex the board records, twice, in two attempts
  that were reverted.
  Two tests, and the second is the one the board said was missing: dragging the
  handle wider makes the panel wider and the shell does not break, and a narrow
  window has a scrollable tab bar and no exception. Six shell tests had to learn
  to scroll a tab into view before tapping it, which is the right way round: a tab
  past the panel's edge is off it, not missing.
  The third step is not done and not pretended: the inspector is still in the
  panel's own column, and moving it into a tab of its own is now a small change
  rather than a layout rescue.
* T067, reported by a person running `make run-knightlore` and shown here as a
  black screen saying "Loading the castle". Two faults, and one thing that is
  not a fault at all.
  The art is forty-nine images and they were decoded one at a time: `await` inside
  a loop, so the browser was asked for the next image only after the last one had
  finished decoding. Measured in a headless browser, the first fifty assets came
  in five seconds and then the load crawled, two images every thirty seconds, for
  as long as it took. They load in batches of eight now, and a test holds that:
  a bundle that counts how many loads are open at once fails if the peak is one.
  On the machine here the improvement is not visible in the request pattern,
  because the image codec queues decodes whatever asks for them: the test proves
  the asking changed, and the wall is the codec.
  The second fault is worse for the person playing. A load that *failed* said
  nothing: the reason was drawn by an overlay that only appears once the assets
  are ready, and the loader was drawn on top of that overlay for ever. A missing
  world file, or any asset that is not there, produced a screen that never said
  anything again. The reason is on the screen now, in place of the loader, and a
  test drives a game whose world is missing and reads the message.
  And the third thing is not a fault: `The AudioContext was not allowed to start`
  is Chrome's autoplay policy, which is a rule about a page needing a click
  before it can make a sound. It is not the cause of the black screen, and it
  stops on its own when the player clicks.
  One thing a person should know, which is not in the code: `make run-knightlore`
  serves a *debug* build, where the whole program is compiled in the browser as it
  loads. For playing the game, build it and serve it, or run it in release.
* T068, the editor, which could not be run at all. It was a library: the shell, the
  palette, the sprite browser and the TSX authoring view all existed, all were
  tested, and nothing put them on a screen. It has an entry point now, and
  `make serve-editor` builds it and serves it on 8082, with `make run-editor` for
  the debug build it now also has. `flutter create --platforms web` added the
  scaffolding the web needs, and with it a README that said "A new Flutter
  project" and a test for a counter: both replaced, the README with what the
  editor is and does not do, the test with one that opens the app and opens the
  project picker.
  The icon font is the part worth remembering. `packages/iso_editor` was the only
  package in the repository without `uses-material-design: true`, so the Material
  icon font was never bundled and every icon in the editor rendered as an empty
  box: the tools, the toolbar, the save button, the picker. It looked fine in a
  debug build, which is the only way the editor had ever been run, because a
  debug build does not need the flag. Nobody had seen the editor in a release
  build because nobody could make one. Found by screenshotting the release build
  and looking at it, the way every other visual fault in this board was found.
  What the editor still does not do: keep anything. Its map lives in the page, so
  closing the browser loses the work. It reads and writes Tiled files through the
  file gateway and has nowhere to keep a project. That is the next thing it wants.
* T069, the follow-up to T068, and the fault the entry point hid. The editor
  opened an empty room: the Graph tab had no world, the sprite browser had no
  sprites, the palette had no tileset, because the only storage was in memory
  and a project's keys are repository-relative, `games/headoverheels/assets/
  levels/world.json`. Picking a game in the picker changed which keys were asked
  for and every one of them was missing. An editor that cannot open a project is
  a widget.
  It asks now. `FileSystemEditorStorage` resolves a project's keys against a
  directory, and the editor asks for that directory before it opens anything, so
  picking a game loads that game's real world, sprites and tileset, and writing
  writes the file the game loads. A browser has no directory to open, so the file
  system is behind a conditional import and the browser's build says so in words
  rather than failing somewhere that does not explain itself.
  Creating a new project still does not exist, and that is the honest answer to
  the question behind this: a project is a directory with a world, a manifest and
  some rooms, and making one means writing that scaffold. It is a feature, not a
  bug, and it is not done here.
* T070, a tap that missed its cell as soon as the grid had been dragged. The
  `onTapUp` position was already in the grid's coordinates — the detector is the
  child the viewer transforms — and it went through `toScene` as well, so the pan
  was applied twice. The grid could not be dragged before the first drag, which
  is why it looked right for so long. A test drives it: tap, drag, tap the same
  place on the grid, and the same cell has to come back. It fails on the old code
  with a cell one step out, and that was checked rather than assumed.
* T071, asked for as "show me the sprites and the sounds". A person wanted to see
  the assets and how they are laid out, and the honest answer started with a
  correction: there is nothing real to extract. The original 1987 games are not
  the source of any sheet or sound here. `docs/RESEARCH/Head Over Heels.tzx` is
  in the repository because it was studied, and the sprites the games load are
  drawn by the generators in `scripts/` and the sounds are computed by each
  game's `tool/generate_audio.dart`. Copying assets out of the tape image would
  be redistributing somebody else's work, which is the one thing this repository
  has never done.
  So `make assets-preview` shows what there is: every manifest entry with its
  sheet, animation, direction and frame count, every sheet on disk that no
  manifest entry points at, and every sound with a player. 117 sheets and 57
  sounds, in a page, checked in a browser.
  And the page immediately earned its keep. Head over Heels' two unlisted sheets
  are the character masters, sliced into the per-direction sheets, which is what
  they are for. Knight Lore's five are scrolls: `props/scroll_<area>.png`, drawn,
  on disk, and loaded by nobody, because `propTypes` does not list `scroll` and
  the runtime builds its own sprite paths instead of reading the manifest meant
  to describe them. That is not the whole story, and it is worse: nothing in the
  Knight Lore renderer draws world items at all, so a scroll or an ingredient
  lying on the floor of a room is not on the screen. The game is six ingredients
  and two scrolls, and the player cannot see either. The tests never caught it
  because every test that mentions an item tests the item's logic — pickup,
  casting, balance — and not one asks whether it is drawn. That is T072,
  and the tests have teeth: the coverage test names every item that has no
  loaded sheet (twelve failures, six ingredients and six scrolls, named
  individually), and the rendering test renders the gatehouse, opens a chest
  through the real path and renders again, and demands that the second frame is
  *lighter* — because an item's shadow is drawn whether or not the item is, so
  light is the number that proves the item is there. Both were run with the
  drawing switched off to be sure they could fail. The first version of the
  pixel test passed with the drawing off, because it moved the knight between
  the two frames and measured the knight; the party is now in place before the
  first frame, so the only thing that can change the picture is the item.
* T073, found while drawing T072 and not fixed there. Ten chests in the world
  hold ten items: the six ingredients, the golden key, and three scrolls. The
  catalogue has six scrolls and the night is only survivable with Magic Armour
  or Invisibility — and neither is in any chest. The wolf takes the sabreman
  every night, the party splits, and nothing in the world can prevent it. The
  game is still winnable, because the curse lifts on six ingredients in the
  cauldron and scrolls are never demanded, so this is a headline mechanic with
  no answer rather than an unwinnable game. Adding three chests was a balance
  decision, so it was asked for; and then it was made, and the decision is
  written down, because a decision nobody can read is a decision nobody can
  check.
  Magic Armour is in the great hall, one room from the gatehouse. The night is
  the first thing that can kill you, and the answer to it cannot be the deepest
  treasure in the world; the hall holds no cauldron either, so the answer to the
  wolf is not something the party has to stand next to the remedy to find.
  Invisibility is in the jungle ruins, three rooms in, beside the casket. Flip
  is in the cauldron cave, which had no chest at all: the whole cauldron area,
  where the remedy is brewed, was treasure-free.
  The rule behind those three lives in a test rather than in this paragraph.
  Every chest in every room has to stand on a walkable tile a party can walk to,
  measured by flooding the real `.tmx` terrain from the room's own spawn; the
  two defensive scrolls have to be within three rooms of the gatehouse on the
  room graph and must never share a room with a cauldron; and every scroll in
  the catalogue has to be in some chest. Both of the new tests were run before
  the chests were placed and named all three missing scrolls, so they can fail.
  The flood fill found nothing this time — the tiles were checked before the
  chests went in — but the ten older chests pass through it, and a chest added
  inside a wall tomorrow will not.
* T074, measured rather than assumed. The Knight Lore web build sits on
  "Loading the castle…" and never draws a room. It is not T072: with the eight
  original prop types the build fetches 50 images and still never draws within
  150 seconds, and with the fifteen it fetches 85 and still never draws within
  250. Both were built and measured here. The suspicion is the software
  renderer in this environment decoding 50-85 small PNGs, which is not what a
  browser with a GPU does, but that is a suspicion and not a measurement of a
  real browser, so it is not written down as an excuse. What it does mean is
  that the item drawing has no browser evidence behind it, and the claim for it
  rests on the pixel test alone.
* T064, one line, and it was worth two tests. The menu said "Remastered for
  Android": a remaster nobody made, claimed by a menu that cannot know what
  platform it is on, since the same build serves the web and an APK. It now says
  what this is, a Flutter port on the web and on Android. The version beside it
  was written in the menu and in the pubspec and nothing compared them, so a
  release would have shown the number it used to have; the menu reads one
  constant now and a test compares it with the pubspec. A third test holds the
  menu's own words, which nothing did: the title, the subtitle, and the absence
  of the old claim.
* Audit of the Sprint 09 backlog, checked against the code rather than the
  board. T025, the atlas: `scripts/pack_atlas.py` is referenced by nothing, the
  Makefile never runs it, and `assets/sprites/atlases/` is empty. The game loads
  65 individual sheets through the manifest, which works and is what the editor
  reads, so the atlas was an optimisation nothing needed. Not needed, and the
  script goes. T026, the sprite registry: it works and the characters use it,
  but it hardcodes the animation names and the eight directions in Dart while
  `assets/sprites/manifest.yaml` is the validated source of truth for the same
  facts. Two sources can disagree and the validator only knows about one, so
  that is T053. T027, gameplay integration: the systems are registered and the
  game runs, but the game's own tests number two, and forty nine of its fifty one
  are audio. The integration is real and unverified, which is T054. T029, the
  asset migration: the assets are under `games/headoverheels/assets`, five room
  themes, world.json, 65 sheets, and the validation pipeline passes 169 checks.
  Done. T028, visual QA, is the real gap: Knight Lore renders itself to PNGs and
  the test gates on it, and Head over Heels renders nothing, so a broken
  renderer there would only be found by playing. That is why T028 went from low
  to high.
* T036 scope: the editor could read a TSX and could not write one. Now
  `TsxTileDefinition` and `TsxTilesetDefinition` are values with `copyWith`,
  `withProperty`, `withoutProperty`, `upsertTile` and `removeTile`, a
  `TsxTilesetDefinition.create` that sizes a new tileset from its sheet, a
  `toXmlString` that writes what Tiled reads, and a `TsxValidation` in the same
  shape as the world graph's. The Palette tab grew a tile inspector: edit the
  type, edit the class, add and remove properties, delete the tile, save the
  file, and author a new tileset from a sheet already in the project, whose size
  is measured from the image rather than typed. A property keeps its declared type
  when it is edited, so a number does not quietly become text.
  `test/tsx_authoring_test.dart` (18) covers the model: round trip through
  parse and write, property types, validation, and the catalog. Two layout bugs
  were fixed on the way, both real: the inspector's scroll view handed its fields
  an unbounded width, so a row of `Expanded` grew to 100 000 pixels, and
  `TsxBrowser` overflowed by 10 pixels whenever its panel was short, which the
  existing shell test caught as soon as the inspector took part of the height.
* T052 scope, second attempt, and what it proved. The inspector now has a tab of
  its own, which is the obvious fix, and it does not work: a fifth tab in the
  320 pixel panel makes six existing shell tests fail, a control land at x of
  1523 in a 1500 pixel window, and a RenderFlex overflow to the right by 98822
  pixels. Widening the panel to 420 did not help, and narrowing the tab bar made
  it scrollable, which is correct on its own. The retype-and-save flow itself
  works: a test drove the inspector, changed a tile's type, saved, and read the
  file back, so the feature is fine and the container is not.
  So the panel is the bug, and it needs a real pass before anything else goes in
  it: a fixed 320 pixel column carrying five tabs, a sprite manager, a world
  graph and a tile form. The work is to make the panel resizable and the tab bar
  fit, then move the inspector into a tab of its own, and only then wire the
  shell tests. Everything from this attempt was reverted rather than shipped, so
  T036 stands as it was.
* T051 scope: a pubspec entry ending in `/` ships the files directly inside that
  directory and nothing below it, so `assets/sprites/` shipped the manifest and
  none of the sprites. Both games were broken in the browser and neither build
  complained: Head over Heels published 1 of 157 files, Knight Lore 34 of 99.
  `scripts/publish_assets.py` now writes the leaf list from the tree between
  markers in each pubspec, and `make check` fails when the two disagree. Head over
  Heels publishes 122 files, which is every file except the gitignored
  `assets/sprites_normalized/` cache; Knight Lore publishes 99 of 99.
  Found while checking that T049's audio reached the web build: the 30 WAVs were
  correctly ignored by the bundler because `assets/audio/` said nothing about
  `assets/audio/music/`.
* T050 scope: 34 findings, now zero, and `flutter analyze` on the game is clean
  without a flag. Two imports and a computed name in `sprite_registry.dart` that
  nothing read; three dead locals in the joystick, and a `_isDragging` field that
  was set on every pan and never read, which is now used: the knob brightens
  while it is held, which is what the field was clearly for. Twenty two
  `withOpacity` calls became `withValues(alpha:)`, which keeps the alpha in
  floating point instead of quantising it to eight bits. The theme set both
  `background` and `surface`, and both `onBackground` and `onSurface`;
  Material 3 ignores the deprecated pair and derives the background from
  `surface`, so the two lines are gone rather than renamed, and no colour that
  renders has changed. Two constructors now pass their parameters up.
* T035 scope: the root package is now `games/headoverheels`. `lib`, `assets`,
  `style`, `test`, the five platform directories, `analysis_options.yaml`,
  `.metadata` and the pubspec moved with `git mv`, so the history follows the
  files. Nothing at the top level is a package any more, so the Makefile names
  where each command runs: `setup` loops over both games and both libraries,
  `test`, `lint` and `build` run in `games/headoverheels`, `format-check` covers
  `games packages`, and `assets-check` passes the game directory to both Python
  validators. `run-headoverheels` and `build-headoverheels` join the Knight Lore
  equivalents. `EditorProject.headoverheels` now points inside `games/`, and its
  test proves every key of both projects stays inside its own game directory.
  Two things the move exposed: `format-check` had never covered `games/`, so ten
  Knight Lore files had drifted from the formatter and are now formatted; and the
  T046 test asserted the two projects differ only by the game directory, which
  stopped being true once both live under `games/`, so the invariant is now the
  stronger one: the sprite paths are parallel and no project can read the other
  game's files.
* T049 scope: the thirty sounds of Head over Heels are now computed, in
  `lib/core/audio/hoh_cues.dart`, and `tool/generate_audio.dart` writes them as
  WAVs under `assets/audio`. The synthesiser moved to `iso_core`, exported as
  `package:iso_core/audio.dart` so a generator can run it on the plain Dart VM
  without Flame, and both games share it. The thirty path constants in
  `AudioSystem` are gone: the class asks `HohCue` for a path, so a sound cannot
  be named without a file behind it, and `test/audio_test.dart` (49 tests) checks
  every cue against the file on disk, that the file is the same sound the cue
  renders, that the eight music loops do not click at the loop point, and that
  nothing under `assets/audio` is anything but a WAV this repository produces.
  The original `.ogg` tracks are not in the repository: nothing produced them and
  their names are the original game's rooms.
* T048 scope: `test/balance_test.dart` measures the game and prints it: 48 room
  changes for a run that knows the world (2.7 of the 40 days), 20 to walk every
  room, and the spell lifetimes in days from the data. Two invariants keep the
  clock meaningful, and the report is in `games/knightlore/README.md`.
  The measurements found four defects, all fixed:
  `nightFalls()` set the werewolf phase in both branches, so Magic Armour and
  Invisibility did nothing and two of the six scrolls were pointless; an instant
  spell (Flip) stayed in the active set for ever, which was the only thing the
  dead `SpellState.advance(ticks)` cleaned up, so that method went too and decay
  now happens at dawn and nowhere else; the emerald and the jewel each existed in
  two containers, and the casket shared a room with one of them, so the six
  ingredients are now one per room across five areas; and the rule that every
  container holds something was right but did not allow a spent container, which
  is now stated rather than assumed.
* T046 scope: `EditorProject` (`packages/iso_editor/lib/src/app/editor_project.dart`)
  is a name plus the paths a game keeps its files in, and the two shipped games
  are declared there as data. The shell has a picker that switches between them,
  the app reloads the sprite manifest of the game being opened, and the graph
  panel is keyed on the project so it reads the new world instead of keeping the
  old graph. `test/editor_projects_test.dart` (6 tests) reads the repository
  through an `EditorStorage`, so the paths are proved against the files the
  games actually write: it opens the Knight Lore world (15 rooms, 5 themes, no
  validation errors), checks its manifest names sheets that exist, and switches
  the picker in a widget test.
  The test found the paths were wrong: Knight Lore's files live inside
  `games/knightlore`, so every key needs the game directory, which is now what
  makes the two projects differ by one string.
* T045 scope: four things, all data or geometry rather than new state.
  `lib/src/render/ambience.dart` holds the light of each area and the shape of a
  shadow; the room view draws a shadow under every figure and washes the finished
  room with the area's colour; `sundial.dart` draws the forty day dial on the HUD
  from a pure geometry class, so a test checks the marker really travels instead
  of trusting a picture; and a room change now fades over `transitionSeconds`
  (0.22s) with the wash easing back in behind it.
  The tests found four defects, all fixed: the fade read the camera size, which
  asserts before the game is laid out and would have crashed the first frame; the
  ambience never came back after a room change, leaving the room unlit forever;
  `RoomView.bounds` was in projection space while everything is drawn in
  `screenOf` space, so the wash was offset by the origin and painted over half
  the screen; and the wash used the view's strength as the alpha, which starts
  at 1, so it was fully opaque instead of the area's own 0.35 to 0.45.
* T044 scope: the audio is synthesised, not sampled. `lib/src/audio/audio_synth.dart`
  is pure Dart (pulse, triangle, noise, glide, envelopes), `knight_lore_cues.dart`
  holds 22 cues and five seamless ambient loops, and `tool/generate_audio.dart`
  writes `assets/audio/*.wav` from that same code. `test/audio_test.dart` proves
  each cue is audible, brief, unclipped, distinct and that the committed files
  match a fresh render, so a cue cannot drift from its file.
  `test/audio_wiring_test.dart` proves the rules actually reach the sounds: a
  step, a bump, a door, a pickup, a trap, a spell per scroll, night and dawn.
  The failures the tests found: the WAV header was not in the pubspec asset list,
  so a release build shipped no audio at all; the frame hash rounded float samples
  to zero and made every sound look identical; and the loop seam test compared
  the wrong samples, which proves nothing for a square wave.
* T047 scope: `KnightLoreGame.createView()` + `RoomView.renderInto()` render a
  room off-screen; `test/visual_preview_test.dart` writes `build/preview/*.png`
  and gates on colour count, an FNV-1a frame hash per area and the bounding box
  of drawn pixels, so a cropped or blank room fails the build. The evidence found
  three real defects: the room was cropped, the tileset mixed 32 and 48 tall
  sprites (walls floated 16px above their tile), and the floor tile's inner
  diamond was drawn off centre, shearing the grid. All three are fixed.
* T033 scope: TMX/TSX import, pan/zoom dimetric canvas with tileset image preview, paint/place/erase
  tools, layer visibility, object inspector, document save/load, TMX export, TSX palette browser and
  file-picker gateways. Known gap: no per-layer tile selection.

## Done
* T001: Research original game mechanics & online MSX version
* T002: Define core game architecture
* T003: Implement Head/Heels character controllers & physics
* T004: Build isometric level rendering engine
* T005: Implement puzzle mechanics (switches, conveyors, doughnuts)
* T006: Implement remaining puzzle mechanics (spring, fish, doughnut, monster)
* T007: Implement final puzzle mechanics + InteractionSystem
* T008: Create modern UI/UX: menus, HUD, touch controls
* T009: Implement Bag system (Heels carry items)
* T010: Connect CharacterState notifier to CharacterComponent
* T011: Create test room TMX with all entity types
* T012: Port original level data / design new levels
* T013: Audio: SFX, music, adaptive audio system
* T014: Polish: animations, transitions, accessibility
* T015: Release build & Play Store preparation
* T016: Asset & Visual System Audit
* T017: Visual Design System
* T018: Character Masters
* T019: Character Animation Pipeline
* T020: Environment Masters
* T021: Castle Tileset
* T022: Entity Masters
* T023: Remaining Themes
* T024: Validation Pipeline
* T030: Builder architecture & reusable iso_core foundation
* T031: Editor document, storage, undo/redo & sprite import foundation
* T032: Builder CLI scaffold and project validation
* T033: Visual isometric map editor (palette/TSX browser, file gateways, canvas preview)
* T034: Sprite browser/animator and asset management UI (manifest editor, frame import, delete)
* T037: World graph viewer/editor with topology validation (Graph tab, world.json round trip)
* T039: Puzzle trigger inspector in the graph tab (targetId and target room editing)
* T040: Spell scrolls — catalogue, chests that hold one item each, casting with 1-9
* T043: Screens — title, pause, status scroll, victory and defeat, with the
  screen state machine in the game so it is testable without widgets
* T042: Traps and hazards — balls block, spikes/blocks/demons catch, a trap fires once
  per visit and costs a day, with a route check that no room becomes unwalkable
* T041: Treasures and the six ingredients — containers open once, statues hold items, the
  wizard never repeats a delivered ingredient, and a full playthrough test wins the game
* T038: Second example game, Knight Lore: rules, world, room maps, generated art, Flame loop,
  HUD, keyboard input and a working web build