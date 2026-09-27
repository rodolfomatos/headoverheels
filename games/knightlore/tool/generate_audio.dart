// Writes every cue and ambient loop in `assets/audio` from the synthesiser in
// `lib/src/audio`.
//
//     dart run tool/generate_audio.dart
//
// The WAV files are a build product of this project's own maths, not recorded
// audio: no sample from the original game is involved. `test/audio_test.dart`
// re-renders everything and fails if a file on disk no longer matches.
import 'dart:io';

// Imported directly rather than through the barrel: the synthesiser is pure
// Dart, so this runs on the plain VM without pulling in the widget layer.
import 'package:knightlore/src/audio/knight_lore_cues.dart';

void main() {
  final directory = Directory('assets/audio')..createSync(recursive: true);
  var bytes = 0;

  for (final cue in AudioCue.values) {
    final pcm = renderCue(cue).normalised();
    final file = File('${directory.path}/${cue.name}.wav')
      ..writeAsBytesSync(pcm.toWav());
    bytes += file.lengthSync();
    stdout.writeln(
      '${cue.name.padRight(20)} '
      '${pcm.durationSeconds.toStringAsFixed(2)}s '
      'peak ${pcm.peak.toStringAsFixed(2)}',
    );
  }

  for (final area in AudioArea.values) {
    final pcm = renderAmbient(area).normalised();
    final file = File('${directory.path}/${area.asset}.wav')
      ..writeAsBytesSync(pcm.toWav());
    bytes += file.lengthSync();
    stdout.writeln(
      '${area.asset.padRight(20)} '
      '${pcm.durationSeconds.toStringAsFixed(2)}s '
      'loop peak ${pcm.peak.toStringAsFixed(2)}',
    );
  }

  stdout.writeln(
    '${AudioCue.values.length} cues and ${AudioArea.values.length} loops, '
    '${(bytes / 1024).toStringAsFixed(0)} KiB total',
  );
}
