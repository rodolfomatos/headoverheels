import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
// The synthesiser lives in iso_core now, and the cues are the game's.
import 'package:iso_core/audio.dart' show decodeWav;
import 'package:knightlore/src/audio/knight_lore_cues.dart';
import 'package:knightlore/src/world/items.dart';

void main() {
  group('every cue is a real sound', () {
    for (final cue in AudioCue.values) {
      test('${cue.name} is audible, brief and unclipped', () {
        final pcm = renderCue(cue).normalised();
        expect(pcm.isSilent, isFalse, reason: '${cue.name} is silent');
        expect(
          pcm.peak,
          lessThanOrEqualTo(1.0),
          reason: '${cue.name} clips',
        );
        expect(
          pcm.peak,
          greaterThan(0.1),
          reason: '${cue.name} is too quiet to hear',
        );
        expect(
          pcm.durationSeconds,
          inInclusiveRange(0.03, 1.0),
          reason: '${cue.name} is the wrong length',
        );
        // A cue that is one flat value is a bug, not a sound.
        final first = pcm.samples.first;
        expect(
          pcm.samples.any((sample) => (sample - first).abs() > 0.01),
          isTrue,
          reason: '${cue.name} is a constant',
        );
      });
    }
  });

  test('the six spells are six different sounds', () {
    // Every scroll in the game must have a cue, and no two may share one.
    final scrollCues = cueForScroll.values.toList();
    expect(scrollCues.length, 6);
    expect(scrollCues.toSet().length, 6);
    for (final cue in scrollCues) {
      expect(renderCue(cue).isSilent, isFalse, reason: cue.name);
    }
  });

  test('every scroll item in the game has a cue', () {
    // A scroll without a sound would cast in silence, so the item catalogue and
    // the cue table have to stay in step.
    final scrolls =
        KlItems.all.where((item) => item.isScroll).map((item) => item.id);
    for (final scroll in scrolls) {
      expect(
        cueForSpellItem(scroll),
        isNotNull,
        reason: '$scroll has no cue',
      );
    }
    expect(cueForSpellItem('a_chest'), isNull);
  });

  test('no two cues sound the same', () {
    final hashes = {
      for (final cue in AudioCue.values) cue: renderCue(cue).hash
    };
    final collisions = <AudioCue>[];
    final seen = <int, AudioCue>{};
    for (final entry in hashes.entries) {
      final previous = seen[entry.value];
      if (previous != null) collisions.add(entry.key);
      seen[entry.value] = entry.key;
    }
    expect(collisions, isEmpty, reason: 'these cues are identical');
  });

  test('rendering is deterministic', () {
    for (final cue in AudioCue.values) {
      expect(
        renderCue(cue).hash,
        renderCue(cue).hash,
        reason: '${cue.name} changed between runs',
      );
    }
    for (final area in AudioArea.values) {
      expect(renderAmbient(area).hash, renderAmbient(area).hash);
    }
  });

  test('the sundial tick is quieter than the other cues', () {
    // It fires every in-game day, so it must not shout over the footsteps.
    final tick = renderCue(AudioCue.dayTick).peak;
    for (final cue in [AudioCue.chest, AudioCue.hurt, AudioCue.victory]) {
      expect(renderCue(cue).peak, greaterThan(tick));
    }
  });

  group('ambient loops', () {
    for (final area in AudioArea.values) {
      test('${area.name} loops without a click', () {
        final pcm = renderAmbient(area).normalised();
        expect(pcm.isSilent, isFalse);
        expect(pcm.durationSeconds, greaterThanOrEqualTo(1.5));

        // A square wave jumps by design, so a loop only clicks if the seam
        // jumps *more* than the waveform already does. That is the honest
        // version of "seamless" for a chip loop.
        expect(
          pcm.seamStep,
          lessThanOrEqualTo(pcm.largestStep * 1.02),
          reason: '${area.name} clicks at the loop point '
              '(${pcm.seamStep} against ${pcm.largestStep})',
        );
        // The tremolo has to complete whole cycles too, or the fade at the end
        // will not meet the fade at the start.
        final quietest = pcm.samples.reduce(math.min);
        expect(pcm.peak - quietest, greaterThan(0.05));
        expect(pcm.peak - quietest, lessThan(0.9));
      });
    }

    test('each area has its own loop', () {
      final hashes = {
        for (final area in AudioArea.values) area: renderAmbient(area).hash
      };
      expect(hashes.values.toSet().length, AudioArea.values.length);
    });
  });

  group('the wav files on disk', () {
    test('round trip through the encoder', () {
      final original = renderCue(AudioCue.chest).normalised();
      final decoded = decodeWav(original.toWav());
      expect(decoded.sampleRate, original.sampleRate);
      expect(decoded.samples.length, original.samples.length);
      for (var index = 0; index < original.samples.length; index += 97) {
        // 16 bit quantisation, so the samples are close and not identical.
        expect(
          (decoded.samples[index] - original.samples[index]).abs(),
          lessThan(0.001),
        );
      }
    });

    test('match what the synthesiser renders now', () {
      // A drift gate: if someone edits a cue and forgets to regenerate, this
      // fails instead of shipping a stale file.
      var checked = 0;
      for (final cue in AudioCue.values) {
        final file = File('assets/audio/${cue.name}.wav');
        expect(file.existsSync(), isTrue, reason: '${cue.name}.wav is missing');
        expect(
          file.readAsBytesSync(),
          renderCue(cue).normalised().toWav(),
          reason:
              '${cue.name}.wav is stale: run `dart run tool/generate_audio.dart`',
        );
        checked++;
      }
      for (final area in AudioArea.values) {
        final file = File('assets/audio/${area.asset}.wav');
        expect(file.existsSync(), isTrue,
            reason: '${area.asset}.wav is missing');
        expect(
          file.readAsBytesSync(),
          renderAmbient(area).normalised().toWav(),
          reason: '${area.asset}.wav is stale',
        );
        checked++;
      }
      expect(checked, AudioCue.values.length + AudioArea.values.length);
    });

    test('the committed loops really are seamless', () {
      // The check above runs on the rendered buffer; this one runs on the file
      // a browser will load, which is the thing that has to be looped.
      for (final area in AudioArea.values) {
        final pcm = decodeWav(
          Uint8List.fromList(
            File('assets/audio/${area.asset}.wav').readAsBytesSync(),
          ),
        );
        expect(
          pcm.seamStep,
          lessThanOrEqualTo(pcm.largestStep * 1.02),
          reason: '${area.asset}.wav clicks at the loop point',
        );
      }
    });
  });

  group('the wav encoder', () {
    test('writes a header a player can read', () {
      final bytes = renderCue(AudioCue.step).toWav();
      final view = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(view.getUint32(16, Endian.little), 16, reason: 'PCM fmt size');
      expect(view.getUint16(20, Endian.little), 1, reason: 'uncompressed');
      expect(view.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(view.getUint16(34, Endian.little), 16, reason: 'bits per sample');
      expect(view.getUint32(4, Endian.little), bytes.length - 8);
    });

    test('refuses a file that is not wav', () {
      expect(
        () => decodeWav(Uint8List.fromList(List.filled(64, 7))),
        throwsFormatException,
      );
    });
  });
}
