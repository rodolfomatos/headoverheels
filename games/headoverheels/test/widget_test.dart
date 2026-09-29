// The app's entry point: what a player sees first, and where the menu leads.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/features/ui/screens/main_menu_screen.dart';
import 'package:headoverheels/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The world is loaded from the asset bundle, so the binding has to exist before
  // anything reads it.
  TestWidgetsFlutterBinding.ensureInitialized();
  // The audio settings come from SharedPreferences, and the plugin is not there
  // to answer: without this the settings screen fails to build at all.
  SharedPreferences.setMockInitialValues({});

  Future<void> start(WidgetTester tester) async {
    // A menu tall enough to hold all of its buttons: at the test window's own
    // size the lower ones sit outside it, and a tap outside the window lands on
    // nothing.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: HohApp()));
    await tester.pump();
  }

  testWidgets('the app starts on the game menu, not on a demo page', (
    tester,
  ) async {
    // This file was the Flutter counter demo, start page and all: the game's
    // menu was unreachable and the routes it pushed to did not exist, so a web
    // build of this was a build of a demo.
    await start(tester);

    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('0'), findsNothing, reason: 'the counter is not the app');
  });

  testWidgets('New Game reaches the game', (tester) async {
    await start(tester);
    await tester.tap(find.text('New Game'));
    await tester.pump();
    // The world arrives through the bundle, and the screen shows the game once
    // it has.
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byKey(const Key('game-canvas')).evaluate().isNotEmpty) break;
    }

    expect(
      find.byKey(const Key('game-canvas')),
      findsOneWidget,
      reason: 'the menu led nowhere, or the world never arrived',
    );
  });

  testWidgets('the menu says what this is', (tester) async {
    // "Remastered for Android" claimed a remaster nobody made and a platform the
    // same build cannot know it is on: it serves the web and an APK.
    await start(tester);

    expect(find.text('Head over Heels'), findsOneWidget);
    expect(find.text(appSubtitle), findsOneWidget);
    expect(
      find.textContaining('Remastered'),
      findsNothing,
      reason: 'a port is not a remaster, and saying so is worth a check',
    );
  });

  testWidgets('the version the menu shows is the version the game has', (
    tester,
  ) async {
    // The version was written in the menu and in the pubspec, and nothing
    // compared them: a release would have shown the number it used to have.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^version: (\S+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!.split('+').first;

    expect(
      appVersion,
      declared,
      reason: 'the menu shows a version the pubspec does not have',
    );

    await start(tester);
    expect(find.text('Head over Heels v\$appVersion'), findsOneWidget);
  });

  testWidgets('Settings answers, with the settings the game reads', (
    tester,
  ) async {
    await start(tester);

    // The route by name, rather than a tap on the button: the menu's own
    // buttons are checked in a browser, where a finger lands where a person
    // puts it. What matters here is that the route the menu pushes to exists and
    // builds.
    Navigator.of(
      tester.element(find.byType(MainMenuScreen)),
    ).pushNamed('/settings');
    await tester.pumpAndSettle();

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
  });
}
