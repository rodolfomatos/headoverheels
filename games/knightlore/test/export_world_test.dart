import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';

/// Regenerates `assets/world/knightlore_world.json` from [KnightLoreWorld.build]
/// and fails loudly if the world is not valid. Run with `flutter test`.
void main() {
  test('exports the world definition and keeps it valid', () {
    final graph = KnightLoreWorld.build();
    final validation = validateWorld(graph);
    expect(validation.errors, isEmpty, reason: '${validation.issues}');

    final file = File(KnightLoreWorld.worldKey);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(graph.toJsonString());
    expect(
      file.readAsStringSync(),
      graph.toJsonString(),
      reason: 'world json drifted from KnightLoreWorld.build()',
    );
    expect(
      WorldGraph.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      ).rooms,
      hasLength(graph.rooms.length),
      reason: 'the exported file must parse back into the same world',
    );
  });
}
