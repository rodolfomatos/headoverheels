import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide AssetManifest;
import 'package:iso_core/iso_core.dart';
import 'package:path/path.dart' as p;

import '../assets/asset_import_service.dart';
import '../assets/asset_manifest_service.dart';
import '../document/editor_document.dart';
import 'editor_project.dart';
import '../state/editor_controller.dart';
import '../storage/editor_file_gateway.dart';
import '../storage/editor_storage.dart';
import '../tmx/tmx_codec.dart';
import '../tmx/tsx_catalog.dart';
import '../views/map_editor_view.dart';
import '../views/sprite_manager.dart';
import '../views/tsx_authoring.dart';
import '../views/tsx_browser.dart';
import '../views/world_graph_panel.dart';

class IsoEditorApp extends StatefulWidget {
  const IsoEditorApp({
    required this.storage,
    this.initialDocument,
    this.manifest,
    this.assetsBasePath = 'assets/sprites',
    this.tilesets,
    this.tilesetImageBasePath = 'assets/tilesets',
    this.fileGateway,
    this.worldKey = 'assets/levels/world.json',
    this.project = EditorProject.headoverheels,
    this.projects = EditorProject.shipped,
    super.key,
  });

  final EditorStorage storage;
  final EditorDocument? initialDocument;
  final AssetManifest? manifest;
  final String assetsBasePath;
  final TsxCatalog? tilesets;
  final String tilesetImageBasePath;
  final EditorFileGateway? fileGateway;
  final String worldKey;

  /// The game the editor opens. The default keeps the old behaviour of reading
  /// [worldKey] only.
  final EditorProject project;

  /// The games offered in the picker.
  final List<EditorProject> projects;

  @override
  State<IsoEditorApp> createState() => _IsoEditorAppState();
}

class _IsoEditorAppState extends State<IsoEditorApp> {
  late final EditorController _controller;
  late final TsxCatalog _tilesets;
  late EditorProject _project;
  AssetManifest? _manifest;

  @override
  void initState() {
    super.initState();
    _controller = EditorController(
      storage: widget.storage,
      document: widget.initialDocument,
    );
    _tilesets = widget.tilesets ?? TsxCatalog(const []);
    _project = widget.project;
    _manifest = widget.manifest;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Opens [project]: its sprite manifest, and its world through the shell.
  Future<void> _openProject(EditorProject project) async {
    if (project.id == _project.id) return;
    setState(() => _project = project);
    final service = AssetManifestService(
      storage: widget.storage,
      manifestKey: project.manifestKey,
    );
    final manifest = await service.load();
    if (!mounted) return;
    setState(() => _manifest = manifest);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iso Editor',
      theme: ThemeData.dark(useMaterial3: true),
      home: EditorShell(
        controller: _controller,
        manifest: _manifest,
        assetsBasePath: widget.project.assetsBasePath,
        tilesets: _tilesets,
        tilesetImageBasePath: _project.tilesetImageBasePath,
        fileGateway: widget.fileGateway ?? const FileSelectorEditorGateway(),
        // Only the explicit argument wins: a caller that passes a world key is
        // pointing at a file of its own, not at one of the shipped projects.
        worldKey: widget.worldKey == EditorProject.headoverheels.worldKey
            ? _project.worldKey
            : widget.worldKey,
        project: _project,
        projects: widget.projects,
        onProjectChanged: _openProject,
      ),
    );
  }
}

class EditorShell extends StatefulWidget {
  const EditorShell({
    required this.controller,
    this.manifest,
    this.assetsBasePath = 'assets/sprites',
    this.tilesets,
    this.tilesetImageBasePath = 'assets/tilesets',
    this.fileGateway,
    this.worldKey = 'assets/levels/world.json',
    this.project = EditorProject.headoverheels,
    this.projects = EditorProject.shipped,
    this.onProjectChanged,
    super.key,
  });

  final EditorController controller;
  final AssetManifest? manifest;
  final String assetsBasePath;
  final TsxCatalog? tilesets;
  final String tilesetImageBasePath;
  final EditorFileGateway? fileGateway;
  final String worldKey;

  /// The game currently open, and the games the picker offers.
  final EditorProject project;
  final List<EditorProject> projects;

  /// Called when the player picks another game. The app owns reloading, because
  /// only it knows how to read the new world.
  final void Function(EditorProject project)? onProjectChanged;

  @override
  State<EditorShell> createState() => _EditorShellState();
}

/// Lets the player move between the games. Switching is the app's job, so this
/// only reports the choice.
class _ProjectPicker extends StatelessWidget {
  const _ProjectPicker({
    required this.projects,
    required this.current,
    required this.onChanged,
  });

  final List<EditorProject> projects;
  final EditorProject current;
  final void Function(EditorProject project) onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: const Key('project-picker'),
    tooltip: 'Game',
    onSelected: (id) => onChanged(EditorProject.byId(id)),
    itemBuilder: (context) => [
      for (final project in projects)
        PopupMenuItem<String>(
          value: project.id,
          child: Row(
            children: [
              if (project.id == current.id)
                const Icon(Icons.check, size: 16)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(project.label),
            ],
          ),
        ),
    ],
    child: Chip(
      label: Text(current.label),
      avatar: const Icon(Icons.sports_esports, size: 16),
    ),
  );
}

class _EditorShellState extends State<EditorShell> {
  /// The key of the project this shell is showing.
  String get projectId => widget.project.id;

  int _tileId = 1;
  String _objectType = 'entity';
  AssetManifest? _manifest;
  TsxCatalog? _tilesets;
  TsxTilesetDefinition? _tileset;

  EditorController get _controller => widget.controller;
  EditorFileGateway? get _fileGateway => widget.fileGateway;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
    _tilesets = widget.tilesets;
    _tileset = _tilesets?.tilesets.isEmpty ?? true
        ? null
        : _tilesets!.tilesets.first;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(_controller.document.projectName)),
                if (widget.projects.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _ProjectPicker(
                      projects: widget.projects,
                      current: widget.project,
                      onChanged: (project) =>
                          widget.onProjectChanged?.call(project),
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('undo-button'),
                tooltip: 'Undo',
                onPressed: _controller.canUndo ? _controller.undo : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: const Key('redo-button'),
                tooltip: 'Redo',
                onPressed: _controller.canRedo ? _controller.redo : null,
                icon: const Icon(Icons.redo),
              ),
              IconButton(
                key: const Key('import-tmx-button'),
                tooltip: 'Import TMX',
                onPressed: _importTmx,
                icon: const Icon(Icons.file_open_outlined),
              ),
              IconButton(
                key: const Key('export-tmx-button'),
                tooltip: 'Export TMX',
                onPressed: _exportTmx,
                icon: const Icon(Icons.save_outlined),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: const Key('save-button'),
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_controller.dirty ? 'Save*' : 'Save'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Row(
            children: [
              _ToolRail(
                tool: _controller.tool,
                tileId: _tileId,
                objectType: _objectType,
                onToolSelected: _controller.setTool,
                onTileChanged: (value) => setState(() => _tileId = value),
                onObjectTypeChanged: (value) {
                  setState(() => _objectType = value);
                },
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF181A1F),
                  child: MapEditorView(
                    document: _controller.document,
                    selectedTileId: _tileId,
                    tileset: _tileset,
                    resolveImagePath: _resolveTilesetImage,
                    onCellSelected: (position) {
                      _controller.applyCell(
                        CellAddress(position.x.round(), position.y.round()),
                        tileId: _tileId,
                        objectType: _objectType,
                      );
                    },
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 320,
                child: _InspectorPanel(
                  controller: _controller,
                  manifest: _manifest,
                  assetsBasePath: widget.assetsBasePath,
                  tilesets: _tilesets,
                  selectedTileId: _tileId,
                  onTileSelected: _selectPaletteTile,
                  onLoadTileset: _loadTilesetFromFile,
                  onNewTileset: _authorTileset,
                  onTileEdited: _editTile,
                  onTileDeleted: _deleteTile,
                  onSaveTileset: _saveTileset,
                  selectedTile: _selectedTile,
                  onImportSprite: _importSprite,
                  worldKey: widget.worldKey,
                  storage: _controller.storage,
                  onSaveAsset: _saveAsset,
                  onDeleteAsset: _deleteAsset,
                  onAddFrames: _addFrames,
                  projectId: projectId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    await _controller.save();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved ${_controller.documentKey}')));
  }

  Future<void> _importTmx() async {
    TmxCoordinateMode? mode;
    final gateway = _fileGateway;
    var source = gateway == null ? null : await _pickTmxSource();
    if (source == null) {
      if (!mounted) return;
      final result =
          await showDialog<({String source, TmxCoordinateMode mode})>(
            context: context,
            builder: (context) => const _TmxImportDialog(),
          );
      if (result == null) return;
      source = result.source;
      mode = result.mode;
    }
    try {
      final document = const TmxCodec().import(
        source,
        projectName: _controller.document.projectName,
        theme: _controller.document.theme,
        coordinateMode: mode ?? TmxCoordinateMode.tiledIsometric,
      );
      _controller.replaceDocument(document);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('TMX import failed: $error')));
    }
  }

  Future<String?> _pickTmxSource() async {
    final gateway = _fileGateway;
    if (gateway == null) return null;
    final file = await gateway.pickText(
      label: 'Tiled map',
      extensions: const ['tmx', 'xml'],
    );
    if (file == null) return null;
    return utf8.decode(file.bytes, allowMalformed: true);
  }

  Future<void> _exportTmx() async {
    try {
      final source = const TmxCodec().export(_controller.document);
      final name = '${_controller.document.projectName}.tmx'.replaceAll(
        ' ',
        '_',
      );
      final gateway = _fileGateway;
      if (gateway != null) {
        final path = await gateway.saveText(
          suggestedName: name,
          contents: source,
          label: 'Tiled map',
          extensions: const ['tmx'],
        );
        if (!mounted) return;
        if (path == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Export cancelled')));
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('TMX written to $path')));
        return;
      }
      await Clipboard.setData(ClipboardData(text: source));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TMX exported and copied to clipboard')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('TMX export failed: $error')));
    }
  }

  String _resolveTilesetImage(String imageSource) {
    if (imageSource.isEmpty) return '';
    if (imageSource.startsWith('http://') ||
        imageSource.startsWith('https://') ||
        imageSource.startsWith('data:')) {
      return imageSource;
    }
    final normalized = imageSource.startsWith('/')
        ? imageSource.substring(1)
        : imageSource;
    return p.posix.normalize(
      p.posix.join(widget.tilesetImageBasePath, normalized),
    );
  }

  void _selectPaletteTile(TsxTileDefinition tile) {
    setState(() {
      _tileId = tile.id;
      _tileset = _tilesets?.byName(_tileset?.name ?? '');
      if (tile.type.isNotEmpty) _objectType = tile.type;
    });
    _controller.setTool(EditorTool.tile);
  }

  /// The tile the inspector is editing, taken from the open tileset.
  TsxTileDefinition? get _selectedTile {
    final tileset = _tileset;
    if (tileset == null) return null;
    return tileset.tileOrNew(_tileId);
  }

  /// Puts an edited tile back into its tileset, as a new value.
  void _editTile(TsxTileDefinition tile) {
    final tileset = _tileset;
    if (tileset == null) return;
    setState(() {
      _tilesets = (_tilesets ?? TsxCatalog(const [])).upsert(
        tileset.upsertTile(tile),
      );
      _tileset = tileset.upsertTile(tile);
    });
  }

  void _deleteTile(int id) {
    final tileset = _tileset;
    if (tileset == null) return;
    setState(() {
      _tilesets = (_tilesets ?? TsxCatalog(const [])).upsert(
        tileset.removeTile(id),
      );
      _tileset = tileset.removeTile(id);
    });
  }

  /// Writes the open tileset back out as TSX.
  Future<void> _saveTileset() async {
    final tileset = _tileset;
    if (tileset == null) return;
    final validation = TsxValidation.of([tileset]);
    if (!validation.isValid) {
      _notify('Cannot save: ${validation.errors.first}');
      return;
    }
    final gateway = _fileGateway;
    if (gateway == null) {
      _notify('Configure a file gateway to save TSX tilesets');
      return;
    }
    final path = await gateway.saveText(
      suggestedName: '${tileset.name}.tsx',
      contents: tileset.toXmlString(),
      label: 'Tiled tileset',
      extensions: const ['tsx'],
    );
    if (path == null) return;
    _notify('Saved ${tileset.name}.tsx');
  }

  /// Authors a tileset from a sheet that is already in the project.
  Future<void> _authorTileset() async {
    final created = await showDialog<TsxTilesetDefinition>(
      context: context,
      builder: (context) => NewTilesetDialog(
        storage: _controller.storage,
        assetsBasePath: widget.project.assetsBasePath,
      ),
    );
    if (created == null) return;
    setState(() {
      _tilesets = (_tilesets ?? TsxCatalog(const [])).upsert(created);
      _tileset = created;
    });
    _notify('Authored ${created.name}: ${created.tileCount} tiles');
  }

  Future<void> _loadTilesetFromFile() async {
    final gateway = _fileGateway;
    if (gateway == null) {
      _notify('Configure a file gateway to load TSX tilesets');
      return;
    }
    final file = await gateway.pickText(
      label: 'Tiled tileset',
      extensions: const ['tsx'],
    );
    if (file == null) return;
    try {
      final tileset = TsxTilesetDefinition.parse(utf8.decode(file.bytes));
      setState(() {
        final existing = _tilesets?.tilesets ?? const <TsxTilesetDefinition>[];
        final without = existing
            .where((entry) => entry.name != tileset.name)
            .toList();
        _tilesets = TsxCatalog([...without, tileset]);
        _tileset = tileset;
        if (tileset.tiles.isNotEmpty) _tileId = tileset.tiles.first.id;
      });
      _notify('Loaded tileset ${tileset.name}');
    } catch (error) {
      _notify('TSX import failed: $error');
    }
  }

  Future<void> _importSprite() async {
    final gateway = _fileGateway;
    if (gateway == null) {
      _notify('Configure a file gateway to import sprites');
      return;
    }
    final request = await showDialog<AssetImportRequest>(
      context: context,
      builder: (context) => const _SpriteImportDialog(),
    );
    if (request == null) return;
    final file = await gateway.pickBinary(
      label: 'Sprite image',
      extensions: const ['png'],
    );
    if (file == null) return;
    final service = AssetImportService(
      storage: _controller.storage,
      manifestKey: '${widget.assetsBasePath}/manifest.yaml',
      assetsBasePath: widget.assetsBasePath,
    );
    try {
      await service.commit(
        bytes: file.bytes,
        fileName: file.name,
        request: request,
      );
      _manifest = await service.loadManifest();
      setState(() {});
      _notify('Imported ${request.subject}/${request.animation}');
    } catch (error) {
      _notify('Sprite import failed: $error');
    }
  }

  AssetManifestService get _manifestService => AssetManifestService(
    storage: _controller.storage,
    manifestKey: '${widget.assetsBasePath}/manifest.yaml',
  );

  AssetImportService get _importer => AssetImportService(
    storage: _controller.storage,
    manifestKey: '${widget.assetsBasePath}/manifest.yaml',
    assetsBasePath: widget.assetsBasePath,
  );

  Future<void> _saveAsset(AssetEntry entry) async {
    final manifest = _manifest;
    if (manifest == null) return;
    try {
      _manifest = await _manifestService.update(
        manifest,
        entry.id,
        (_) => entry,
      );
      setState(() {});
      _notify('Updated ${entry.id}');
    } catch (error) {
      _notify('Update failed: $error');
    }
  }

  Future<void> _deleteAsset(AssetEntry entry) async {
    final manifest = _manifest;
    if (manifest == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entry.id}?'),
        content: Text(
          'Removes the manifest entry${entry.frames == null ? '' : ' and frame files'}. '
          'The PNG files stay on disk unless you delete them manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-asset-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      _manifest = await _manifestService.remove(
        manifest,
        entry.id,
        deleteFrameFiles: true,
      );
      setState(() {});
      _notify('Removed ${entry.id}');
    } catch (error) {
      _notify('Delete failed: $error');
    }
  }

  Future<void> _addFrames(AssetEntry entry) async {
    final gateway = _fileGateway;
    if (gateway == null) {
      _notify('Configure a file gateway to add frames');
      return;
    }
    final files = await gateway.pickBinaries(
      label: 'Animation frames',
      extensions: const ['png'],
    );
    if (files.isEmpty) return;
    try {
      final updated = await _importer.appendFrames(
        entry: entry,
        frames: [
          for (final file in files) (name: file.name, bytes: file.bytes),
        ],
      );
      _manifest = await _manifestService.load();
      setState(() {});
      _notify('${updated.id} now has ${updated.frames} frame(s)');
    } catch (error) {
      _notify('Frame import failed: $error');
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ToolRail extends StatelessWidget {
  const _ToolRail({
    required this.tool,
    required this.tileId,
    required this.objectType,
    required this.onToolSelected,
    required this.onTileChanged,
    required this.onObjectTypeChanged,
  });

  final EditorTool tool;
  final int tileId;
  final String objectType;
  final ValueChanged<EditorTool> onToolSelected;
  final ValueChanged<int> onTileChanged;
  final ValueChanged<String> onObjectTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _ToolButton(
            key: const Key('tool-select'),
            icon: Icons.near_me_outlined,
            tooltip: 'Select',
            selected: tool == EditorTool.select,
            onPressed: () => onToolSelected(EditorTool.select),
          ),
          _ToolButton(
            key: const Key('tool-tile'),
            icon: Icons.grid_view_outlined,
            tooltip: 'Tile',
            selected: tool == EditorTool.tile,
            onPressed: () => onToolSelected(EditorTool.tile),
          ),
          _ToolButton(
            key: const Key('tool-object'),
            icon: Icons.category_outlined,
            tooltip: 'Object',
            selected: tool == EditorTool.object,
            onPressed: () => onToolSelected(EditorTool.object),
          ),
          _ToolButton(
            key: const Key('tool-spawn'),
            icon: Icons.flag_outlined,
            tooltip: 'Spawn',
            selected: tool == EditorTool.spawn,
            onPressed: () => onToolSelected(EditorTool.spawn),
          ),
          _ToolButton(
            key: const Key('tool-erase'),
            icon: Icons.delete_outline,
            tooltip: 'Erase',
            selected: tool == EditorTool.erase,
            onPressed: () => onToolSelected(EditorTool.erase),
          ),
          const Divider(),
          Text('Tile $tileId', style: Theme.of(context).textTheme.labelSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: tileId <= 0 ? null : () => onTileChanged(tileId - 1),
                icon: const Icon(Icons.remove, size: 16),
              ),
              IconButton(
                onPressed: () => onTileChanged(tileId + 1),
                icon: const Icon(Icons.add, size: 16),
              ),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              isExpanded: true,
              value: objectType,
              items: const [
                DropdownMenuItem(value: 'entity', child: Text('Entity')),
                DropdownMenuItem(value: 'door', child: Text('Door')),
                DropdownMenuItem(value: 'switch', child: Text('Switch')),
                DropdownMenuItem(value: 'spawn', child: Text('Spawn')),
              ],
              onChanged: (value) {
                if (value != null) onObjectTypeChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      style: selected
          ? IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            )
          : null,
      icon: Icon(icon),
    );
  }
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel({
    required this.controller,
    required this.manifest,
    required this.assetsBasePath,
    required this.tilesets,
    required this.selectedTileId,
    required this.onTileSelected,
    required this.onLoadTileset,
    required this.onNewTileset,
    required this.onTileEdited,
    required this.onTileDeleted,
    required this.onSaveTileset,
    required this.selectedTile,
    required this.onImportSprite,
    required this.worldKey,
    required this.storage,
    required this.onSaveAsset,
    required this.onDeleteAsset,
    required this.onAddFrames,
    required this.projectId,
  });

  final EditorController controller;
  final AssetManifest? manifest;
  final String assetsBasePath;

  /// Which game is open, so the graph panel reloads when it changes.
  final String projectId;

  final TsxCatalog? tilesets;
  final int selectedTileId;
  final ValueChanged<TsxTileDefinition> onTileSelected;
  final VoidCallback onLoadTileset;
  final VoidCallback onNewTileset;
  final ValueChanged<TsxTileDefinition> onTileEdited;
  final ValueChanged<int> onTileDeleted;
  final VoidCallback? onSaveTileset;

  /// The tile the inspector is editing.
  final TsxTileDefinition? selectedTile;
  final VoidCallback onImportSprite;
  final String worldKey;
  final EditorStorage storage;
  final Future<void> Function(AssetEntry entry) onSaveAsset;
  final Future<void> Function(AssetEntry entry) onDeleteAsset;
  final Future<void> Function(AssetEntry entry) onAddFrames;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Project'),
              Tab(text: 'Palette'),
              Tab(text: 'Sprites'),
              Tab(text: 'Graph'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Text(
                      controller.document.projectName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.document.width} × ${controller.document.height} · ${controller.document.theme}',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Layers',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (
                      var index = 0;
                      index < controller.document.layers.length;
                      index++
                    )
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(controller.document.layers[index].name),
                        value: controller.document.layers[index].visible,
                        onChanged: (value) {
                          controller.setLayerVisibility(index, value ?? true);
                        },
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Objects',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final object in controller.document.objects)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          object.name.isEmpty ? object.id : object.name,
                        ),
                        subtitle: Text(
                          '${object.type} (${object.position.x.toInt()}, ${object.position.y.toInt()})',
                        ),
                        selected: controller.selection == object.id,
                        onTap: () => controller.select(object.id),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: (tilesets == null || tilesets!.tilesets.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('No tilesets loaded'),
                              const SizedBox(height: 8),
                              FilledButton.tonalIcon(
                                key: const Key('load-tsx-button'),
                                onPressed: onLoadTileset,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Load TSX'),
                              ),
                              const SizedBox(height: 6),
                              FilledButton.tonalIcon(
                                key: const Key('new-tsx-button'),
                                onPressed: onNewTileset,
                                icon: const Icon(Icons.add),
                                label: const Text('New TSX'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            TsxProblems(validation: tilesets!.validation),
                            Expanded(
                              child: TsxBrowser(
                                key: const Key('tsx-browser'),
                                catalog: tilesets!,
                                selectedTileId: selectedTileId,
                                onTileSelected: onTileSelected,
                              ),
                            ),
                            const Divider(height: 1),
                            if (selectedTile != null)
                              TsxTileInspector(
                                key: ValueKey(
                                  'tsx-inspector:${selectedTile!.id}',
                                ),
                                tile: selectedTile!,
                                onChanged: onTileEdited,
                                onDeleted: () =>
                                    onTileDeleted(selectedTile!.id),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                FilledButton.tonalIcon(
                                  key: const Key('save-tsx-button'),
                                  onPressed: onSaveTileset == null
                                      ? null
                                      : () => onSaveTileset!(),
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('Save TSX'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  key: const Key('new-tsx-button'),
                                  onPressed: onNewTileset,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('New'),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              manifest == null
                                  ? 'No asset manifest loaded'
                                  : '${manifest!.assets.length} assets',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            key: const Key('import-sprite-button'),
                            onPressed: onImportSprite,
                            icon: const Icon(Icons.upload),
                            label: const Text('Import'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: manifest == null
                          ? const Center(
                              child: Text('Import a sprite to start'),
                            )
                          : SpriteManager(
                              manifest: manifest!,
                              assetsBasePath: assetsBasePath,
                              onImport: () async => onImportSprite(),
                              onSave: onSaveAsset,
                              onDelete: onDeleteAsset,
                              onAddFrames: onAddFrames,
                            ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  // Keyed on the game, so switching projects reads the new
                  // world instead of keeping the graph already in memory. The
                  // panel keeps its own stable key for anything looking for it.
                  child: KeyedSubtree(
                    key: ValueKey('world-graph-project:$projectId'),
                    child: WorldGraphPanel(
                      key: const Key('world-graph-panel'),
                      source: () => storage.readText(worldKey),
                      onSave: (json) => storage.writeText(worldKey, json),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpriteImportDialog extends StatefulWidget {
  const _SpriteImportDialog();

  @override
  State<_SpriteImportDialog> createState() => _SpriteImportDialogState();
}

class _SpriteImportDialogState extends State<_SpriteImportDialog> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _animation = TextEditingController(text: 'idle');
  String _category = 'entity';
  String _direction = 'down';
  String _alpha = AssetAlphaMode.opaque.name;

  @override
  void dispose() {
    _subject.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import sprite'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'entity', child: Text('Entity')),
                DropdownMenuItem(value: 'character', child: Text('Character')),
                DropdownMenuItem(value: 'prop', child: Text('Prop')),
                DropdownMenuItem(value: 'fx', child: Text('FX')),
                DropdownMenuItem(value: 'ui', child: Text('UI')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            TextField(
              key: const Key('sprite-subject-field'),
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject id'),
            ),
            TextField(
              controller: _animation,
              decoration: const InputDecoration(labelText: 'Animation'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _direction,
              decoration: const InputDecoration(labelText: 'Direction'),
              items: const [
                DropdownMenuItem(value: 'down', child: Text('down')),
                DropdownMenuItem(value: 'up', child: Text('up')),
                DropdownMenuItem(value: 'left', child: Text('left')),
                DropdownMenuItem(value: 'right', child: Text('right')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _direction = value);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _alpha,
              decoration: const InputDecoration(labelText: 'Alpha mode'),
              items: [
                for (final mode in AssetAlphaMode.values)
                  DropdownMenuItem(value: mode.name, child: Text(mode.name)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _alpha = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-sprite-import'),
          onPressed: () {
            final subject = _subject.text.trim();
            if (subject.isEmpty) return;
            Navigator.pop(
              context,
              AssetImportRequest(
                category: _category,
                subject: subject,
                animation: _animation.text.trim().isEmpty
                    ? 'idle'
                    : _animation.text.trim(),
                direction: _direction,
                alpha: AssetAlphaMode.values.firstWhere(
                  (mode) => mode.name == _alpha,
                ),
              ),
            );
          },
          child: const Text('Choose file'),
        ),
      ],
    );
  }
}

class _TmxImportDialog extends StatefulWidget {
  const _TmxImportDialog();

  @override
  State<_TmxImportDialog> createState() => _TmxImportDialogState();
}

class _TmxImportDialogState extends State<_TmxImportDialog> {
  final TextEditingController _source = TextEditingController();
  TmxCoordinateMode _mode = TmxCoordinateMode.tiledIsometric;

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import TMX'),
      content: SizedBox(
        width: 700,
        height: 500,
        child: Column(
          children: [
            DropdownButtonFormField<TmxCoordinateMode>(
              initialValue: _mode,
              decoration: const InputDecoration(
                labelText: 'Object coordinates',
              ),
              items: const [
                DropdownMenuItem(
                  value: TmxCoordinateMode.tiledIsometric,
                  child: Text('Tiled isometric projection'),
                ),
                DropdownMenuItem(
                  value: TmxCoordinateMode.grid,
                  child: Text('Grid multiplied by tile size'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _mode = value);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _source,
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: const InputDecoration(
                  hintText: 'Paste TMX XML here',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-tmx-import'),
          onPressed: _source.text.trim().isEmpty
              ? null
              : () =>
                    Navigator.pop(context, (source: _source.text, mode: _mode)),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
