import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../storage/editor_storage.dart';
import '../tmx/tsx_catalog.dart';

/// Edits the type, the class and the properties of one tile.
///
/// A change is reported immediately as a new [TsxTileDefinition], so the caller
/// owns the tileset and decides when to write the file. Nothing is saved from
/// here: authoring a tileset and publishing it are two different decisions.
class TsxTileInspector extends StatefulWidget {
  const TsxTileInspector({
    super.key,
    required this.tile,
    required this.onChanged,
    this.onDeleted,
    this.onSave,
    this.onNew,
  });

  /// The tile being edited. Its id is fixed: a tile that changes id is another
  /// tile, and the list would reorder under the author.
  final TsxTileDefinition tile;

  final ValueChanged<TsxTileDefinition> onChanged;
  final VoidCallback? onDeleted;

  /// Writing the file and authoring another tileset live here, with the tile
  /// being described, rather than in a row of their own that competes with the
  /// browser for the panel's height.
  final VoidCallback? onSave;
  final VoidCallback? onNew;

  @override
  State<TsxTileInspector> createState() => _TsxTileInspectorState();
}

class _TsxTileInspectorState extends State<TsxTileInspector> {
  late final TextEditingController _type = TextEditingController(
    text: widget.tile.type,
  );
  late final TextEditingController _className = TextEditingController(
    text: widget.tile.className,
  );
  final TextEditingController _propertyName = TextEditingController();
  final TextEditingController _propertyValue = TextEditingController();

  @override
  void didUpdateWidget(TsxTileInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different tile is being inspected: the fields have to follow it rather
    // than keep what was typed for the last one.
    if (oldWidget.tile.id != widget.tile.id) {
      _type.text = widget.tile.type;
      _className.text = widget.tile.className;
    }
  }

  @override
  void dispose() {
    _type.dispose();
    _className.dispose();
    _propertyName.dispose();
    _propertyValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // The inspector sits in a panel whose width is decided outside, and a
    // scroll view hands its child an unbounded width unless it is told
    // otherwise: the fields below would grow to infinity without this.
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tile ${widget.tile.id}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('tile-type-field'),
              controller: _type,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'type',
                helperText: 'what the game looks up, such as floor or chest',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  widget.onChanged(widget.tile.copyWith(type: value.trim())),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('tile-class-field'),
              controller: _className,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'class',
                helperText: "Tiled's own field, kept apart from the type",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => widget.onChanged(
                widget.tile.copyWith(className: value.trim()),
              ),
            ),
            const SizedBox(height: 12),
            Text('properties', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            if (widget.tile.properties.isEmpty)
              const Text('none yet', style: TextStyle(fontSize: 12))
            else
              for (final entry in widget.tile.properties.entries)
                Row(
                  key: Key('tile-property-${entry.key}'),
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.key} = ${entry.value}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: Key('tile-property-remove-${entry.key}'),
                      tooltip: 'Remove $entry.key',
                      iconSize: 16,
                      onPressed: () => widget.onChanged(
                        widget.tile.withoutProperty(entry.key),
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
            const SizedBox(height: 8),
            // A wrap rather than a row: the panel is narrow and two fields with a
            // button do not always fit on one line.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    key: const Key('property-name-field'),
                    controller: _propertyName,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    key: const Key('property-value-field'),
                    controller: _propertyValue,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'value',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addProperty(),
                  ),
                ),
                IconButton(
                  key: const Key('add-property-button'),
                  tooltip: 'Add property',
                  onPressed: _addProperty,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (widget.onDeleted != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('delete-tile-button'),
                onPressed: widget.onDeleted,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove this tile'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  void _addProperty() {
    final name = _propertyName.text.trim();
    if (name.isEmpty) return;
    widget.onChanged(widget.tile.withProperty(name, _propertyValue.text));
    _propertyName.clear();
    _propertyValue.clear();
  }
}

/// Asks for the two things a new tileset needs, then measures its sheet.
///
/// The size is read from the image rather than typed, because a tileset whose
/// columns disagree with its sheet is the mistake this editor exists to stop.
class NewTilesetDialog extends StatefulWidget {
  const NewTilesetDialog({
    super.key,
    required this.storage,
    this.assetsBasePath = 'assets/sprites',
    this.tileSize = const Size(64, 32),
  });

  final EditorStorage storage;
  final String assetsBasePath;
  final Size tileSize;

  @override
  State<NewTilesetDialog> createState() => _NewTilesetDialogState();
}

class _NewTilesetDialogState extends State<NewTilesetDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _image = TextEditingController();
  String? _error;
  bool _measuring = false;

  @override
  void dispose() {
    _name.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New tileset'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('new-tileset-name'),
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'name',
              hintText: 'castle',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('new-tileset-image'),
            controller: _image,
            decoration: InputDecoration(
              labelText: 'sheet',
              hintText: 'tiles.png, relative to $assetsBaseHint',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _create(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiles are ${widget.tileSize.width.toInt()}x'
            '${widget.tileSize.height.toInt()}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const Key('new-tileset-error'),
              style: const TextStyle(color: Color(0xFFE57373), fontSize: 12),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('create-tileset-button'),
        onPressed: _measuring ? null : () => _create(context),
        child: const Text('Create'),
      ),
    ],
  );

  String get assetsBaseHint =>
      widget.assetsBasePath.isEmpty ? 'assets' : widget.assetsBasePath;

  /// Reads the sheet and hands back a tileset sized from it.
  Future<void> _create(BuildContext context) async {
    final name = _name.text.trim();
    final source = _image.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'The tileset needs a name');
      return;
    }
    if (source.isEmpty) {
      setState(() => _error = 'The tileset needs a sheet');
      return;
    }
    setState(() {
      _measuring = true;
      _error = null;
    });

    final key = _assetKey(source);
    try {
      if (!await widget.storage.exists(key)) {
        setState(() {
          _measuring = false;
          _error = 'No sheet at $key';
        });
        return;
      }
      final bytes = await widget.storage.readBinary(key);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final tileset = TsxTilesetDefinition.create(
        name: name,
        imageSource: source,
        imageWidth: image.width,
        imageHeight: image.height,
        tileWidth: widget.tileSize.width.toInt(),
        tileHeight: widget.tileSize.height.toInt(),
      );
      image.dispose();
      if (!context.mounted) return;
      Navigator.of(context).pop(tileset);
    } on ArgumentError catch (error) {
      setState(() {
        _measuring = false;
        _error = error.message?.toString() ?? 'That sheet holds no tile';
      });
    } catch (error) {
      setState(() {
        _measuring = false;
        _error = 'Could not read $key: $error';
      });
    }
  }

  /// Where the editor looks for a sheet, given what was typed.
  String _assetKey(String source) {
    if (source.startsWith('assets/')) return source;
    if (widget.assetsBasePath.isEmpty) return 'assets/$source';
    return '${widget.assetsBasePath}/$source';
  }
}

/// Shows what [TsxValidation] has to say, errors first.
class TsxProblems extends StatelessWidget {
  const TsxProblems({super.key, required this.validation});

  final TsxValidation validation;

  @override
  Widget build(BuildContext context) {
    if (validation.errors.isEmpty && validation.warnings.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      key: const Key('tsx-problems'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final error in validation.errors)
          Text(
            error,
            key: const Key('tsx-error'),
            style: const TextStyle(color: Color(0xFFE57373), fontSize: 11),
          ),
        for (final warning in validation.warnings)
          Text(
            warning,
            key: const Key('tsx-warning'),
            style: const TextStyle(color: Color(0xFFE0A24A), fontSize: 11),
          ),
      ],
    );
  }
}
