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

  /// The component showing this entity's art, when it has one.
  PositionComponent? _art;

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

  /// Shows the art the manifest has for [entity], at this entity's own size.
  ///
  /// The entities used to draw a coloured rectangle instead: a red monster, a
  /// brown bag, a grey character on a grey floor. The art was in the manifest the
  /// whole time, loaded by the registry, and nothing asked for it.
  ///
  /// Where the art is a strip, as most of it is, this shows the animation: a
  /// monster is eight frames wide and can walk. Where it is one image, a key or
  /// a crown, it shows the image and stays still, which is what it is.
  ///
  /// Returns null when the manifest has no sprite for the type, which is a hole
  /// in the art rather than a reason to invent a shape: `sprite_load_test` fails
  /// on a world whose entities the manifest has nothing for.
  Future<PositionComponent?> showManifestSprite(String entity) async {
    final registry = SpriteRegistry();
    await registry.loadEntity(entity);

    // The art is centred in this entity's box, and the box is centred on the
    // trigger's position. Both used to be `Anchor.center` on top of each other,
    // so every entity was drawn at `position - size`: a whole tile up and to the
    // left of where the world says it is. Measured: 12 of the room's 16
    // entities drew 0 pixels, and the four that drew anything were the four
    // whose world x happened to be large enough to survive it.
    final centre = size / 2;

    final animation = registry.getEntityAnimation(entity);
    if (animation != null) {
      final component = SpriteAnimationComponent(
        animation: animation,
        position: centre,
        size: size,
        anchor: Anchor.center,
      );
      add(component);
      _art = component;
      return component;
    }

    final sprite = registry.getEntitySprite(entity);
    if (sprite == null) return null;
    final component = SpriteComponent(
      sprite: sprite,
      position: centre,
      size: size,
      anchor: Anchor.center,
    );
    add(component);
    _art = component;
    return component;
  }

  /// Shows the prop the manifest has for [prop], at this entity's own size.
  ///
  /// Props are a separate list in the manifest from entities — a crate is a prop
  /// and a monster is an entity — and until the registry indexed them an entity
  /// that wanted a prop got nothing at all, silently, which is how the
  /// dispensary stood in a room as an absence.
  Future<PositionComponent?> showManifestProp(String prop) async {
    final registry = SpriteRegistry();
    await registry.loadProp(prop);
    final sprite = registry.getPropSprite(prop);
    if (sprite == null) return null;
    final component = SpriteComponent(
      sprite: sprite,
      position: size / 2,
      size: size,
      anchor: Anchor.center,
    );
    add(component);
    _art = component;
    return component;
  }

  /// What this entity is showing, the sprite or the animation.
  PositionComponent? get spriteComponent => _art;

  /// Tints the sprite, which is how a state that used to be a coloured
  /// rectangle now shows: a frozen monster went red, a thrown switch went
  /// green, and a sleeping puppy woke up green.
  ///
  /// A transparent colour is not "no tint", it is a filter that multiplies
  /// everything by zero. `BlendMode.modulate` multiplies the alpha as well as
  /// the colour, so tinting with `Colors.transparent` erased the sprite
  /// completely: a switch that had not been thrown drew nothing at all, and
  /// the tint was the only reason.
  void tint(Color? colour) {
    // Both kinds of art hold a paint: a SpriteComponent has one, and a
    // SpriteAnimationComponent is a PositionComponent that does too.
    if (_art is! HasPaint) return;
    (_art! as HasPaint).paint.colorFilter = colour == null
        ? null
        : ColorFilter.mode(colour, BlendMode.modulate);
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
