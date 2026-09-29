// The map editor, as an application.
//
// The editor was a library with no way to run: the shell, the palette, the
// sprite manager and the TSX browser all existed and all were tested, and
// nothing put them on a screen. That is the same gap the other entry point in
// this project had, where a demo stood where the game should have been.
//
// What it does not do yet: keep anything. [MemoryEditorStorage] holds the map in
// the page, so closing the page loses the work, and the editor can read and write
// Tiled files through its file gateway but has nowhere to keep a project. That is
// the next thing the editor needs, and it is written down rather than implied.
import 'package:flutter/material.dart';
import 'package:iso_editor/iso_editor.dart';

void main() {
  runApp(const EditorApp());
}

/// The editor, with both of the repository's games in its picker.
class EditorApp extends StatelessWidget {
  const EditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iso Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C8BF5)),
        useMaterial3: true,
      ),
      home: _EditorHome(),
    );
  }
}

class _EditorHome extends StatefulWidget {
  const _EditorHome();

  @override
  State<_EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends State<_EditorHome> {
  final EditorController _controller = EditorController(
    storage: MemoryEditorStorage(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorShell(
      controller: _controller,
      // Reading and writing Tiled files, with the person choosing which.
      fileGateway: const FileSelectorEditorGateway(),
    );
  }
}
