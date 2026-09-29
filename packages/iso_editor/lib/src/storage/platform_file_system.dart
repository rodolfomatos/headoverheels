// The file system, or the reason there is not one.
//
// A browser has no directory to open and no file to write. Everything above this
// file — the storage, the paths, the shell — is the same code on both sides;
// these four operations are what knows whether a file exists at all.
export 'platform_file_system_stub.dart'
    if (dart.library.io) 'platform_file_system_io.dart';
