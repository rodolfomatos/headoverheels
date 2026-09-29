import 'dart:typed_data';

/// The file system, where there is one.
///
/// This is the build of [PlatformFileSystem] for a browser: there is no directory
/// to open and no file to write, so every operation says so in words a person can
/// act on, rather than failing later in a place that does not explain itself.
class PlatformFileSystem {
  const PlatformFileSystem();

  static const String cannotExplain =
      'A page in a browser cannot open a directory. The editor needs a place on '
      'disk to read and write a project: run it on a desktop, or point it at a '
      'project that is bundled with it.';

  Future<Uint8List?> readBytes(String path) async {
    throw UnsupportedError('$cannotExplain Asked for $path.');
  }

  Future<void> writeBytes(String path, Uint8List bytes) async {
    throw UnsupportedError('$cannotExplain Asked to write $path.');
  }

  Future<void> delete(String path) async {
    throw UnsupportedError('$cannotExplain Asked to delete $path.');
  }

  Future<bool> exists(String path) async => false;
}

/// The instance the storage uses.
const PlatformFileSystem platformFileSystem = PlatformFileSystem();
