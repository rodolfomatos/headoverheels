// The editor as an application, which it was not until recently.
//
// The editor was a library: the shell, the palette, the sprite browser and the
// TSX authoring view all existed and all were tested, and nothing put them on a
// screen. It had an entry point that opened an empty room and could not find the
// world it was meant to be editing, and it now asks where the projects are
// before it opens one. This drives the whole flow: ask, choose, open.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iso_editor/iso_editor.dart';
import 'package:iso_editor/main.dart';

void main() {
  testWidgets('the editor asks where the projects are, then opens one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The directory chooser opens a native dialog, so the flow is driven with
    // the answer rather than the dialog.
    await tester.pumpWidget(
      MaterialApp(
        home: EditorHome(pickDirectory: () async => '/tmp/iso-editor-test'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EditorShell), findsNothing);
    expect(find.text('Open a project'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choose-project-directory')));
    await tester.pumpAndSettle();

    expect(
      find.byType(EditorShell),
      findsOneWidget,
      reason: 'choosing a project did not open the editor',
    );
    // The picker names the game it has open, and the menu the other one: an
    // editor that cannot open a project is a widget.
    expect(find.textContaining('Head over Heels'), findsWidgets);

    await tester.tap(find.byKey(const Key('project-picker')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Knight Lore'), findsWidgets);
  });
}
