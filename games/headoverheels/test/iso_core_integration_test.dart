import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  test('root project resolves the iso_core package', () {
    final screen = gridToScreen(Vector3(2, 3, 0));
    final grid = screenToGrid(screen);

    expect(grid.x, 2);
    expect(grid.y, 3);
  });
}
