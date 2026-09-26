import 'dart:collection';

import 'package:vector_math/vector_math.dart';

import '../isometric/isometric.dart';

enum GameAction { jump, interact, fire, carry, switchCharacter, pause }

class InputState {
  InputState({Vector2? move, Set<GameAction>? actions})
    : move = move ?? Vector2.zero(),
      actions = UnmodifiableSetView(actions ?? <GameAction>{});

  final Vector2 move;
  final Set<GameAction> actions;

  bool isPressed(GameAction action) => actions.contains(action);

  bool get hasMoveInput => move.length2 > 0.01;

  Direction8? get direction {
    if (!hasMoveInput) return null;
    return Direction8.fromVector(move);
  }

  InputState copyWith({Vector2? move, Set<GameAction>? actions}) {
    return InputState(
      move: move ?? this.move,
      actions: actions ?? this.actions.toSet(),
    );
  }
}

abstract interface class InputSource {
  InputState get state;
  Stream<InputState> get changes;
  void dispose();
}

class InputRouter {
  final List<InputSource> _sources = [];

  void add(InputSource source) => _sources.add(source);
  void remove(InputSource source) => _sources.remove(source);
  void clear() => _sources.clear();

  InputState get state {
    var move = Vector2.zero();
    final actions = <GameAction>{};
    for (final source in _sources) {
      final sourceState = source.state;
      if (move.length2 <= sourceState.move.length2) {
        move = sourceState.move;
      }
      actions.addAll(sourceState.actions);
    }
    return InputState(move: move, actions: actions);
  }
}
