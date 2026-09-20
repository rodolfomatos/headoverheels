# T011 — Solution Proposal: Test Room TMX

## CHOSEN APPROACH

### 1. TMX Structure
```
assets/levels/
├── tilesets/
│   ├── castle.tsx          # Tileset definition
│   └── castle.png          # Tileset image (64x32 tiles)
├── rooms/
│   ├── test_room.tmx       # Test room with all entities
│   └── test_room_2.tmx     # Second room for teleport
└── world.json              # Room graph
```

### 2. TMX Layer Structure
```xml
<map orientation="isometric" tilewidth="64" tileheight="32" width="16" height="16">
  <tileset firstgid="1" source="tilesets/castle.tsx"/>
  <layer name="Floor" width="16" height="16">...</layer>
  <layer name="Walls" width="16" height="16">...</layer>
  <objectgroup name="Entities">
    <object id="switch_1" type="switchTrigger" x="320" y="160" properties="targetId:door_1"/>
    <object id="door_1" type="door" x="480" y="0" width="64" height="32" properties="targetRoom:test_room_2,targetEntrance:south,isLocked:true,keyId:key_1"/>
    <object id="conveyor_1" type="conveyor" x="0" y="0" width="640" height="32" properties="conveyorDirection:east,conveyorSpeed:2"/>
    <object id="spring_1" type="springItem" x="320" y="320"/>
    <object id="fish_1" type="bag" x="640" y="320"/>
    <object id="crown_1" type="crown" x="960" y="160" properties="planetId:castle"/>
    <object id="bag_1" type="bag" x="160" y="480"/>
    <object id="hushpuppy_1" type="hushPuppy" x="800" y="320"/>
    <object id="monster_1" type="monster" x="0" y="0" width="64" height="32" properties="patrolPoints:[(10,5),(15,5)],waitTime:0.5"/>
    <object id="guardian_1" type="guardian" x="1024" y="160" width="64" height="64" properties="patrolPoints:[(16,2)]"/>
    <object id="teleport_1" type="teleport" x="512" y="512" properties="targetRoom:test_room_2,targetEntrance:south,oneWay:false"/>
  </objectgroup>
  <objectgroup name="Triggers">
    <object id="door_trigger_1" type="door" x="480" y="0" width="64" height="32" properties="targetRoom:test_room_2,targetEntrance:south"/>
  </objectgroup>
</map>
```

### 3. Tileset (castle.tsx)
```xml
<tileset version="1.2" tiledversion="1.10.0" name="castle" tilewidth="64" tileheight="32" tilecount="256" columns="16">
  <image source="castle.png" width="1024" height="512"/>
  <!-- Tile definitions with collision properties -->
  <tile id="0" type="floor"/>
  <tile id="1" type="wall" property="collidable=true"/>
  <!-- ... -->
</tileset>
```

### 3. World Graph (world.json)
```json
{
  "rooms": {
    "test_room": {
      "file": "rooms/test_room.tmx",
      "theme": "castle",
      "exits": {
        "east": { "room": "test_room_2", "entrance": "west" }
      },
      "spawnPoint": { "x": 1, "y": 1, "z": 0 },
      "triggers": [...]
    },
    "test_room_2": {
      "file": "rooms/test_room_2.tmx",
      "theme": "castle",
      "exits": {
        "west": { "room": "test_room", "entrance": "east" }
      },
      "spawnPoint": { "x": 14, "y": 8, "z": 0 }
    }
  },
  "startRoom": "test_room"
}
```

### 4. Asset Pipeline
- Create castle.tsx in Tiled editor
- Reference in TMX: `source="tilesets/castle.tsx"`
- Place castle.png in `assets/levels/tilesets/`
- Add to pubspec.yaml assets:
```yaml
flutter:
  assets:
    - assets/levels/tilesets/
    - assets/levels/rooms/
```

## WHAT WILL CHANGE

### New Files
```
assets/levels/
├── tilesets/
│   ├── castle.tsx
│   └── castle.png
├── rooms/
│   ├── test_room.tmx
│   └── test_room_2.tmx
└── world.json
```

### Modified Files
- `lib/features/gameplay/room/room_graph.dart` — add test rooms to world graph

## VERIFICATION CRITERIA

### Unit Tests
- [ ] TMX loads without errors
- [ ] All entities spawn correctly
- [ ] Room transitions work

### Integration Tests
- [ ] Load test_room → all entities spawn
- [ ] Switch activates door
- [ ] Conveyor pushes character
- [ ] Spring boosts jump
- [ ] Fish saves checkpoint
- [ ] Crown increments collection
- [ ] Bag pickup grants carry ability
- [ ] Hush Puppy teleports from Head
- [ ] Monster patrols and kills
- [ ] Guardian blocks until 4 crowns
- [ ] Teleport transitions to test_room_2

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes