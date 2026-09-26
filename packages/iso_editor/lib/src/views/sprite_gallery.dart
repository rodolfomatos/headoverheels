import 'package:flutter/material.dart';
import 'package:iso_core/iso_core.dart';

class SpriteGallery extends StatefulWidget {
  const SpriteGallery({
    required this.manifest,
    required this.assetsBasePath,
    this.category,
    super.key,
  });

  final AssetManifest manifest;
  final String assetsBasePath;
  final String? category;

  @override
  State<SpriteGallery> createState() => _SpriteGalleryState();
}

class _SpriteGalleryState extends State<SpriteGallery> {
  double _scale = 2;

  @override
  Widget build(BuildContext context) {
    final assets = widget.manifest.assets
        .where(
          (asset) =>
              !asset.isTileset &&
              (widget.category == null || asset.category == widget.category),
        )
        .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Text('Scale'),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1x')),
                      ButtonSegment(value: 2, label: Text('2x')),
                      ButtonSegment(value: 4, label: Text('4x')),
                    ],
                    selected: {_scale},
                    onSelectionChanged: (value) {
                      setState(() => _scale = value.first);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.8,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return _SpriteCard(
                asset: asset,
                assetsBasePath: widget.assetsBasePath,
                scale: _scale,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpriteCard extends StatelessWidget {
  const _SpriteCard({
    required this.asset,
    required this.assetsBasePath,
    required this.scale,
  });

  final AssetEntry asset;
  final String assetsBasePath;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final incomplete =
        (asset.frames ?? 1) > 1 && asset.metadata['frame_files'] is! List;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  '$assetsBasePath/${asset.file}',
                  scale: scale,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(asset.id, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                _Tag(label: asset.category),
                _Tag(label: asset.alpha),
                if (incomplete) const _Tag(label: 'incomplete', warning: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: warning
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
