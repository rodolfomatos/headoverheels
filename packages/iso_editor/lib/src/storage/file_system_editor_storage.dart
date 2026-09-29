import 'dart:typed_data';

import 'editor_storage.dart';
import 'platform_file_system.dart';

/// An [EditorStorage] rooted at a directory on disk.
///
/// A project's keys are repository-relative: `games/headoverheels/assets/
/// levels/world.json`. Resolving them against a root is the whole of what an
/// editor needs to open a real project, and it is what the editor did not have:
/// the only storage was in memory, so picking a game in the picker changed
/// which keys the shell asked for and every one of them was missing. The Graph
/// tab had no world, the sprite browser had no sprites, and the palette had no
/// tileset, which is what an editor with no project looks like.
///
/// Writes go back to the files. That is the point of the editor: the map it
/// edits is the map the game loads.
class FileSystemEditorStorage implements EditorStorage {
  FileSystemEditorStorage(this.root);

  /// The directory every key is resolved against: the repository, for the two
  /// projects this repository ships.
  final String root;

  @override
  Future<String> readText(String key) async {
    final bytes = await readBinary(key);
    return String.fromCharCodes(bytes);
  }

  @override
  Future<void> writeText(String key, String value) =>
      writeBinary(key, Uint8List.fromList(value.codeUnits));

  @override
  Future<Uint8List> readBinary(String key) async {
    final bytes = await platformFileSystem.readBytes(_pathFor(key));
    if (bytes == null) {
      throw StateError(
        'Nothing at $key, under $root. Is this the repository root?',
      );
    }
    return bytes;
  }

  @override
  Future<void> writeBinary(String key, Uint8List value) async {
    await platformFileSystem.writeBytes(_pathFor(key), value);
  }

  @override
  Future<void> delete(String key) => platformFileSystem.delete(_pathFor(key));

  @override
  Future<bool> exists(String key) => platformFileSystem.exists(_pathFor(key));

  String _pathFor(String key) => '$root/$key';
}
