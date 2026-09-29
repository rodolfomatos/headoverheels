// The entry point of Head over Heels.
//
// This was still the Flutter counter demo: the app started on a page with a
// counter, the game's own main menu was unreachable, and the routes the menu
// pushes to did not exist. A web build of this was a build of a demo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/features/ui/screens/game_screen.dart';
import 'package:headoverheels/features/ui/screens/main_menu_screen.dart';
import 'package:headoverheels/features/ui/screens/settings_screen.dart';
import 'package:headoverheels/features/ui/theme/app_theme.dart';

void main() {
  // ProviderScope: the game's state lives in providers, the characters and the
  // crowns among them, and a widget that reads one has nowhere to read it from
  // without this.
  runApp(const ProviderScope(child: HohApp()));
}

/// The routes the main menu navigates to.
class HohApp extends StatelessWidget {
  const HohApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Head over Heels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const MainMenuScreen(),
      routes: {
        '/game': (_) => const GameScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
