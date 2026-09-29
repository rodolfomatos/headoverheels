// Base puzzle entity component for Head over Heels.

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart' show BlendMode, Color, ColorFilter;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:headoverheels/core/assets/sprite_registry.dart';
import 'package:headoverheels/features/gameplay/game.dart';

/// Base class for all puzzle entities.
/// A puzzle entity, with the game that owns it.
///
/// The mixin is typed so an entity can reach the game's own API, `currentRoom`
/// and the pickup notifiers, instead of the untyped `game` it gets by default.
abstract class PuzzleEntity extends PositionComponent
    with CollisionCallbacks, HasGameReference<HeadOverHeelsGame> {
  final String id;
  final TriggerZone triggerZone;

  /// The sprite the manifest gave this entity, when it has one.
  SpriteComponent? _sprite;

  PuzzleEntity({required this.id, required this.triggerZone})
    : super(
        position: IsometricCoordinates.gridToScreen(triggerZone.position),
        size: Vector2(
          triggerZone.size.x * IsometricCoordinates.tileWidth,
          triggerZone.size.y * IsometricCoordinates.tileHeight,
        ),
        anchor: Anchor.center,
      );

  @override
  void onLoad() {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    super.onLoad();
  }

  /// Shows the sprite the manifest has for [entity], at this entity's own size.
  ///
  /// The entities used to draw a coloured rectangle instead: a red monster, a
  /// brown bag, a grey character on a grey floor. The art was in the manifest the
  /// whole time, loaded by the registry, and nothing asked for it.
  ///
  /// Returns null when the manifest has no sprite for the type, which is a hole
  /// in the art rather than a reason to invent a shape: `sprite_load_test` fails
  /// on a world whose entities the manifest has nothing for.
  Future<SpriteComponent?> showManifestSprite(String entity) async {
    await SpriteRegistry().loadEntity(entity);
    final sprite = SpriteRegistry().getEntitySprite(entity);
    if (sprite == null) return null;

    final component = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );
    add(component);
    _sprite = component;
    return component;
  }

  /// The sprite this entity is showing, if it has one.
  SpriteComponent? get spriteComponent => _sprite;

  /// Tints the sprite, which is how a state that used to be a coloured
  /// rectangle now shows: a frozen monster went red, a thrown switch went
  /// green, and a sleeping puppy woke up green.
  void tint(Color colour) {
    _sprite?.paint.colorFilter = ColorFilter.mode(colour, BlendMode.modulate);
  }

  /// Called when character interacts (presses action key while overlapping).
  void onInteract(CharacterComponent character);

  /// Called when character enters trigger zone.
  void onEnter(CharacterComponent character) {}

  /// Called when character exits trigger zone.
  void onExit(CharacterComponent character) {}

  /// Update logic (called every frame).
  void updatePuzzle(double dt) {}

  /// Called when a switch this entity is wired to is thrown.
  ///
  /// A hook rather than an interface: most puzzle entities do not care, and the
  /// ones that do override it.
  void onSwitchToggled(bool isOn, String switchId) {}
}
