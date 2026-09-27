import 'dart:math' as math;
import 'dart:typed_data';

/// A mono audio buffer, in samples per second.
///
/// Everything in this file is pure Dart: the game has no audio assets, so the
/// sounds are computed from maths and the WAV files in `assets/audio` are a
/// build product of this code, not something recorded from the original game.
class Pcm {
  Pcm(this.samples, {this.sampleRate = defaultRate});

  /// A safe rate for beeps: high enough to sound like a chip, low enough that
  /// the loops stay small enough to ship in a web build. Nothing here needs
  /// more than the 8 kHz a 16 kHz sample rate carries.
  static const int defaultRate = 16000;

  final Float32List samples;
  final int sampleRate;

  /// The loudest sample, 0 when the buffer is silent.
  double get peak {
    var loudest = 0.0;
    for (final sample in samples) {
      final magnitude = sample.abs();
      if (magnitude > loudest) loudest = magnitude;
    }
    return loudest;
  }

  double get durationSeconds => samples.length / sampleRate;
  bool get isSilent => peak < 0.001;

  /// The same buffer, normalised to [target] if it is quiet.
  ///
  /// Clipping is prevented by scaling down, never by clamping: a hard clamp
  /// makes a square wave buzz.
  Pcm normalised([double target = 0.7]) {
    final loudest = peak;
    if (loudest <= 0) return this;
    if (loudest <= target) return this;
    final scale = target / loudest;
    return Pcm(
      Float32List.fromList(
        samples.map((sample) => (sample * scale).clamp(-1.0, 1.0)).toList(),
      ),
      sampleRate: sampleRate,
    );
  }

  /// The buffer as signed 16 bit little endian samples.
  Uint8List toPcm16() {
    final bytes = Uint8List(samples.length * 2);
    final view = ByteData.sublistView(bytes);
    for (var index = 0; index < samples.length; index++) {
      final value = (samples[index].clamp(-1.0, 1.0) * 32767).round();
      view.setInt16(index * 2, value, Endian.little);
    }
    return bytes;
  }

  /// A 16 bit mono RIFF/WAVE file, which every platform can play.
  Uint8List toWav() => encodeWav(this);

  /// A checksum of the samples, so two buffers can be told apart in a test.
  ///
  /// The samples are quantised the way the WAV encoder quantises them. Rounding
  /// the float directly would collapse every sample in (-1, 1) to zero and make
  /// every sound hash the same.
  int get hash {
    var value = 0x811c9dc5;
    for (var index = 0; index < samples.length; index++) {
      final quantised =
          (samples[index].clamp(-1.0, 1.0) * 32767).round() & 0xFFFFFFFF;
      value = ((value ^ quantised) * 0x01000193) & 0xFFFFFFFF;
    }
    return value;
  }

  /// The biggest jump between two neighbouring samples, including the one
  /// across the loop point.
  ///
  /// A square wave is meant to jump: what matters is whether the loop point
  /// jumps as much as the waveform already does.
  double get largestStep {
    var step = (samples.first - samples.last).abs();
    for (var index = 1; index < samples.length; index++) {
      final current = (samples[index] - samples[index - 1]).abs();
      if (current > step) step = current;
    }
    return step;
  }

  /// The step across the loop point, from the last sample back to the first.
  double get seamStep => (samples.first - samples.last).abs();
}

/// Wraps [pcm] in a RIFF/WAVE container.
Uint8List encodeWav(Pcm pcm) {
  final data = pcm.toPcm16();
  final bytes = Uint8List(44 + data.length);
  final view = ByteData.sublistView(bytes);
  void ascii(int offset, String text) {
    for (var index = 0; index < text.length; index++) {
      bytes[offset + index] = text.codeUnitAt(index);
    }
  }

  ascii(0, 'RIFF');
  view.setUint32(4, 36 + data.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, Endian.little); // PCM header size
  view.setUint16(20, 1, Endian.little); // uncompressed
  view.setUint16(22, 1, Endian.little); // mono
  view.setUint32(24, pcm.sampleRate, Endian.little);
  view.setUint32(28, pcm.sampleRate * 2, Endian.little); // bytes per second
  view.setUint16(32, 2, Endian.little); // block align
  view.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  view.setUint32(40, data.length, Endian.little);
  bytes.setRange(44, bytes.length, data);
  return bytes;
}

/// Reads a 16 bit mono WAV file back into a [Pcm].
///
/// Only the format this file writes is supported: a test uses it to prove the
/// encoder and the assets on disk round trip.
Pcm decodeWav(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  String ascii(int offset, int length) =>
      String.fromCharCodes(bytes.sublist(offset, offset + length));

  if (ascii(0, 4) != 'RIFF' || ascii(8, 4) != 'WAVE') {
    throw const FormatException('not a RIFF/WAVE file');
  }
  var offset = 12;
  var sampleRate = Pcm.defaultRate;
  Uint8List? data;
  while (offset + 8 <= bytes.length) {
    final id = ascii(offset, 4);
    final size = view.getUint32(offset + 4, Endian.little);
    if (id == 'fmt ') {
      sampleRate = view.getUint32(offset + 12, Endian.little);
    } else if (id == 'data') {
      data = Uint8List.sublistView(bytes, offset + 8, offset + 8 + size);
    }
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  if (data == null) throw const FormatException('no data chunk');

  final samples = Float32List(data.length ~/ 2);
  for (var index = 0; index < samples.length; index++) {
    samples[index] =
        view.getInt16(offset - data.length + index * 2, Endian.little) / 32767;
  }
  return Pcm(samples, sampleRate: sampleRate);
}

/// The building blocks the cues are made of.
class Synth {
  Synth({this.sampleRate = Pcm.defaultRate, int? seed})
    : _random = math.Random(seed ?? 7);

  final int sampleRate;
  final math.Random _random;

  int frames(double seconds) => (seconds * sampleRate).round();

  /// A pulse wave of [frequency] hertz. [duty] is the share of the period the
  /// wave spends high, which is what turns one square into a reedy tone.
  Float32List pulse(double frequency, double seconds, {double duty = 0.5}) {
    final length = frames(seconds);
    final samples = Float32List(length);
    final period = sampleRate / frequency;
    for (var index = 0; index < length; index++) {
      samples[index] = (index % period) / period < duty ? 1.0 : -1.0;
    }
    return samples;
  }

  Float32List triangle(double frequency, double seconds) {
    final length = frames(seconds);
    final samples = Float32List(length);
    final period = sampleRate / frequency;
    for (var index = 0; index < length; index++) {
      final phase = (index % period) / period;
      samples[index] = (phase < 0.5 ? phase * 4 - 1 : 3 - phase * 4);
    }
    return samples;
  }

  Float32List sine(double frequency, double seconds) {
    final length = frames(seconds);
    final samples = Float32List(length);
    for (var index = 0; index < length; index++) {
      samples[index] = math.sin(2 * math.pi * frequency * index / sampleRate);
    }
    return samples;
  }

  /// White noise, which the original used for footsteps and traps.
  Float32List noise(double seconds) {
    final length = frames(seconds);
    return Float32List.fromList(
      List.generate(length, (_) => _random.nextDouble() * 2 - 1),
    );
  }

  /// A frequency that glides from [from] to [to] hertz.
  Float32List glide(
    double from,
    double to,
    double seconds, {
    double duty = 0.5,
  }) {
    final length = frames(seconds);
    final samples = Float32List(length);
    var phase = 0.0;
    for (var index = 0; index < length; index++) {
      final progress = index / length;
      final frequency = from + (to - from) * progress;
      phase += frequency / sampleRate;
      samples[index] = (phase % 1) < duty ? 1.0 : -1.0;
    }
    return samples;
  }

  /// A fast attack and an exponential tail, the shape a chip sound has.
  Float32List decay(Float32List samples, {double tail = 5}) {
    final length = samples.length;
    return Float32List.fromList(
      List.generate(length, (index) {
        final attack = math.min(1.0, index / (sampleRate * 0.004));
        return samples[index] * attack * math.exp(-tail * index / length);
      }),
    );
  }

  /// A slow swell, for the spells that build instead of hitting.
  Float32List swell(Float32List samples) {
    final length = samples.length;
    return Float32List.fromList(
      List.generate(length, (index) {
        final progress = index / length;
        final envelope = math.sin(math.pi * progress);
        return samples[index] * envelope * envelope;
      }),
    );
  }

  /// Puts [parts] one after another. Each part is a buffer plus a gain.
  Float32List sequence(List<({Float32List samples, double gain})> parts) {
    var length = 0;
    for (final part in parts) {
      length += part.samples.length;
    }
    final out = Float32List(length);
    var offset = 0;
    for (final part in parts) {
      for (var index = 0; index < part.samples.length; index++) {
        out[offset + index] += part.samples[index] * part.gain;
      }
      offset += part.samples.length;
    }
    return out;
  }

  /// Mixes layers on top of each other, for the ambient loops.
  Float32List layer(List<({Float32List samples, double gain})> parts) {
    var length = 0;
    for (final part in parts) {
      if (part.samples.length > length) length = part.samples.length;
    }
    final out = Float32List(length);
    for (final part in parts) {
      for (var index = 0; index < part.samples.length; index++) {
        out[index] += part.samples[index] * part.gain;
      }
    }
    return out;
  }

  /// Restricts a buffer to [seconds] and applies [gain].
  Float32List take(Float32List samples, double seconds, {double gain = 1}) {
    final length = math.min(samples.length, frames(seconds));
    return Float32List.fromList(
      List.generate(length, (index) => samples[index] * gain),
    );
  }

  /// A looping drone that starts and ends on the same sample value, so the
  /// loop point is inaudible.
  ///
  /// Every frequency is rounded to a whole number of cycles in [seconds] and
  /// every slow movement is given a whole number of periods, which is what
  /// makes the seam disappear.
  Float32List drone({
    required double seconds,
    required double frequency,
    double duty = 0.5,
    double tremolo = 0,
    double tremoloRate = 0,
  }) {
    final length = frames(seconds);
    final cycles = (frequency * seconds).round();
    final tone = cycles / seconds;
    final tremoloCycles = tremoloRate == 0
        ? 0
        : (tremoloRate * seconds).round();
    final samples = Float32List(length);
    for (var index = 0; index < length; index++) {
      var value = ((index * tone / sampleRate) % 1) < duty ? 1.0 : -1.0;
      if (tremoloCycles > 0) {
        final rate = tremoloCycles / seconds;
        value *=
            1 -
            tremolo +
            tremolo *
                (0.5 + 0.5 * math.sin(2 * math.pi * rate * index / sampleRate));
      }
      samples[index] = value;
    }
    return samples;
  }
}

/// Scales [samples] so its loudest value is [target], if it is not already.
Float32List withGain(Float32List samples, double gain) => Float32List.fromList(
  List.generate(samples.length, (i) => samples[i] * gain),
);

/// Mixes two buffers of equal length.
Float32List mix(Float32List a, Float32List b) => Float32List.fromList(
  List.generate(a.length, (index) => a[index] + b[index]),
);
