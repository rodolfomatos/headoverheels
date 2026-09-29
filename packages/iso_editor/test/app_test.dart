// The editor as an application, which it was not until recently.
//
// The editor was a library: the shell, the palette, the sprite browser and the
// TSX authoring view all existed and all were tested, and nothing put them on a
// screen. `flutter create` added a test for a counter that never ran, and this
// replaces it with one for the thing that does.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iso_editor/iso_editor.dart';
import 'package:iso_editor/main.dart';

void main() {
  testWidgets('the editor opens on its shell, with both games to pick', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const EditorApp());
    await tester.pumpAndSettle();

    expect(find.byType(EditorShell), findsOneWidget);
    // The picker names the game it has open, and the menu names the other one:
    // an editor that cannot open a project is a widget.
    expect(find.textContaining('Head over Heels'), findsWidgets);

    // The picker has a key of its own, which is what the shell tests use too.
    await tester.tap(find.byKey(const Key('project-picker')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Knight Lore'), findsWidgets);
  });
}
