import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class EditorPickedFile {
  const EditorPickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

abstract interface class EditorFileGateway {
  Future<EditorPickedFile?> pickText({
    required String label,
    List<String> extensions,
  });
  Future<EditorPickedFile?> pickBinary({
    required String label,
    List<String> extensions,
  });
  Future<List<EditorPickedFile>> pickBinaries({
    required String label,
    List<String> extensions,
  });
  Future<String?> saveText({
    required String suggestedName,
    required String contents,
    required String label,
    List<String> extensions,
  });
}

class FileSelectorEditorGateway implements EditorFileGateway {
  const FileSelectorEditorGateway();

  @override
  Future<EditorPickedFile?> pickText({
    required String label,
    List<String> extensions = const [],
  }) async {
    final file = await openFile(
      acceptedTypeGroups: [
        _group(label, extensions, ['text/plain']),
      ],
    );
    if (file == null) return null;
    return EditorPickedFile(name: file.name, bytes: await file.readAsBytes());
  }

  @override
  Future<EditorPickedFile?> pickBinary({
    required String label,
    List<String> extensions = const [],
  }) async {
    final file = await openFile(
      acceptedTypeGroups: [_group(label, extensions, const [])],
    );
    if (file == null) return null;
    return EditorPickedFile(name: file.name, bytes: await file.readAsBytes());
  }

  @override
  Future<List<EditorPickedFile>> pickBinaries({
    required String label,
    List<String> extensions = const [],
  }) async {
    final files = await openFiles(
      acceptedTypeGroups: [_group(label, extensions, const [])],
    );
    return [
      for (final file in files)
        EditorPickedFile(name: file.name, bytes: await file.readAsBytes()),
    ];
  }

  @override
  Future<String?> saveText({
    required String suggestedName,
    required String contents,
    required String label,
    List<String> extensions = const [],
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        _group(label, extensions, ['text/plain']),
      ],
    );
    if (location == null) return null;
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(contents)),
      mimeType: 'text/plain',
      path: location.path,
      name: suggestedName,
    );
    await file.saveTo(location.path);
    return location.path;
  }

  XTypeGroup _group(
    String label,
    List<String> extensions,
    List<String> mimeTypes,
  ) {
    return XTypeGroup(
      label: label,
      extensions: extensions,
      mimeTypes: mimeTypes,
    );
  }
}

class MemoryEditorFileGateway implements EditorFileGateway {
  MemoryEditorFileGateway({this.textFile, this.binaryFile, this.binaryFiles});

  EditorPickedFile? textFile;
  EditorPickedFile? binaryFile;
  List<EditorPickedFile>? binaryFiles;
  final Map<String, String> savedText = {};

  @override
  Future<EditorPickedFile?> pickText({
    required String label,
    List<String> extensions = const [],
  }) async => textFile;

  @override
  Future<EditorPickedFile?> pickBinary({
    required String label,
    List<String> extensions = const [],
  }) async => binaryFile;

  @override
  Future<List<EditorPickedFile>> pickBinaries({
    required String label,
    List<String> extensions = const [],
  }) async => binaryFiles ?? const [];

  @override
  Future<String?> saveText({
    required String suggestedName,
    required String contents,
    required String label,
    List<String> extensions = const [],
  }) async {
    savedText[suggestedName] = contents;
    return suggestedName;
  }
}
