import 'package:flutter/material.dart';
import 'package:iso_core/iso_core.dart';

import '../assets/asset_manifest_service.dart';
import 'sprite_animator.dart';

class SpriteManager extends StatefulWidget {
  const SpriteManager({
    required this.manifest,
    required this.assetsBasePath,
    required this.onSave,
    required this.onDelete,
    required this.onAddFrames,
    required this.onImport,
    super.key,
  });

  final AssetManifest manifest;
  final String assetsBasePath;
  final Future<void> Function(AssetEntry entry) onSave;
  final Future<void> Function(AssetEntry entry) onDelete;
  final Future<void> Function(AssetEntry entry) onAddFrames;
  final Future<void> Function() onImport;

  @override
  State<SpriteManager> createState() => _SpriteManagerState();
}

class _SpriteManagerState extends State<SpriteManager> {
  String? _selectedId;
  String _category = 'all';
  String _query = '';

  AssetEntry? get _selected => widget.manifest.getAsset(_selectedId ?? '');

  List<AssetEntry> get _visibleAssets {
    final query = _query.toLowerCase();
    return widget.manifest.assets
        .where((asset) {
          if (_category != 'all' && asset.category != _category) return false;
          if (query.isEmpty) return true;
          return asset.id.toLowerCase().contains(query) ||
              (asset.entity ?? '').toLowerCase().contains(query) ||
              (asset.character ?? '').toLowerCase().contains(query) ||
              (asset.animation ?? '').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  key: const Key('sprite-category-filter'),
                  isExpanded: true,
                  value: _category,
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All categories'),
                    ),
                    for (final category in const [
                      'character',
                      'entity',
                      'tile',
                      'prop',
                      'fx',
                      'ui',
                    ])
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                key: const Key('import-sprite-button'),
                onPressed: widget.onImport,
                icon: const Icon(Icons.upload),
                label: const Text('Import'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            key: const Key('sprite-search-field'),
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'filter by id, subject or animation',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: _visibleAssets.isEmpty
              ? const Center(child: Text('No assets match'))
              : ListView.builder(
                  itemCount: _visibleAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _visibleAssets[index];
                    final frames = AssetManifestService.frameFilesOf(
                      asset,
                    ).length;
                    return ListTile(
                      key: Key('asset-tile-${asset.id}'),
                      dense: true,
                      selected: asset.id == _selectedId,
                      title: Text(asset.id, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${asset.category} · ${asset.width}×${asset.height} · '
                        '${frames == 0 ? 1 : frames} frame(s)'
                        '${(asset.frames ?? 1) > 1 && frames != asset.frames ? ' · mismatch' : ''}',
                      ),
                      onTap: () => setState(() => _selectedId = asset.id),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _selected == null
              ? const Center(child: Text('Select an asset to inspect'))
              : _AssetDetails(
                  key: ValueKey(_selected!.id),
                  entry: _selected!,
                  assetsBasePath: widget.assetsBasePath,
                  onSave: widget.onSave,
                  onDelete: widget.onDelete,
                  onAddFrames: widget.onAddFrames,
                ),
        ),
      ],
    );
  }
}

class _AssetDetails extends StatefulWidget {
  const _AssetDetails({
    required this.entry,
    required this.assetsBasePath,
    required this.onSave,
    required this.onDelete,
    required this.onAddFrames,
    super.key,
  });

  final AssetEntry entry;
  final String assetsBasePath;
  final Future<void> Function(AssetEntry entry) onSave;
  final Future<void> Function(AssetEntry entry) onDelete;
  final Future<void> Function(AssetEntry entry) onAddFrames;

  @override
  State<_AssetDetails> createState() => _AssetDetailsState();
}

class _AssetDetailsState extends State<_AssetDetails> {
  late final TextEditingController _width;
  late final TextEditingController _height;
  late final TextEditingController _anchorX;
  late final TextEditingController _anchorY;
  late final TextEditingController _frames;
  late final TextEditingController _frameDuration;
  late final TextEditingController _palette;
  late String _alpha;
  late String _paletteValue;
  late bool _loop;

  @override
  void initState() {
    super.initState();
    _width = TextEditingController(text: '${widget.entry.width}');
    _height = TextEditingController(text: '${widget.entry.height}');
    _anchorX = TextEditingController(text: '${widget.entry.anchorX}');
    _anchorY = TextEditingController(text: '${widget.entry.anchorY}');
    _frames = TextEditingController(text: '${widget.entry.frames ?? 1}');
    _frameDuration = TextEditingController(
      text: '${widget.entry.frameDuration ?? 100}',
    );
    _palette = TextEditingController(text: widget.entry.palette);
    _alpha = widget.entry.alpha;
    _paletteValue = widget.entry.palette;
    _loop = widget.entry.loop ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _width,
      _height,
      _anchorX,
      _anchorY,
      _frames,
      _frameDuration,
      _palette,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text(entry.id, style: Theme.of(context).textTheme.titleSmall),
        Text(
          entry.file,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        SpriteAnimator(entry: entry, assetsBasePath: widget.assetsBasePath),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numberField('width', _width)),
            const SizedBox(width: 8),
            Expanded(child: _numberField('height', _height)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numberField('anchor x', _anchorX)),
            const SizedBox(width: 8),
            Expanded(child: _numberField('anchor y', _anchorY)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numberField('frames', _frames)),
            const SizedBox(width: 8),
            Expanded(child: _numberField('frame ms', _frameDuration)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('asset-alpha-field'),
          initialValue: _alpha,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true, labelText: 'alpha'),
          items: [
            for (final mode in AssetAlphaMode.values)
              DropdownMenuItem(value: mode.name, child: Text(mode.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _alpha = value);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('asset-palette-field'),
                controller: _palette,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'palette',
                ),
                onChanged: (value) => _paletteValue = value,
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              key: const Key('asset-loop-chip'),
              label: const Text('loop'),
              selected: _loop,
              onSelected: (value) => setState(() => _loop = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('asset-save-button'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
            OutlinedButton.icon(
              key: const Key('asset-frames-button'),
              onPressed: () => widget.onAddFrames(widget.entry),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add frames'),
            ),
            IconButton(
              key: const Key('asset-delete-button'),
              tooltip: 'Delete asset',
              onPressed: () => widget.onDelete(widget.entry),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return TextField(
      key: Key('asset-field-$label'),
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(isDense: true, labelText: label),
    );
  }

  Future<void> _save() async {
    await widget.onSave(
      widget.entry.copyWith(
        runtimeSize: {
          'width': int.tryParse(_width.text) ?? widget.entry.width,
          'height': int.tryParse(_height.text) ?? widget.entry.height,
        },
        anchor: {
          'x': int.tryParse(_anchorX.text) ?? widget.entry.anchorX,
          'y': int.tryParse(_anchorY.text) ?? widget.entry.anchorY,
        },
        frames: int.tryParse(_frames.text) ?? widget.entry.frames,
        frameDuration:
            int.tryParse(_frameDuration.text) ?? widget.entry.frameDuration,
        alpha: _alpha,
        palette: _paletteValue,
        loop: _loop,
      ),
    );
  }
}
