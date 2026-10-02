// Head over Heels had no keyboard, and the joystick pointed the wrong way.
//
// Two faults, one ticket each, and the second was hiding under the first.
//
// The joystick: `InputSystem._offsetToDirection` subtracted `pi/2` where it needed
// to add it. `Direction8.values` starts at north and counts clockwise, so
// `fromAngle` reads 0 as north and a screen offset is a quarter turn away from
// north. Subtracting pointed every direction at its opposite -- push up, the
// party walked south; push right, it walked west. The joystick has been
// backwards for as long as it has existed, and nothing caught it because nothing
// asserted which direction a push produced. The party moved and the frame
// changed, and those were the only two things anyone asked.
//
// The keyboard: there was none. The joystick and the on-screen buttons moved the
// party and no key did anything, so a player who reached for the arrow keys stood
// still in a room that was otherwise alive.
//
// What is tested here is the mapping, not the widget. The widget needs a real
// focus tree and a real key event stream; the mapping is where the arithmetic
// lives, and arithmetic is where this can be wrong in a way nobody notices.

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/state/input_system.dart';

import 'support/hoh_frame.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  directionOfAPush();
  directionFromHeldKeys();
  partyFollowsTheKeys();
}

/// Which direction a push actually produces.
///
/// "It moved" is not the claim. "It moved the way the control was pointed" is, and
/// only the second one fails when the mapping is a half turn out.
void directionOfAPush() {
  test('a push on the joystick names the direction it points at', () {
    final cases = <String, (Offset, Direction8)>{
      'up': (const Offset(0, -1), Direction8.north),
      'right': (const Offset(1, 0), Direction8.east),
      'down': (const Offset(0, 1), Direction8.south),
      'left': (const Offset(-1, 0), Direction8.west),
    };

    cases.forEach((name, pair) {
      expect(
        InputSystem.directionOfOffset(pair.$1),
        pair.$2,
        reason:
            'pushing $name must move the party ${pair.$2.name}, not '
            '${InputSystem.directionOfOffset(pair.$1)?.name}',
      );
    });
  });

  test('a diagonal push lands on the diagonal, not a cardinal', () {
    expect(
      InputSystem.directionOfOffset(const Offset(1, -1)),
      Direction8.northEast,
    );
  });

  test('a centred stick asks for nothing', () {
    expect(InputSystem.directionOfOffset(Offset.zero), isNull);
  });
}

void directionFromHeldKeys() {
  Offset? keys(List<LogicalKeyboardKey> held) =>
      InputSystem.directionFromKeys(held.toSet());

  group('one key, one direction', () {
    test('up is north, and W says the same thing', () {
      expect(keys([LogicalKeyboardKey.arrowUp])!.dy, lessThan(0));
      expect(keys([LogicalKeyboardKey.arrowUp])!.dx, 0);
      expect(keys([LogicalKeyboardKey.keyW])!.dy, lessThan(0));
    });

    test('down is south', () {
      expect(keys([LogicalKeyboardKey.arrowDown])!.dy, greaterThan(0));
      expect(keys([LogicalKeyboardKey.keyS])!.dy, greaterThan(0));
    });

    test('left is west', () {
      expect(keys([LogicalKeyboardKey.arrowLeft])!.dx, lessThan(0));
    });

    test('right is east', () {
      expect(keys([LogicalKeyboardKey.arrowRight])!.dx, greaterThan(0));
    });

    test('every direction key is recognised', () {
      for (final key in [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyD,
      ]) {
        expect(InputSystem.isDirectionKey(key), isTrue, reason: '$key');
      }
    });

    test('a key that is not a direction key is not one', () {
      expect(InputSystem.isDirectionKey(LogicalKeyboardKey.space), isFalse);
      expect(InputSystem.isDirectionKey(LogicalKeyboardKey.keyZ), isFalse);
    });
  });

  group('no key held means no direction', () {
    test('an empty set asks for nothing', () {
      // A party that keeps walking after the key is up is a party a player
      // cannot stop. Whether this system actually stops it is T090; this only
      // says the mapping reports "no direction", which is the first half.
      expect(keys([]), isNull);
    });
  });

  group('diagonals', () {
    test('up and right is north-east', () {
      final d = keys([
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowRight,
      ])!;

      expect(d.dx, greaterThan(0));
      expect(d.dy, lessThan(0));
    });

    test('a diagonal is not faster than a straight line', () {
      // A joystick cannot be pushed past its radius, so an unnormalised diagonal
      // would move at sqrt(2) times the speed. That reads as "diagonal movement
      // feels fast" and nothing else.
      final straight = keys([LogicalKeyboardKey.arrowUp])!;
      final diagonal = keys([
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowRight,
      ])!;

      expect(diagonal.distance, closeTo(straight.distance, 1e-9));
    });

    test('opposite keys cancel out', () {
      expect(
        keys([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]),
        isNull,
      );
      expect(
        keys([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowDown]),
        isNull,
      );
    });

    test('three keys still normalise', () {
      final d = keys([
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
      ])!;

      expect(d.dx, 0);
      expect(d.distance, closeTo(1.0, 1e-9));
    });
  });

  group('actions', () {
    test('space jumps, and Z does the same thing', () {
      expect(InputSystem.actionForKey(LogicalKeyboardKey.space), 'jump');
      expect(InputSystem.actionForKey(LogicalKeyboardKey.keyZ), 'jump');
    });

    test('carry, fire and swop each have a key', () {
      expect(InputSystem.actionForKey(LogicalKeyboardKey.keyX), 'carry');
      expect(InputSystem.actionForKey(LogicalKeyboardKey.keyV), 'fire');
      expect(InputSystem.actionForKey(LogicalKeyboardKey.tab), 'swop');
    });

    test('a direction key is not also an action', () {
      // Otherwise holding an arrow would jump on the way to walking.
      for (final key in [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyD,
      ]) {
        expect(InputSystem.actionForKey(key), isNull, reason: '$key');
      }
    });

    test('a key that is neither asks for nothing', () {
      expect(InputSystem.actionForKey(LogicalKeyboardKey.f1), isNull);
    });
  });
}

/// The party follows a key, measured through the real input path.
///
/// `room_render_test.dart` sets the position on the notifier directly, so it
/// never touches the input path -- which is the path this ticket is about.
///
/// The release half is deliberately absent. The party does not stop; that is
/// T090, with the measurement. Writing the assertion anyway would have meant
/// either a failing suite or a weaker claim than the one that turned out to be
/// true.
void partyFollowsTheKeys() {
  testWidgets('holding a key moves the party the way the key points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final loaded = await loadRealGame(tester);
    expect(loaded, isNotNull, reason: 'the game never finished loading');
    final game = loaded!;
    freeze(game.game);

    final input = game.container.read(inputSystemProvider);
    // The harness searches the game, the world and the room, because the party
    // has lived in all three over this project's history.
    final head = game.party.first;
    final start = head.gridPosition.clone();

    await withLoop(tester, game.game, () async {
      input.onJoystickDirection(
        InputSystem.directionFromKeys({LogicalKeyboardKey.arrowRight})!,
      );
    });
    game.game.resumeEngine();
    // Many frames, not one: `gridPosition` is integral, so a single 16ms frame
    // does not cross a tile boundary and a working key would look like a dead
    // one.
    await settle(tester, frames: 60);
    freeze(game.game);

    final moved = head.gridPosition;
    // ignore: avoid_print
    print('key east: ${start.x},${start.y} -> ${moved.x},${moved.y}');

    expect(
      moved.x > start.x,
      isTrue,
      reason:
          'the right arrow was held and the party did not go east: '
          '${start.x},${start.y} -> ${moved.x},${moved.y}',
    );
  });
}
