// The map editor, as an application.
//
// The editor was a library with no way to run: the shell, the palette, the
// sprite browser and the TSX browser all existed and all were tested, and
// nothing put them on a screen. Then it had an entry point with an in-memory
// project, which is an editor that opens an empty room and cannot find the world
// it is meant to be editing. A project's keys are repository-relative, so the
// whole of what a project needs is a directory to resolve them against, and the
// person using the editor says which one.
import 'package:file_selector/file_selector.dart';
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
      home: const EditorHome(),
    );
  }
}

/// Asks for a repository, and opens a project in it.
class EditorHome extends StatefulWidget {
  const EditorHome({this.pickDirectory, super.key});

  /// How the person says where their projects are.
  ///
  /// `getDirectoryPath` opens a native dialog, which a test cannot drive and
  /// which a page in a browser does not have. Taking it as a parameter is what
  /// lets the flow be tested at all: ask, choose, open.
  final Future<String?> Function()? pickDirectory;

  @override
  State<EditorHome> createState() => EditorHomeState();
}

class EditorHomeState extends State<EditorHome> {
  /// Where the projects are: the directory every key is resolved against.
  String? _root;

  /// Opens a project in [root].
  void _open(String root) => setState(() => _root = root);

  EditorController _controllerFor(String root) =>
      EditorController(storage: FileSystemEditorStorage(root));

  @override
  Widget build(BuildContext context) {
    final root = _root;
    if (root == null) {
      return _ChooseProject(
        onChosen: _open,
        pickDirectory: widget.pickDirectory ?? getDirectoryPath,
      );
    }
    return EditorShell(
      controller: _controllerFor(root),
      // Reading and writing Tiled files, with the person choosing which.
      fileGateway: const FileSelectorEditorGateway(),
    );
  }
}

/// The first thing the editor asks for, because an editor with nowhere to look
/// is the empty room this replaced.
class _ChooseProject extends StatelessWidget {
  const _ChooseProject({required this.onChosen, required this.pickDirectory});

  /// Where the person said their projects are.
  final ValueChanged<String> onChosen;

  /// How that question is asked.
  final Future<String?> Function() pickDirectory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Open a project',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the directory the projects live in — the repository — and '
                'every project in it can be opened. Editing a project writes to '
                'its files.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('choose-project-directory'),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Choose directory'),
                onPressed: () async {
                  final chosen = await pickDirectory();
                  if (chosen == null || !context.mounted) return;
                  onChosen(chosen);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
