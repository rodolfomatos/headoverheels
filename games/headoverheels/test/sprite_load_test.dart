import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/core/assets/sprite_registry.dart';
import 'package:iso_core/iso_core.dart' show AssetEntry, AssetManifest;

/// The first frame, and what it waits for.
///
/// A game's first frame is the one a player stares at while nothing else has
/// happened yet, and this one waited for every sprite in the project: 65 images,
/// of which the room needs none. The registry loads per character and per
/// animation now, and these tests hold it to that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<AssetEntry>> manifest() async {
    final source = await rootBundle.loadString(manifestKey);
    return AssetManifest.fromYaml(source).assets;
  }

  group('what the first frame waits for', () {
    test('one animation of one character, not the whole manifest', () async {
      final entries = await manifest();
      final idle = entries
          .where(
            (entry) =>
                entry.character == 'head' &&
                entry.animation == SpriteRegistry.firstFrameAnimation,
          )
          .toList();
      final everything = entries.length;

      expect(idle, isNotEmpty, reason: 'the manifest has no idle animation');
      expect(
        idle.length,
        lessThan(everything),
        reason: 'asking for idle is asking for everything',
      );
    });

    test('the first frame needs no entity, prop or effect sprite', () async {
      // The room's entities, props and effects are not what holds the first
      // frame: they are what the rest of the manifest is for.
      final entries = await manifest();
      final firstFrame = entries
          .where((entry) => entry.character != null)
          .toList();
      final others = entries.where((entry) => entry.character == null).toList();

      expect(firstFrame, isNotEmpty);
      expect(
        others,
        isNotEmpty,
        reason: 'the manifest lists more than a party',
      );
      expect(
        firstFrame.any((entry) => entry.category != 'character'),
        isFalse,
        reason: 'a non-character entry is in the first frame\'s way',
      );
    });

    test('the first frame is a small share of the manifest', () async {
      // A number to notice when it grows: the party standing still is four
      // images, not sixty-five.
      final entries = await manifest();
      final firstFrame = entries
          .where(
            (entry) =>
                entry.character == 'head' &&
                entry.animation == SpriteRegistry.firstFrameAnimation,
          )
          .length;

      expect(firstFrame, lessThanOrEqualTo(4));
    });
  });

  group('the rest of the manifest', () {
    test('every file the manifest names is in the bundle', () async {
      // The registry fails loudly on a file that is not there, which turns a
      // silent black screen into a test failure. This is the check that the
      // files it will ask for are real.
      final entries = await manifest();
      for (final entry in entries) {
        final file = File('$spritesRoot/${entry.file}');
        expect(
          file.existsSync(),
          isTrue,
          reason: '${entry.id} names ${file.path}, and it is not there',
        );
      }
    });

    test('the manifest names every character the game has', () async {
      final entries = await manifest();
      for (final character in ['head', 'heels']) {
        expect(
          entries.any((entry) => entry.character == character),
          isTrue,
          reason: "the manifest has no sprites for $character",
        );
      }
    });
  });
}
