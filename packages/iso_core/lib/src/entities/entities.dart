import 'dart:collection';

import 'package:vector_math/vector_math.dart';

class EntityTypeDefinition {
  const EntityTypeDefinition({
    required this.id,
    required this.category,
    this.collidable = false,
    this.animated = false,
    this.metadata = const {},
  });

  final String id;
  final String category;
  final bool collidable;
  final bool animated;
  final Map<String, dynamic> metadata;
}

class EntityRegistry {
  EntityRegistry(Iterable<EntityTypeDefinition> types)
    : _types = UnmodifiableMapView({for (final type in types) type.id: type});

  final Map<String, EntityTypeDefinition> _types;

  Iterable<EntityTypeDefinition> get types => _types.values;
  bool contains(String id) => _types.containsKey(id);
  EntityTypeDefinition? getById(String id) => _types[id];
}

abstract class GameEntity {
  GameEntity({required this.id, required this.typeId, required this.position});

  final String id;
  final String typeId;
  Vector3 position;
  bool isActive = false;
  Map<String, dynamic> data = {};

  void updateEntity(double dt);

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': typeId,
    'position': [position.x, position.y, position.z],
    'is_active': isActive,
    'data': data,
  };
}

typedef EntityBuilder =
    GameEntity Function(
      String id,
      Vector3 position,
      Map<String, dynamic> properties,
    );

class EntityFactory {
  EntityFactory({EntityRegistry? registry})
    : registry = registry ?? EntityRegistry(const []);

  final EntityRegistry registry;
  final Map<String, EntityBuilder> _builders = {};

  void register(String typeId, EntityBuilder builder) {
    _builders[typeId] = builder;
  }

  bool canCreate(String typeId) => _builders.containsKey(typeId);

  GameEntity create(
    String id,
    String typeId,
    Vector3 position,
    Map<String, dynamic> properties,
  ) {
    final builder = _builders[typeId];
    if (builder == null) {
      throw StateError('No builder registered for entity type: $typeId');
    }
    return builder(id, position, properties);
  }
}

mixin TriggerableEntity on GameEntity {
  String? triggerTargetId;

  void onTrigger(String sourceTypeId);
}

mixin StatefulEntity on GameEntity {
  void setActive(bool active);
}

mixin AnimatedEntity on GameEntity {
  String currentAnimation = 'idle';
  int currentFrame = 0;
  double frameTimer = 0;

  void updateAnimation(double dt);
}
