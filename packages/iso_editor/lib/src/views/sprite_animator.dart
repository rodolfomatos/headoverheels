import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iso_core/iso_core.dart';

import '../assets/asset_manifest_service.dart';

class SpriteAnimator extends StatefulWidget {
  const SpriteAnimator({
    required this.entry,
    required this.assetsBasePath,
    this.scale = 2,
    this.autoPlay = false,
    super.key,
  });

  final AssetEntry entry;
  final String assetsBasePath;
  final double scale;
  final bool autoPlay;

  @override
  State<SpriteAnimator> createState() => _SpriteAnimatorState();
}

class _SpriteAnimatorState extends State<SpriteAnimator> {
  int _frame = 0;
  bool _playing = false;
  int _frameDuration = 100;
  Timer? _timer;

  List<String> get _frames {
    final declared = AssetManifestService.frameFilesOf(widget.entry);
    if (declared.isNotEmpty) return declared;
    return [widget.entry.file];
  }

  @override
  void initState() {
    super.initState();
    _frameDuration = widget.entry.frameDuration ?? 100;
    if (widget.autoPlay) _start();
  }

  @override
  void didUpdateWidget(SpriteAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _stop();
      _frame = 0;
      _frameDuration = widget.entry.frameDuration ?? 100;
      if (widget.autoPlay) _start();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    _stop();
    if (_frames.length < 2) return;
    _playing = true;
    _timer = Timer.periodic(
      Duration(milliseconds: _frameDuration),
      (_) => _advance(),
    );
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (_playing) _playing = false;
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      final next = _frame + 1;
      _frame = next >= _frames.length
          ? (widget.entry.loop ?? true ? 0 : _frames.length - 1)
          : next;
      if (!(widget.entry.loop ?? true) && next >= _frames.length) {
        _stop();
      }
    });
  }

  void _goTo(int frame) {
    setState(() {
      _frame = frame.clamp(0, _frames.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final frames = _frames;
    final current = frames[_frame.clamp(0, frames.length - 1)];
    final declared = widget.entry.frames;
    final incomplete = declared != null && declared != frames.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset(
              '$widget.assetsBasePath/$current',
              scale: widget.scale,
              filterQuality: FilterQuality.none,
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.broken_image_outlined, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              key: const Key('animator-prev'),
              onPressed: frames.length < 2
                  ? null
                  : () {
                      _goTo(_frame - 1);
                    },
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton.filledTonal(
              key: const Key('animator-play'),
              onPressed: frames.length < 2
                  ? null
                  : _playing
                  ? _stop
                  : _start,
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              key: const Key('animator-next'),
              onPressed: frames.length < 2
                  ? null
                  : () {
                      _goTo(_frame + 1);
                    },
              icon: const Icon(Icons.skip_next),
            ),
            Expanded(
              child: Slider(
                value: _frame.toDouble().clamp(
                  0,
                  (frames.length - 1).toDouble(),
                ),
                max: (frames.length - 1).toDouble(),
                divisions: frames.length > 1 ? frames.length - 1 : null,
                label: '${_frame + 1}/${frames.length}',
                onChanged: (value) => _goTo(value.round()),
              ),
            ),
            Text('${_frame + 1}/${frames.length}'),
          ],
        ),
        Row(
          children: [
            const Text('ms/frame'),
            Expanded(
              child: Slider(
                key: const Key('animator-duration'),
                value: _frameDuration.toDouble().clamp(16, 1000),
                max: 1000,
                divisions: 62,
                label: '$_frameDuration ms',
                onChanged: (value) {
                  setState(() {
                    _frameDuration = value.round();
                  });
                  if (_playing) _start();
                },
              ),
            ),
            Text('$_frameDuration ms'),
          ],
        ),
        if (incomplete)
          Text(
            'Declared $declared frames but ${frames.length} available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
