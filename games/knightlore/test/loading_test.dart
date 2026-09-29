import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

import 'test_asset_bundle.dart';

/// The load, and what a player sees while it happens.
///
/// Knight Lore sat on "Loading the castle" for minutes with no way to tell
/// whether it was working: the art is forty-nine images and it decoded them one
/// at a time, and a load that *failed* said nothing at all, because the error was
/// drawn by an overlay that only appears once the assets are ready. These tests
/// hold both of those down.
class CountingBundle extends TestAssetBundle {
  CountingBundle({super.root});

  int inFlight = 0;
  int peakInFlight = 0;
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    inFlight++;
    if (inFlight > peakInFlight) peakInFlight = inFlight;
    // Long enough that overlapping loads are visible rather than accidental.
    await Future<void>.delayed(const Duration(milliseconds: 12));
    try {
      return await super.load(key);
    } finally {
      inFlight--;
    }
  }
}

/// A bundle whose world is not there, which is what a bad build looks like.
class MissingWorldBundle extends TestAssetBundle {
  MissingWorldBundle({super.root});

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == KnightLoreWorld.worldKey) {
      throw FlutterError('asset not found: $key');
    }
    return super.loadString(key, cache: cache);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  KnightLoreGame gameWith(TestAssetBundle bundle) {
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: bundle,
      audio: KnightLoreAudio()..startRecording(),
    );
    addTearDown(game.dispose);
    return game;
  }

  test('the art is decoded more than one image at a time', () async {
    // The art is forty-nine images. The browser fetched the first fifty assets in
    // five seconds and then the load crawled, two images every thirty seconds,
    // for as long as it took. Decoding is the work, and one at a time is a queue
    // with nothing in it.
    final bundle = CountingBundle();
    final game = gameWith(bundle);

    await game.onLoad();

    expect(game.assetsReady, isTrue,
        reason: game.error ?? 'the game did not load');
    expect(
      bundle.peakInFlight,
      greaterThan(1),
      reason: 'the images are still decoded one at a time: '
          '${bundle.loads} loads, never more than ${bundle.peakInFlight} open',
    );
  });

  test('a load that fails records what it was', () async {
    final game = gameWith(MissingWorldBundle());

    await game.onLoad();

    expect(game.assetsReady, isFalse);
    expect(game.error, isNotNull, reason: 'the failure was swallowed');
    expect(game.error, contains(KnightLoreWorld.worldKey));
  });

  testWidgets('a failed load shows the reason, not the loader', (tester) async {
    // The loader used to cover the error: the reason was drawn by the overlay,
    // and the overlay only appears once the assets are ready, so a game with a
    // missing world file waited for ever on "Loading the castle".
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = gameWith(MissingWorldBundle());
    await game.onLoad();

    await tester.pumpWidget(MaterialApp(home: KnightLoreScreen(game: game)));
    // Frames, not pumpAndSettle: the screen has a game in it with a running
    // ticker, and a tree with a ticker never settles.
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('The game could not load.'), findsOneWidget);
    expect(
      find.textContaining('Loading the castle'),
      findsNothing,
      reason: 'the loader is what a person stares at when nothing else says so',
    );
  });
}
