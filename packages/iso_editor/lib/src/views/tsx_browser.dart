import 'package:flutter/material.dart';

import '../tmx/tsx_catalog.dart';

class TsxBrowser extends StatefulWidget {
  const TsxBrowser({
    super.key,
    required this.catalog,
    this.selectedTileId,
    this.onTileSelected,
    this.resolveImagePath,
    this.maximumVisibleTiles = 512,
  });

  final TsxCatalog catalog;
  final int? selectedTileId;
  final ValueChanged<TsxTileDefinition>? onTileSelected;
  final String Function(String imageSource)? resolveImagePath;
  final int maximumVisibleTiles;

  @override
  State<TsxBrowser> createState() => _TsxBrowserState();
}

class _TsxBrowserState extends State<TsxBrowser> {
  int _tilesetIndex = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (widget.catalog.tilesets.isEmpty) {
      return const Center(child: Text('No TSX tilesets loaded'));
    }
    final index = _tilesetIndex.clamp(0, widget.catalog.tilesets.length - 1);
    final tileset = widget.catalog.tilesets[index];
    final tiles = _filteredTiles(tileset);
    // The panel can be short, and a fixed header plus a grid does not fit in a
    // box of nothing. Below this the search box goes rather than the layout
    // overflowing.
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy = constraints.maxHeight >= 130;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.catalog.tilesets.length > 1)
              DropdownButton<int>(
                value: index,
                isDense: true,
                onChanged: (value) =>
                    setState(() => _tilesetIndex = value ?? 0),
                items: [
                  for (var i = 0; i < widget.catalog.tilesets.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(widget.catalog.tilesets[i].name),
                    ),
                ],
              ),
            if (roomy)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                    hintText: 'tile id or type',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
            Text(
              '${tileset.name}: ${tileset.tileCount} tiles, '
              '${tileset.tileWidth}x${tileset.tileHeight}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: tiles.isEmpty
                  ? const Center(child: Text('No tiles match'))
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final tile in tiles)
                            _TileCell(
                              tile: tile,
                              tileset: tileset,
                              selected: widget.selectedTileId == tile.id,
                              imagePath: widget.resolveImagePath?.call(
                                tileset.imageSource,
                              ),
                              onTap: widget.onTileSelected == null
                                  ? null
                                  : () => widget.onTileSelected!(tile),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<TsxTileDefinition> _filteredTiles(TsxTilesetDefinition tileset) {
    final all = tileset.tiles.isEmpty
        ? [
            for (var id = 0; id < tileset.tileCount; id++)
              TsxTileDefinition(
                id: id,
                type: '',
                className: '',
                properties: const {},
              ),
          ]
        : tileset.tiles;
    if (_query.isEmpty) {
      return all.take(widget.maximumVisibleTiles).toList();
    }
    return all
        .where(
          (tile) =>
              tile.id.toString().contains(_query) ||
              tile.type.toLowerCase().contains(_query) ||
              tile.className.toLowerCase().contains(_query),
        )
        .take(widget.maximumVisibleTiles)
        .toList();
  }
}

class _TileCell extends StatelessWidget {
  const _TileCell({
    required this.tile,
    required this.tileset,
    required this.selected,
    required this.imagePath,
    required this.onTap,
  });

  final TsxTileDefinition tile;
  final TsxTilesetDefinition tileset;
  final bool selected;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final alignment = tileset.alignmentForTile(tile.id);
    final preview = SizedBox(
      width: 44,
      height: 30,
      child: ClipPath(
        clipper: const _DiamondClipper(),
        child: imagePath == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.grid_on, size: 14)),
              )
            : Image.asset(
                imagePath!,
                fit: BoxFit.none,
                alignment: Alignment(alignment.x, alignment.y),
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: Theme.of(context).colorScheme.errorContainer,
                ),
              ),
      ),
    );
    return Tooltip(
      message:
          'id ${tile.id}'
          '${tile.type.isEmpty ? '' : ' · ${tile.type}'}',
      child: InkWell(
        // Keyed by id, so a tile can be pointed at: from a test, or from the
        // inspector when it picks one up again after a reload.
        key: Key('tile-${tile.id}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              preview,
              Text('${tile.id}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiamondClipper extends CustomClipper<Path> {
  const _DiamondClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width / 2, 0)
    ..lineTo(size.width, size.height / 2)
    ..lineTo(size.width / 2, size.height)
    ..lineTo(0, size.height / 2)
    ..close();

  @override
  bool shouldReclip(_DiamondClipper oldClipper) => false;
}
