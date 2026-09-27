import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iso_editor/iso_editor.dart';

void main() {
  testWidgets('the inspector alone reports an edited property', (tester) async {
    tester.view.physicalSize = const Size(420, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final changes = <TsxTileDefinition>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TsxTileInspector(
            tile: const TsxTileDefinition(
              id: 0,
              type: 'floor',
              properties: {'cost': 1},
            ),
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('property-name-field')),
      'deep',
    );
    await tester.enterText(
      find.byKey(const Key('property-value-field')),
      'true',
    );
    await tester.ensureVisible(find.byKey(const Key('add-property-button')));
    await tester.tap(find.byKey(const Key('add-property-button')));
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty, reason: 'nothing was reported');
    expect(changes.last.properties['deep'], 'true');
    expect(changes.last.properties['cost'], 1, reason: 'the old one survived');
  });
}
