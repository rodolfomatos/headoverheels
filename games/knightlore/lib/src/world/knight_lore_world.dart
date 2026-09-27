import 'package:iso_core/iso_core.dart';
import 'package:vector_math/vector_math.dart' show Vector2, Vector3;

/// Room identifiers, grouped by area. The five areas and their role follow the
/// structure of the original game; the individual room names and the topology
/// are our own, authored for this engine.
class KlAreas {
  static const String castle = 'castle';
  static const String jungle = 'jungle';
  static const String cauldron = 'cauldron';
  static const String mine = 'mine';
  static const String tower = 'tower';

  static const List<String> all = [castle, jungle, cauldron, mine, tower];
}

class KlRooms {
  static const String gatehouse = 'castle_gatehouse';
  static const String greatHall = 'castle_great_hall';
  static const String corridor = 'castle_corridor';
  static const String laboratory = 'castle_laboratory';
  static const String underground = 'castle_underground';

  static const String jungleEntrance = 'jungle_entrance';
  static const String jungleTrack = 'jungle_track';
  static const String jungleRuins = 'jungle_ruins';

  static const String cauldronEntrance = 'cauldron_entrance';
  static const String cauldronCave = 'cauldron_cave';

  static const String mineEntrance = 'mine_entrance';
  static const String mineShaft = 'mine_shaft';
  static const String mineVault = 'mine_vault';

  static const String towerEntrance = 'tower_entrance';
  static const String towerTop = 'tower_top';

  /// The engine is two dimensional, so "down to the crypt" and "down to the
  /// mine" are ordinary doorways on another edge; the ids carry the flavour.
  ///
  /// Melkhior's laboratory, where the cauldron lives.
  static const String wizardRoom = laboratory;
}

/// Builds the Knight Lore world in the generic `iso_core` format. The same data
/// is written to `assets/world/knightlore_world.json` so the editor and the
/// runtime read identical files.
class KnightLoreWorld {
  const KnightLoreWorld._();

  static const String worldKey = 'assets/world/knightlore_world.json';

  static WorldGraph build() {
    final rooms = <String, RoomInfo>{};

    void room(
      String id,
      String area, {
      Vector3? spawn,
      List<RoomExit> exits = const [],
      List<RoomTrigger> triggers = const [],
    }) {
      rooms[id] = RoomInfo(
        id: id,
        file: 'rooms/$area/$id.tmx',
        theme: area,
        spawnPosition: spawn ?? Vector3(4, 3, 0),
        exits: exits,
        triggers: triggers,
      );
    }

    RoomExit exit(String direction, String room, String entrance) =>
        RoomExit(direction: direction, room: room, entrance: entrance);

    RoomExit locked(
            String direction, String room, String entrance, String key) =>
        RoomExit(
          direction: direction,
          room: room,
          entrance: entrance,
          isLocked: true,
          keyId: key,
        );

    RoomTrigger trigger(
      String id,
      String type,
      double x,
      double y, {
      Map<String, dynamic>? properties,
    }) =>
        RoomTrigger(
          id: id,
          type: type,
          position: Vector3(x, y, 0),
          size: Vector2(1, 1),
          properties: {
            'id': id,
            'type': type,
            'position': {'x': x, 'y': y, 'z': 0},
            'size': {'width': 1, 'height': 1},
            if (properties != null && properties.isNotEmpty)
              'properties': properties,
          },
        );

    room(
      KlRooms.gatehouse,
      KlAreas.castle,
      spawn: Vector3(4, 3, 0),
      exits: [
        exit('north', KlRooms.greatHall, 'south'),
        exit('east', KlRooms.jungleEntrance, 'west'),
      ],
      triggers: [
        trigger('ball_1', 'ball', 2, 3),
        trigger('chest_1', 'chest', 6, 3, properties: {'itemId': 'diamond'}),
      ],
    );

    room(
      KlRooms.greatHall,
      KlAreas.castle,
      exits: [
        exit('south', KlRooms.gatehouse, 'north'),
        exit('west', KlRooms.corridor, 'east'),
        exit('north', KlRooms.underground, 'south'),
      ],
      triggers: [
        trigger('ball_2', 'ball', 3, 4),
        trigger(
          'falling_1',
          'fallingBlock',
          6,
          2,
          properties: {'period': 24, 'activeFor': 14, 'phase': 6},
        ),
        // A statue already emptied, here to say the treasure was moved on.
        trigger(
          'statue_1',
          'statue',
          5,
          4,
          properties: {'state': 'empty'},
        ),
        trigger('witch_1', 'witch', 6, 6),
      ],
    );

    room(
      KlRooms.corridor,
      KlAreas.castle,
      exits: [
        exit('east', KlRooms.greatHall, 'west'),
        exit('north', KlRooms.laboratory, 'south'),
        locked('west', KlRooms.mineEntrance, 'east', 'golden_key'),
      ],
      triggers: [
        trigger('portcullis_1', 'portcullis', 3, 2),
        trigger(
          'spikes_1',
          'spikes',
          4,
          4,
          properties: {'period': 16, 'activeFor': 8, 'phase': 0},
        ),
        trigger('ball_3', 'ball', 5, 5),
      ],
    );

    room(
      KlRooms.laboratory,
      KlAreas.castle,
      exits: [exit('south', KlRooms.corridor, 'north')],
      triggers: [
        trigger(
          'wizard_1',
          'wizard',
          4,
          3,
          properties: {'name': 'Melkhior', 'requiresForm': 'sabreman'},
        ),
        trigger(
          'cauldron_1',
          'cauldron',
          5,
          5,
          properties: {'ingredientsRequired': CurseIngredients.required},
        ),
        trigger(
          'cauldron_2',
          'cauldron',
          3,
          5,
          properties: {'ingredientsRequired': CurseIngredients.required},
        ),
      ],
    );

    room(
      KlRooms.underground,
      KlAreas.castle,
      exits: [exit('south', KlRooms.greatHall, 'north')],
      triggers: [
        trigger(
          'chest_2',
          'chest',
          2,
          4,
          properties: {'itemId': 'scroll_shield'},
        ),
        trigger('ball_4', 'ball', 6, 6),
      ],
    );

    room(
      KlRooms.jungleEntrance,
      KlAreas.jungle,
      exits: [
        exit('west', KlRooms.gatehouse, 'east'),
        exit('north', KlRooms.jungleTrack, 'south'),
        exit('south', KlRooms.cauldronEntrance, 'north'),
      ],
      triggers: [
        trigger('chest_3', 'chest', 3, 5,
            properties: {'itemId': 'pot_of_gold'}),
        trigger('witch_2', 'witch', 6, 3),
      ],
    );

    room(
      KlRooms.jungleTrack,
      KlAreas.jungle,
      exits: [
        exit('south', KlRooms.jungleEntrance, 'north'),
        exit('east', KlRooms.jungleRuins, 'west'),
        exit('west', KlRooms.mineEntrance, 'east'),
      ],
      triggers: [
        trigger('ball_5', 'ball', 4, 2),
        // A statue already emptied, here to say the treasure was moved on.
        trigger(
          'statue_2',
          'statue',
          2,
          5,
          properties: {'state': 'empty'},
        ),
      ],
    );

    room(
      KlRooms.jungleRuins,
      KlAreas.jungle,
      exits: [exit('west', KlRooms.jungleTrack, 'east')],
      triggers: [
        trigger(
          'chest_4',
          'chest',
          5,
          4,
          properties: {'itemId': 'casket'},
        ),
      ],
    );

    room(
      KlRooms.cauldronEntrance,
      KlAreas.cauldron,
      exits: [
        exit('north', KlRooms.jungleEntrance, 'south'),
        exit('east', KlRooms.cauldronCave, 'west'),
      ],
      triggers: [trigger('ball_6', 'ball', 4, 5)],
    );

    room(
      KlRooms.cauldronCave,
      KlAreas.cauldron,
      exits: [exit('west', KlRooms.cauldronEntrance, 'east')],
      triggers: [
        trigger(
          'cauldron_3',
          'cauldron',
          4,
          4,
          properties: {'ingredientsRequired': CurseIngredients.required},
        ),
        trigger('witch_3', 'witch', 2, 2),
      ],
    );

    room(
      KlRooms.mineEntrance,
      KlAreas.mine,
      exits: [
        exit('east', KlRooms.corridor, 'west'),
        exit('west', KlRooms.jungleTrack, 'east'),
        exit('north', KlRooms.mineShaft, 'south'),
      ],
      triggers: [
        trigger('chest_5', 'chest', 2, 4, properties: {'itemId': 'jewel'}),
      ],
    );

    room(
      KlRooms.mineShaft,
      KlAreas.mine,
      exits: [
        exit('south', KlRooms.mineEntrance, 'north'),
        exit('west', KlRooms.mineVault, 'east'),
      ],
      triggers: [
        trigger('ball_7', 'ball', 3, 3),
        trigger(
          'demon_1',
          'demon',
          4,
          4,
          properties: {'period': 20, 'activeFor': 7, 'phase': 10},
        ),
        trigger(
          'bounce_1',
          'bouncingBlock',
          6,
          4,
          properties: {'period': 14, 'activeFor': 5, 'phase': 3},
        ),
        trigger('ball_8', 'ball', 5, 5),
        trigger(
          'chest_8',
          'chest',
          2,
          2,
          properties: {'itemId': 'scroll_open_door'},
        ),
        trigger(
          'chest_9',
          'chest',
          5,
          2,
          properties: {'itemId': 'scroll_telekinesis'},
        ),
      ],
    );

    room(
      KlRooms.mineVault,
      KlAreas.mine,
      exits: [
        exit('east', KlRooms.mineShaft, 'west'),
        exit('north', KlRooms.towerEntrance, 'south'),
      ],
      triggers: [
        trigger(
          'chest_6',
          'chest',
          4,
          3,
          properties: {'itemId': 'golden_key'},
        ),
        trigger(
          'spikes_2',
          'spikes',
          2,
          4,
          properties: {'period': 12, 'activeFor': 5, 'phase': 7},
        ),
      ],
    );

    room(
      KlRooms.towerEntrance,
      KlAreas.tower,
      exits: [
        exit('south', KlRooms.mineVault, 'north'),
        exit('north', KlRooms.towerTop, 'south'),
      ],
      triggers: [
        trigger('witch_4', 'witch', 6, 2),
        trigger(
          'chest_13',
          'chest',
          2,
          5,
          properties: {'itemId': 'emerald'},
        ),
      ],
    );

    room(
      KlRooms.towerTop,
      KlAreas.tower,
      exits: [exit('south', KlRooms.towerEntrance, 'north')],
      triggers: [
        trigger(
          'chest_7',
          'chest',
          4,
          2,
          properties: {'itemId': 'chalice'},
        ),
      ],
    );

    return WorldGraph(
      rooms: rooms,
      startRoom: KlRooms.gatehouse,
      groups: [
        for (final area in KlAreas.all)
          WorldGroup(
            id: area,
            name: _areaNames[area] ?? area,
            properties: {'area': area},
          ),
      ],
    );
  }

  static const Map<String, String> _areaNames = {
    KlAreas.castle: 'Knightlore Castle',
    KlAreas.jungle: 'The Jungle',
    KlAreas.cauldron: "Witches' Cauldron",
    KlAreas.mine: 'Abandoned Mine',
    KlAreas.tower: "Wizard's Tower",
  };
}

/// Kept next to the world so the data files and the rules cannot drift.
class CurseIngredients {
  static const int required = 6;
}
