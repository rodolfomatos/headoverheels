// Writes every sound in `assets/audio` from the synthesiser in `iso_core` and
// the cues in `lib/core/audio/hoh_cues.dart`.
//
//     dart run tool/generate_audio.dart
//
// The files are a build product of this repository: nothing here is a recording
// of the original game, and `test/audio_test.dart` re-renders every cue and
// fails if a file on disk no longer matches.
import 'dart:io';

import 'package:headoverheels/core/audio/hoh_cues.dart';

void main() {
  var bytes = 0;
  var cues = 0;
  var music = 0;

  for (final cue in HohCue.values) {
    final pcm = renderCue(cue).normalised();
    // Exactly the path the cue documents, because that is the path the pubspec
    // bundles and the game loads. Only FlameAudio strips the prefix, at play.
    final file = File(assetFor(cue))..parent.createSync(recursive: true);
    file.writeAsBytesSync(pcm.toWav());
    bytes += file.lengthSync();
    if (looping.contains(cue)) {
      music++;
    } else {
      cues++;
    }
    stdout.writeln(
      '${assetFor(cue).padRight(34)} '
      '${pcm.durationSeconds.toStringAsFixed(2).padLeft(5)}s '
      'peak ${pcm.peak.toStringAsFixed(2)}'
      '${looping.contains(cue) ? '  loop' : ''}',
    );
  }

  stdout.writeln(
    '$cues effects and $music loops, ${(bytes / 1024).toStringAsFixed(0)} KiB',
  );
}
