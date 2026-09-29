import 'dart:io';
import 'dart:typed_data';

/// The file system, for a build that has one.
///
/// Everything above this file is the same code whether or not there is a
/// directory: the storage, the paths, the shell. Only these four operations know
/// that a file exists at all.
class PlatformFileSystem {
  const PlatformFileSystem();

  Future<Uint8List?> readBytes(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  Future<void> writeBytes(String path, Uint8List bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<void> delete(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  Future<bool> exists(String path) => File(path).exists();
}

/// The instance the storage uses.
const PlatformFileSystem platformFileSystem = PlatformFileSystem();
