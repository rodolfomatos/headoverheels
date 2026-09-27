import 'dart:typed_data';

import 'audio_synth.dart';

/// Every sound the game can make.
///
/// The original was a Spectrum game: its audio was beeps and a few effects
/// burnt into tape. None of that can be copied, so every cue here is computed
/// from [Synth] instead, and `assets/audio/*.wav` is written from this same code
/// by `tool/generate_audio.dart`.
enum AudioCue {
  step,
  blocked,
  door,
  chest,
  pickup,
  drop,
  spellSleep,
  spellShield,
  spellLight,
  spellTelekinesis,
  spellInvisibility,
  spellOpenDoor,
  hurt,
  trap,
  night,
  dawn,
  dayTick,
  menuMove,
  menuSelect,
  victory,
  defeat,
  blockedCurse,
}

/// The sound each spell makes, keyed by the scroll that casts it.
///
/// The names are the scroll item ids from `lib/src/world/items.dart`, so the
/// lookup needs no extra plumbing: the game already knows which scroll it cast.
const Map<String, AudioCue> cueForScroll = {
  'scroll_flip': AudioCue.spellSleep,
  'scroll_magic_armour': AudioCue.spellShield,
  'scroll_shield': AudioCue.spellLight,
  'scroll_telekinesis': AudioCue.spellTelekinesis,
  'scroll_invisibility': AudioCue.spellInvisibility,
  'scroll_open_door': AudioCue.spellOpenDoor,
};

/// The cue for a scroll, or null when the item is not a spell.
AudioCue? cueForSpellItem(String? item) =>
    item == null ? null : cueForScroll[item];

/// Renders a cue to a buffer of samples.
Pcm renderCue(AudioCue cue, {Synth? synth}) {
  final s = synth ?? Synth();
  switch (cue) {
    case AudioCue.step:
      // A dry, short click. Walk cycles in the original were a single tick.
      return Pcm(
        s.decay(s.take(s.noise(0.06), 0.05, gain: 0.5), tail: 9),
      ).normalised(0.35);
    case AudioCue.blocked:
      return Pcm(
        s.decay(s.pulse(150, 0.12, duty: 0.25), tail: 4),
      ).normalised(0.4);
    case AudioCue.door:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(392, 0.09), tail: 6), gain: 0.6),
          (samples: s.decay(s.pulse(587, 0.14), tail: 5), gain: 0.6),
        ]),
      );
    case AudioCue.chest:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(523, 0.07), tail: 7), gain: 0.6),
          (samples: s.decay(s.pulse(659, 0.07), tail: 7), gain: 0.6),
          (samples: s.decay(s.pulse(784, 0.12), tail: 5), gain: 0.6),
        ]),
      );
    case AudioCue.pickup:
      return Pcm(s.decay(s.pulse(1200, 0.09), tail: 6)).normalised(0.4);
    case AudioCue.drop:
      return Pcm(s.decay(s.glide(700, 300, 0.12), tail: 5)).normalised(0.4);
    case AudioCue.spellSleep:
      // Sleep spell: a slow slide down, the sound of something going under.
      return Pcm(s.swell(s.glide(880, 220, 0.45)));
    case AudioCue.spellShield:
      // Shield spell: a hard, bright double beat.
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(330, 0.08, duty: 0.5), tail: 6), gain: 0.7),
          (samples: s.decay(s.pulse(494, 0.16, duty: 0.5), tail: 4), gain: 0.7),
        ]),
      );
    case AudioCue.spellLight:
      // Light spell: a rising shimmer.
      return Pcm(
        s.swell(
          mix(
            s.take(s.glide(600, 1400, 0.4, duty: 0.25), 0.4),
            withGain(s.take(s.triangle(1200, 0.4), 0.4), 0.4),
          ),
        ),
      );
    case AudioCue.spellTelekinesis:
      // Telekinesis: a warble, as if the object were being pulled.
      return Pcm(
        s.swell(
          mix(
            s.take(s.pulse(300, 0.42, duty: 0.15), 0.42),
            withGain(
              s.take(s.pulse(360, 0.42, duty: 0.15), 0.42),
              0.6,
            ),
          ),
        ),
      );
    case AudioCue.spellInvisibility:
      // Invisibility: fast tremolo, thin and cold.
      return Pcm(
        s.swell(
          Float32List.fromList(
            List.generate(s.frames(0.4), (index) {
              final on = (index ~/ (s.sampleRate * 0.02)).isEven;
              return on
                  ? (s.pulse(760, 0.02, duty: 0.5)[index % s.frames(0.02)] *
                      0.6)
                  : 0.0;
            }),
          ),
        ),
      ).normalised(0.45);
    case AudioCue.spellOpenDoor:
      // Open door spell: a low thud and a click, like a bolt sliding back.
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(110, 0.12, duty: 0.2), tail: 4), gain: 0.8),
          (samples: s.decay(s.noise(0.16), tail: 6), gain: 0.5),
        ]),
      );
    case AudioCue.hurt:
      // The werewolf's bite: a noise hit over a falling tone.
      return Pcm(
        mix(
          s.take(s.decay(s.noise(0.3), tail: 5), 0.3, gain: 0.5),
          s.take(s.decay(s.glide(400, 90, 0.3, duty: 0.3), tail: 4), 0.3,
              gain: 0.6),
        ),
      );
    case AudioCue.trap:
      // An impaler or a ball: a hard mechanical snap.
      return Pcm(
        s.sequence([
          (samples: s.decay(s.noise(0.07), tail: 10), gain: 0.7),
          (samples: s.decay(s.pulse(220, 0.1, duty: 0.15), tail: 6), gain: 0.5),
        ]),
      );
    case AudioCue.night:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(330, 0.16, duty: 0.5), tail: 3), gain: 0.6),
          (
            samples: s.decay(s.pulse(220, 0.26, duty: 0.25), tail: 3),
            gain: 0.6
          ),
        ]),
      );
    case AudioCue.dawn:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(392, 0.14, duty: 0.5), tail: 4), gain: 0.6),
          (samples: s.decay(s.pulse(587, 0.24, duty: 0.5), tail: 3), gain: 0.6),
        ]),
      );
    case AudioCue.dayTick:
      // The sundial moving on: one quiet pulse, easy to miss.
      return Pcm(s.decay(s.pulse(1046, 0.05, duty: 0.25), tail: 8))
          .normalised(0.22);
    case AudioCue.menuMove:
      return Pcm(s.decay(s.pulse(880, 0.05, duty: 0.25), tail: 8))
          .normalised(0.3);
    case AudioCue.menuSelect:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(660, 0.06), tail: 7), gain: 0.6),
          (samples: s.decay(s.pulse(990, 0.12), tail: 5), gain: 0.6),
        ]),
      );
    case AudioCue.victory:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(523, 0.11), tail: 4), gain: 0.6),
          (samples: s.decay(s.pulse(659, 0.11), tail: 4), gain: 0.6),
          (samples: s.decay(s.pulse(784, 0.11), tail: 4), gain: 0.6),
          (samples: s.decay(s.pulse(1046, 0.3), tail: 2), gain: 0.7),
        ]),
      );
    case AudioCue.defeat:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(440, 0.16), tail: 3), gain: 0.6),
          (samples: s.decay(s.pulse(370, 0.16), tail: 3), gain: 0.6),
          (samples: s.decay(s.pulse(294, 0.4), tail: 2), gain: 0.6),
        ]),
      );
    case AudioCue.blockedCurse:
      // The curse refusing an action: a flat, discouraging buzz.
      return Pcm(
        s.decay(s.pulse(196, 0.18, duty: 0.5), tail: 3),
      ).normalised(0.45);
  }
}

/// The five areas, as the key of their ambient loop.
enum AudioArea {
  castle('ambient_castle', 110),
  jungle('ambient_jungle', 123),
  cauldron('ambient_cauldron', 98),
  mine('ambient_mine', 87),
  tower('ambient_tower', 131);

  const AudioArea(this.asset, this.root);

  /// The file name under `assets/audio`.
  final String asset;

  /// The root of the drone, in hertz. Each area sits in its own key.
  final double root;
}

/// Renders the seamless ambient loop for an area.
///
/// A loop only sounds like a loop if the end and the start are the same
/// waveform, so every frequency here completes a whole number of cycles in
/// [seconds] and the movement is a whole number of periods. That is what
/// [Synth.drone] rounds for.
Pcm renderAmbient(AudioArea area, {Synth? synth}) {
  final s = synth ?? Synth();
  const seconds = 2.0;
  return Pcm(
    s.layer([
      (
        samples: s.drone(seconds: seconds, frequency: area.root, duty: 0.5),
        gain: 0.35
      ),
      (
        samples:
            s.drone(seconds: seconds, frequency: area.root * 1.5, duty: 0.25),
        gain: 0.2
      ),
      (
        samples: s.drone(seconds: seconds, frequency: area.root * 2, duty: 0.5),
        gain: 0.12
      ),
      (
        samples: s.drone(
          seconds: seconds,
          frequency: area.root * 3,
          duty: 0.5,
          tremolo: 0.35,
          tremoloRate: 0.25,
        ),
        gain: 0.08,
      ),
    ]),
    sampleRate: s.sampleRate,
  ).normalised(0.28);
}
