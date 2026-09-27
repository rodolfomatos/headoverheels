import 'package:iso_core/iso_core.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

/// The traps of Knight Lore, as deterministic cycles over game ticks. The
/// renderer only needs to know whether a trap is out, so a hazard is a cell,
/// a period and an offset.
enum HazardKind {
  /// A ball lying in the room: always in the way, never moves.
  ball,

  /// Spikes that come out of the floor on a cycle.
  spikes,

  /// A block that drops from the ceiling and stays there for a while.
  fallingBlock,

  /// A block that falls, waits and goes back up.
  bouncingBlock,

  /// A demon that surfaces on a cycle and hurts whatever is under it.
  demon,
}

class Hazard {
  const Hazard({
    required this.id,
    required this.kind,
    required this.cell,
    this.period = 0,
    this.phase = 0,
    this.activeFor = 1,
    this.costsADay = true,
  });

  factory Hazard.fromTrigger(RoomTrigger trigger) {
    final properties = trigger.properties['properties'];
    int number(String key, int fallback) {
      if (properties is! Map) return fallback;
      final value = properties[key];
      return value is num ? value.toInt() : fallback;
    }

    final kind = switch (trigger.type) {
      'ball' => HazardKind.ball,
      'spikes' => HazardKind.spikes,
      'fallingBlock' => HazardKind.fallingBlock,
      'bouncingBlock' => HazardKind.bouncingBlock,
      'demon' => HazardKind.demon,
      _ => throw FormatException('not a hazard: ${trigger.type}'),
    };

    return Hazard(
      id: trigger.id,
      kind: kind,
      cell: trigger.position,
      period: number('period', 0),
      phase: number('phase', 0),
      activeFor: number('activeFor', 1),
      costsADay:
          properties is Map && properties['costsADay'] == false ? false : true,
    );
  }

  final String id;
  final HazardKind kind;
  final Vector3 cell;
  final int period;
  final int phase;
  final int activeFor;
  final bool costsADay;

  /// Whether the trap is out at [tick]. Static traps are always out.
  bool isOut(int tick) {
    if (kind == HazardKind.ball) return true;
    if (period <= 0) return true;
    final position = (tick - phase) % period;
    final normalised = position < 0 ? position + period : position;
    return normalised < activeFor;
  }

  /// A ball is furniture you cannot pass, not something that kills.
  bool get isBlocking => kind == HazardKind.ball;

  /// Whether the trap hurts the party at [tick].
  bool isLethal(int tick) => isOut(tick) && costsADay && !isBlocking;

  /// Whether the trap is in the way at [tick], lethal or not.
  bool covers(Vector3 position, int tick) =>
      isOut(tick) &&
      position.x.round() == cell.x.round() &&
      position.y.round() == cell.y.round();

  /// Whether the trap is simply in the way, which is all a ball ever does.
  bool blocks(Vector3 position, int tick) =>
      isBlocking ||
      (isOut(tick) &&
          position.x.round() == cell.x.round() &&
          position.y.round() == cell.y.round());
}

/// Every trap in one room, evaluated on a single tick counter so the game and
/// the tests agree on what is out.
class HazardField {
  HazardField(this.hazards);

  final List<Hazard> hazards;

  /// Traps that already caught the party. A trap fires once per visit, so
  /// standing on a spike for several ticks costs one day, not one per tick.
  final Set<String> _spent = {};

  factory HazardField.forRoom(RoomInfo room) => HazardField([
        for (final trigger in room.triggers)
          if (HazardKind.values.any(
            (kind) => kind.name == trigger.type,
          ))
            Hazard.fromTrigger(trigger),
      ]);

  bool get isEmpty => hazards.isEmpty;

  /// Only solid furniture blocks the way. Spikes, blocks and demons do not:
  /// they catch the party that walks into them, which is how the original
  /// behaves.
  bool blocksAt(Vector3 position, int tick) {
    for (final hazard in hazards) {
      if (hazard.isBlocking && hazard.covers(position, tick)) return true;
    }
    return false;
  }

  /// The trap that catches the party at [tick], if any.
  Hazard? hitAt(Vector3 position, int tick) {
    for (final hazard in hazards) {
      if (_spent.contains(hazard.id)) continue;
      if (hazard.isLethal(tick) && hazard.covers(position, tick)) return hazard;
    }
    return null;
  }

  /// Marks a trap as having fired for this visit.
  void spend(Hazard hazard) => _spent.add(hazard.id);

  /// Rearms every trap the party is not standing on.
  void rearm(Vector3 position) {
    _spent.removeWhere((id) {
      final hazard = byId(id);
      if (hazard == null) return true;
      return hazard.cell.x.round() != position.x.round() ||
          hazard.cell.y.round() != position.y.round();
    });
  }

  bool hasSpent(String id) => _spent.contains(id);

  Hazard? byId(String id) {
    for (final hazard in hazards) {
      if (hazard.id == id) return hazard;
    }
    return null;
  }
}
