import 'dart:typed_data';

abstract interface class EditorStorage {
  Future<String> readText(String key);
  Future<void> writeText(String key, String value);
  Future<Uint8List> readBinary(String key);
  Future<void> writeBinary(String key, Uint8List value);
  Future<void> delete(String key);
  Future<bool> exists(String key);
}

class MemoryEditorStorage implements EditorStorage {
  final Map<String, String> _text = {};
  final Map<String, Uint8List> _binary = {};

  @override
  Future<void> delete(String key) async {
    _text.remove(key);
    _binary.remove(key);
  }

  @override
  Future<bool> exists(String key) async =>
      _text.containsKey(key) || _binary.containsKey(key);

  @override
  Future<Uint8List> readBinary(String key) async {
    final value = _binary[key];
    if (value == null) throw StateError('Missing binary asset: $key');
    return Uint8List.fromList(value);
  }

  @override
  Future<String> readText(String key) async {
    final value = _text[key];
    if (value == null) throw StateError('Missing text asset: $key');
    return value;
  }

  @override
  Future<void> writeBinary(String key, Uint8List value) async {
    _binary[key] = Uint8List.fromList(value);
  }

  @override
  Future<void> writeText(String key, String value) async {
    _text[key] = value;
  }
}
