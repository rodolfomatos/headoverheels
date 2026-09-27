import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serves the game assets from disk so the production loading code can run in
/// a test without an asset bundle.
class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle({this.root = '.'});

  final String root;

  @override
  Future<ByteData> load(String key) async {
    final file = File('$root/$key');
    if (!file.existsSync()) {
      throw FlutterError('asset not found: $key');
    }
    final bytes = file.readAsBytesSync();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final file = File('$root/$key');
    if (!file.existsSync()) {
      throw FlutterError('asset not found: $key');
    }
    return file.readAsStringSync();
  }
}
