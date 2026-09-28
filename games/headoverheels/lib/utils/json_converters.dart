// JSON converters for vector_math types and Freezed unions.

import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';

class Vector2Converter implements JsonConverter<Vector2, List<double>> {
  const Vector2Converter();

  @override
  Vector2 fromJson(List<double> json) => Vector2(json[0], json[1]);

  @override
  List<double> toJson(Vector2 object) => [object.x, object.y];
}

class Vector3Converter implements JsonConverter<Vector3, List<double>> {
  const Vector3Converter();

  @override
  Vector3 fromJson(List<double> json) => Vector3(json[0], json[1], json[2]);

  @override
  List<double> toJson(Vector3 object) => [object.x, object.y, object.z];
}

/// The bag's contents: a list of items, each in the shape [CarriedItemConverter]
/// reads.
class CarriedItemsConverter
    implements JsonConverter<List<CarriedItem>, List<dynamic>> {
  const CarriedItemsConverter();

  @override
  List<CarriedItem> fromJson(List<dynamic> json) => json
      .map(
        (entry) => const CarriedItemConverter().fromJson(
          entry as Map<String, dynamic>,
        ),
      )
      .toList();

  @override
  List<dynamic> toJson(List<CarriedItem> object) =>
      object.map((item) => const CarriedItemConverter().toJson(item)).toList();
}

class CarriedItemConverter
    implements JsonConverter<CarriedItem, Map<String, dynamic>> {
  const CarriedItemConverter();

  @override
  CarriedItem fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'none':
        return const CarriedItem.none();
      case 'key':
        return CarriedItem.key(json['keyId'] as String);
      case 'crown':
        return const CarriedItem.crown();
      case 'other':
        return CarriedItem.other(json['itemId'] as String);
      default:
        return const CarriedItem.none();
    }
  }

  @override
  Map<String, dynamic> toJson(CarriedItem object) => object.when(
    none: () => {'type': 'none'},
    key: (keyId) => {'type': 'key', 'keyId': keyId},
    crown: () => {'type': 'crown'},
    other: (itemId) => {'type': 'other', 'itemId': itemId},
  );
}

class PowerUpConverter implements JsonConverter<PowerUp, Map<String, dynamic>> {
  const PowerUpConverter();

  @override
  PowerUp fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'extraLives':
        return PowerUp.extraLives(count: json['count'] as int);
      case 'invulnerable':
        return PowerUp.invulnerable(
          framesRemaining: json['framesRemaining'] as int,
        );
      case 'jumpBoost':
        return PowerUp.jumpBoost(
          framesRemaining: json['framesRemaining'] as int,
        );
      case 'speedBoost':
        return PowerUp.speedBoost(
          framesRemaining: json['framesRemaining'] as int,
        );
      default:
        return PowerUp.extraLives(count: 0);
    }
  }

  @override
  Map<String, dynamic> toJson(PowerUp object) => object.when(
    extraLives: (count) => {'type': 'extraLives', 'count': count},
    invulnerable: (frames) => {
      'type': 'invulnerable',
      'framesRemaining': frames,
    },
    jumpBoost: (frames) => {'type': 'jumpBoost', 'framesRemaining': frames},
    speedBoost: (frames) => {'type': 'speedBoost', 'framesRemaining': frames},
  );
}

class RoomIdConverter implements JsonConverter<RoomId, String> {
  const RoomIdConverter();

  @override
  RoomId fromJson(String json) => RoomId(json);

  @override
  String toJson(RoomId object) => object.value;
}
