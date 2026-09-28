import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/core/audio/hoh_cues.dart';
import 'package:headoverheels/features/audio/audio_system.dart';
import 'package:iso_core/audio.dart' show Pcm, decodeWav;

/// The file behind a cue.
///
/// The path is used exactly as [assetFor] documents it, `assets/...`, because
/// that is where the pubspec looks and where the game loads from. Stripping the
/// prefix here would validate a directory nothing reads.
File _asset(String asset) => File(asset);

/// Reads the file on disk, so a cue and its file can be compared: the same
/// sound, or a stale file.
Future<Pcm> _readPcm(String asset) async =>
    decodeWav(Uint8List.fromList(_asset(asset).readAsBytesSync()));

void main() {
  test('every cue resolves to a file the audio layer can load', () {
    // The cue table names files from the bundle root and the audio layer
    // prefixes `assets/audio/` itself. Asking for `assets/audio/assets/audio/...`
    // returns silence, and every other test here would still pass: the files
    // exist, the WAVs decode, the cue list is complete. Only the path the
    // loader is handed says whether a player hears anything.
    for (final cue in HohCue.values) {
      final path = AudioSystem.relativeAsset(assetFor(cue));
      expect(
        path,
        isNot(startsWith('assets/')),
        reason: 'FlameAudio adds the assets/ prefix; $cue already has it',
      );
      expect(
        File('${AudioSystem.audioRoot}$path').existsSync(),
        isTrue,
        reason: 'nothing to play for $cue: $path',
      );
    }
  });

  group('the game only asks for sounds that exist', () {
    test('every cue has a file on disk', () {
      for (final cue in HohCue.values) {
        final asset = assetFor(cue);
        // Everything has to be inside assets/, or the pubspec will not bundle
        // it and the game will play silence.
        expect(
          asset,
          startsWith('assets/audio/'),
          reason: '$asset is not bundled',
        );
        final file = _asset(asset);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              '${cue.name} names ${assetFor(cue)}, which does not exist. '
              'Run: dart run tool/generate_audio.dart',
        );
        expect(
          file.lengthSync(),
          greaterThan(44),
          reason: '${cue.name} is empty',
        );
      }
    });

    test('the audio system names nothing the cue list does not', () {
      // The list the system preloads is derived from the cues, so this is what
      // stops the two drifting apart.
      expect(
        AudioSystem.allAssets.length,
        HohCue.values.length,
        reason: 'the system must ask for exactly the cues that exist',
      );
      expect(AudioSystem.allAssets.toSet().length, HohCue.values.length);
      for (final asset in AudioSystem.allAssets) {
        expect(
          asset,
          isNot(startsWith(AudioSystem.audioRoot)),
          reason: 'FlameAudio prefixes the audio root itself: $asset',
        );
        expect(
          _asset('${AudioSystem.audioRoot}$asset').existsSync(),
          isTrue,
          reason: asset,
        );
      }
    });

    test('nothing is left pointing at the old recordings', () {
      // The original tracks were .ogg and are not ours to ship. Every sound is
      // computed now, so no path may still name one.
      for (final cue in HohCue.values) {
        expect(assetFor(cue), endsWith('.wav'), reason: cue.name);
      }
      for (final file in Directory('assets/audio').listSync(recursive: true)) {
        if (file is! File) continue;
        if (file.path.endsWith('.md')) continue;
        expect(
          file.path,
          endsWith('.wav'),
          reason: '${file.path} is not something this repository produces',
        );
      }
    });

    test('every planet the game asks for has its own music', () {
      const planets = [
        'castle',
        'egyptus',
        'penitentiary',
        'safari',
        'bookworld',
        'boss',
      ];
      for (final planet in planets) {
        final cue = musicForPlanet(planet);
        expect(looping.contains(cue), isTrue, reason: '$planet must loop');
        expect(
          cue,
          isNot(HohCue.musicMainMenu),
          reason: '$planet fell back to the menu theme',
        );
      }
      // An unknown planet is the menu, not a crash.
      expect(musicForPlanet('nowhere'), HohCue.musicMainMenu);
      expect(musicForPlanet('main_menu'), HohCue.musicMainMenu);
    });
  });

  group('every sound is a real sound', () {
    for (final cue in HohCue.values) {
      test('${cue.name} is audible, brief and unclipped', () async {
        final rendered = renderCue(cue).normalised();
        expect(rendered.isSilent, isFalse, reason: '${cue.name} is silent');
        expect(
          rendered.peak,
          lessThanOrEqualTo(1.0),
          reason: '${cue.name} clips',
        );
        expect(
          rendered.peak,
          greaterThan(0.05),
          reason: '${cue.name} is too quiet to hear',
        );

        // The file on disk has to be the same sound as the cue, or the game
        // plays something the code does not describe.
        final onDisk = await _readPcm(assetFor(cue));
        expect(onDisk.samples.length, closeTo(rendered.samples.length, 2));
        expect(onDisk.durationSeconds, closeTo(rendered.durationSeconds, 0.01));
        expect(
          onDisk.peak,
          closeTo(rendered.peak, 0.01),
          reason: '${cue.name} on disk is a different sound',
        );
        expect(
          onDisk.peak,
          lessThanOrEqualTo(1.0),
          reason: '${cue.name} clips on disk',
        );
      });
    }
  });

  group('the music loops without a click', () {
    for (final cue in HohCue.values.where(looping.contains)) {
      test('${cue.name} is seamless', () async {
        final pcm = await _readPcm(assetFor(cue));
        // A square wave jumps by design, so a loop only clicks if the seam
        // jumps more than the waveform already does.
        expect(
          pcm.seamStep,
          lessThanOrEqualTo(pcm.largestStep * 1.02),
          reason:
              '${cue.name} clicks at the loop point '
              '(${pcm.seamStep} against ${pcm.largestStep})',
        );
        // And it has to be long enough to sound like music, not a blip.
        expect(
          pcm.durationSeconds,
          greaterThanOrEqualTo(2.0),
          reason: '${cue.name} is ${pcm.durationSeconds}s',
        );
      });
    }

    test('every place sounds different from every other', () async {
      final hashes = <String, int>{};
      for (final cue in HohCue.values.where(looping.contains)) {
        hashes[cue.name] = (await _readPcm(assetFor(cue))).hash;
      }
      expect(
        hashes.values.toSet().length,
        hashes.length,
        reason: 'two places share a theme: $hashes',
      );
    });
  });

  group('the effects', () {
    test('no two sound the same', () {
      final effects = HohCue.values.where((cue) => !looping.contains(cue));
      final seen = <int, HohCue>{};
      final collisions = <HohCue>[];
      for (final cue in effects) {
        final hash = renderCue(cue).hash;
        final previous = seen[hash];
        if (previous != null) collisions.add(cue);
        seen[hash] = cue;
      }
      expect(collisions, isEmpty, reason: 'these effects are identical');
    });

    test('they are short enough to fire in a row', () {
      for (final cue in HohCue.values.where((cue) => !looping.contains(cue))) {
        expect(
          renderCue(cue).durationSeconds,
          lessThan(0.6),
          reason:
              '${cue.name} is ${renderCue(cue).durationSeconds}s, which '
              'stacks up when it fires in a row',
        );
      }
    });

    test('they are louder than the music', () {
      // Music plays for minutes and effects fire constantly: the levels have to
      // reflect that before any volume setting is applied.
      final musicPeak = HohCue.values
          .where(looping.contains)
          .map((cue) => renderCue(cue).peak)
          .reduce((a, b) => a > b ? a : b);
      final effectPeak = HohCue.values
          .where((cue) => !looping.contains(cue))
          .map((cue) => renderCue(cue).peak)
          .reduce((a, b) => a > b ? a : b);
      expect(
        musicPeak,
        lessThan(effectPeak),
        reason: 'the music is as loud as the effects',
      );
      expect(musicPeak, lessThan(0.4));
    });
  });

  group('the files match the code', () {
    test('the committed files match what the synthesiser renders now', () {
      // The drift gate: edit a cue, forget to regenerate, and this fails
      // instead of shipping a stale file.
      for (final cue in HohCue.values) {
        expect(
          _asset(assetFor(cue)).readAsBytesSync(),
          renderCue(cue).normalised().toWav(),
          reason:
              '${cue.name} is stale: run `dart run tool/generate_audio.dart`',
        );
      }
    });

    test('rendering is deterministic', () {
      for (final cue in HohCue.values) {
        expect(
          renderCue(cue).hash,
          renderCue(cue).hash,
          reason: '${cue.name} changed between runs',
        );
      }
    });

    test('the wav encoder round trips', () {
      final original = renderCue(HohCue.jump).normalised();
      final decoded = decodeWav(original.toWav());
      expect(decoded.samples.length, original.samples.length);
      for (var index = 0; index < original.samples.length; index += 61) {
        // 16 bit quantisation, so the samples are close rather than identical.
        expect(
          (decoded.samples[index] - original.samples[index]).abs(),
          lessThan(0.001),
        );
      }
    });
  });
}
