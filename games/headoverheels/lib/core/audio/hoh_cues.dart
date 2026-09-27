import 'dart:typed_data';

import 'package:iso_core/audio.dart';

/// Every sound Head over Heels makes.
///
/// The original was an MSX game with a sound chip, and the tracks that came with
/// it are not ours to ship. So all thirty sounds are computed: the cues below
/// are the game's sound design, and `tool/generate_audio.dart` renders them to
/// `assets/audio`, which is a build product of this repository rather than a
/// recording of anything.
enum HohCue {
  // Music, one loop per place. Longer and quieter than a cue.
  musicMainMenu,
  musicCastle,
  musicEgyptus,
  musicPenitentiary,
  musicSafari,
  musicBookworld,
  musicBoss,
  musicGameOver,

  // Effects.
  jump,
  land,
  pickup,
  toggleSwitch,
  door,
  teleport,
  spring,
  conveyor,
  fire,
  doughnutHit,
  enemyHit,
  playerHit,
  playerDeath,
  fishEat,
  fishPoison,
  crown,
  bag,
  hushPuppy,
  swop,
  pause,
  menuSelect,
  menuNavigate,
}

/// The cues that loop under the game, and the keys the game passes for them.
///
/// The game asks for music by planet id, so the id is the link between the game
/// and the file. A test reads both and fails if they drift apart.
const Map<String, HohCue> musicByPlanet = {
  'castle': HohCue.musicCastle,
  'egyptus': HohCue.musicEgyptus,
  'penitentiary': HohCue.musicPenitentiary,
  'safari': HohCue.musicSafari,
  'bookworld': HohCue.musicBookworld,
  'boss': HohCue.musicBoss,
};

/// The cues that loop rather than play once.
const Set<HohCue> looping = {
  HohCue.musicMainMenu,
  HohCue.musicCastle,
  HohCue.musicEgyptus,
  HohCue.musicPenitentiary,
  HohCue.musicSafari,
  HohCue.musicBookworld,
  HohCue.musicBoss,
  HohCue.musicGameOver,
};

/// Where a cue's file lives, under `assets/audio`.
String assetFor(HohCue cue) {
  final name = switch (cue) {
    HohCue.musicMainMenu => 'music/main_menu.wav',
    HohCue.musicCastle => 'music/castle.wav',
    HohCue.musicEgyptus => 'music/egyptus.wav',
    HohCue.musicPenitentiary => 'music/penitentiary.wav',
    HohCue.musicSafari => 'music/safari.wav',
    HohCue.musicBookworld => 'music/bookworld.wav',
    HohCue.musicBoss => 'music/boss.wav',
    HohCue.musicGameOver => 'music/game_over.wav',
    HohCue.toggleSwitch => 'sfx/switch.wav',
    HohCue.doughnutHit => 'sfx/doughnut_hit.wav',
    HohCue.enemyHit => 'sfx/enemy_hit.wav',
    HohCue.playerHit => 'sfx/player_hit.wav',
    HohCue.playerDeath => 'sfx/player_death.wav',
    HohCue.fishEat => 'sfx/fish_eat.wav',
    HohCue.fishPoison => 'sfx/fish_poison.wav',
    HohCue.hushPuppy => 'sfx/hush_puppy.wav',
    HohCue.menuSelect => 'sfx/menu_select.wav',
    HohCue.menuNavigate => 'sfx/menu_navigate.wav',
    _ =>
      'sfx/${{HohCue.jump: 'jump', HohCue.land: 'land', HohCue.pickup: 'pickup', HohCue.door: 'door', HohCue.teleport: 'teleport', HohCue.spring: 'spring', HohCue.conveyor: 'conveyor', HohCue.fire: 'fire', HohCue.crown: 'crown', HohCue.bag: 'bag', HohCue.swop: 'swop', HohCue.pause: 'pause'}[cue]}.wav',
  };
  return 'assets/audio/$name';
}

/// The cue a planet's music is, or the menu theme.
HohCue musicForPlanet(String planetId) =>
    musicByPlanet[planetId] ?? HohCue.musicMainMenu;

/// Renders a cue to a buffer of samples.
Pcm renderCue(HohCue cue, {Synth? synth}) {
  final s = synth ?? Synth();
  switch (cue) {
    // The music. Each place has its own key and its own movement, and every
    // frequency is rounded to whole cycles by the synth so the loop is seamless.
    case HohCue.musicMainMenu:
      return _theme(s, seconds: 3.0, root: 196, wave: HohWave.sparse);
    case HohCue.musicCastle:
      return _theme(s, seconds: 3.0, root: 147, wave: HohWave.solid);
    case HohCue.musicEgyptus:
      return _theme(s, seconds: 3.0, root: 165, wave: HohWave.exotic);
    case HohCue.musicPenitentiary:
      return _theme(s, seconds: 3.0, root: 110, wave: HohWave.slow);
    case HohCue.musicSafari:
      return _theme(s, seconds: 3.0, root: 175, wave: HohWave.fast);
    case HohCue.musicBookworld:
      return _theme(s, seconds: 3.0, root: 131, wave: HohWave.bell);
    case HohCue.musicBoss:
      return _theme(s, seconds: 3.0, root: 98, wave: HohWave.harsh);
    case HohCue.musicGameOver:
      return _theme(s, seconds: 3.0, root: 87, wave: HohWave.sinking);

    case HohCue.jump:
      // A rising blip: the character leaves the floor.
      return Pcm(s.decay(s.glide(320, 900, 0.14), tail: 5)).normalised(0.55);
    case HohCue.land:
      // A dull thud, no rise at all.
      return Pcm(
        s.decay(s.pulse(120, 0.12, duty: 0.3), tail: 6),
      ).normalised(0.6);
    case HohCue.pickup:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(880, 0.06), tail: 7), gain: 0.6),
          (samples: s.decay(s.pulse(1320, 0.1), tail: 5), gain: 0.6),
        ]),
      );
    case HohCue.toggleSwitch:
      // A lever: a click, then a lower click.
      return Pcm(
        s.sequence([
          (samples: s.decay(s.noise(0.05), tail: 10), gain: 0.7),
          (
            samples: s.decay(s.pulse(392, 0.08, duty: 0.25), tail: 6),
            gain: 0.5,
          ),
        ]),
      );
    case HohCue.door:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(196, 0.12, duty: 0.5), tail: 4), gain: 0.6),
          (samples: s.decay(s.noise(0.14), tail: 6), gain: 0.4),
        ]),
      );
    case HohCue.teleport:
      // A shimmer that rises and falls, for arriving somewhere else.
      return Pcm(
        s.swell(
          mix(
            s.take(s.glide(400, 1600, 0.35, duty: 0.2), 0.35),
            withGain(s.take(s.triangle(800, 0.35), 0.35), 0.5),
          ),
        ),
      );
    case HohCue.spring:
      // The boing: a fast warble with a bounce at the end.
      return Pcm(
        s.swell(
          Float32List.fromList(
            List.generate(s.frames(0.3), (index) {
              final bounce = (index * 26 / s.sampleRate) % 1.0;
              final on = bounce < 0.5;
              return on
                  ? s.pulse(300 + bounce * 700, 0.02, duty: 0.5)[index %
                            s.frames(0.02)] *
                        0.6
                  : 0.0;
            }),
          ),
        ),
      ).normalised(0.6);
    case HohCue.conveyor:
      // A belt: a low hum with something sliding over it.
      return Pcm(
        mix(
          s.take(
            s.drone(seconds: 0.4, frequency: 80, duty: 0.5),
            0.4,
            gain: 0.5,
          ),
          s.take(s.decay(s.noise(0.4), tail: 2), 0.4, gain: 0.25),
        ),
      ).normalised(0.4);
    case HohCue.fire:
      // A jet of flame: noise with a falling body under it.
      return Pcm(
        mix(
          s.take(s.decay(s.noise(0.5), tail: 1.5), 0.5, gain: 0.5),
          s.take(
            s.decay(s.glide(600, 200, 0.5, duty: 0.2), tail: 2),
            0.5,
            gain: 0.4,
          ),
        ),
      );
    case HohCue.doughnutHit:
      // The thrown doughnut connects: a woody knock.
      return Pcm(
        s.decay(s.pulse(240, 0.1, duty: 0.15), tail: 8),
      ).normalised(0.7);
    case HohCue.enemyHit:
      return Pcm(
        s.decay(s.glide(700, 220, 0.14, duty: 0.3), tail: 5),
      ).normalised(0.7);
    case HohCue.playerHit:
      return Pcm(
        mix(
          s.take(s.decay(s.noise(0.18), tail: 6), 0.18, gain: 0.4),
          s.take(
            s.decay(s.glide(400, 140, 0.18, duty: 0.4), tail: 4),
            0.18,
            gain: 0.6,
          ),
        ),
      );
    case HohCue.playerDeath:
      // The longest effect, because it is the one that matters.
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(392, 0.14), tail: 4), gain: 0.6),
          (samples: s.decay(s.pulse(311, 0.14), tail: 4), gain: 0.6),
          (samples: s.decay(s.pulse(233, 0.3), tail: 2), gain: 0.6),
        ]),
      );
    case HohCue.fishEat:
      return Pcm(
        s.decay(s.glide(900, 1400, 0.12, duty: 0.25), tail: 6),
      ).normalised(0.5);
    case HohCue.fishPoison:
      // The wrong fish: a sour wobble.
      return Pcm(
        s.swell(
          Float32List.fromList(
            List.generate(s.frames(0.3), (index) {
              final wobble = 1.0 + 0.4 * ((index * 9 / s.sampleRate) % 1.0);
              return s.pulse(300 * wobble, 0.02, duty: 0.2)[index %
                      s.frames(0.02)] *
                  0.5;
            }),
          ),
        ),
      ).normalised(0.5);
    case HohCue.crown:
      // The crown: the game's reward, so a little tune.
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(523, 0.1), tail: 5), gain: 0.6),
          (samples: s.decay(s.pulse(784, 0.1), tail: 5), gain: 0.6),
          (samples: s.decay(s.pulse(1046, 0.2), tail: 3), gain: 0.6),
        ]),
      );
    case HohCue.bag:
      return Pcm(
        s.decay(s.pulse(660, 0.09, duty: 0.25), tail: 7),
      ).normalised(0.45);
    case HohCue.hushPuppy:
      // The puppy quiets a room: a soft hush.
      return Pcm(
        s.decay(s.pulse(520, 0.2, duty: 0.15), tail: 4),
      ).normalised(0.35);
    case HohCue.swop:
      // Moving between the two characters: a short whoosh.
      return Pcm(
        s.decay(s.glide(1200, 500, 0.1, duty: 0.3), tail: 6),
      ).normalised(0.5);
    case HohCue.pause:
      return Pcm(
        s.decay(s.pulse(330, 0.12, duty: 0.5), tail: 4),
      ).normalised(0.4);
    case HohCue.menuSelect:
      return Pcm(
        s.sequence([
          (samples: s.decay(s.pulse(660, 0.06), tail: 7), gain: 0.6),
          (samples: s.decay(s.pulse(990, 0.12), tail: 5), gain: 0.6),
        ]),
      );
    case HohCue.menuNavigate:
      return Pcm(
        s.decay(s.pulse(880, 0.05, duty: 0.25), tail: 8),
      ).normalised(0.3);
  }
}

/// The character of a place's music.
enum HohWave { solid, sparse, exotic, slow, fast, bell, harsh, sinking }

/// Builds a seamless theme for one place.
///
/// The layers all complete whole cycles in [seconds], so the loop point is
/// inaudible; what distinguishes one place from another is the key, the
/// timbres and how fast the layers move.
Pcm _theme(
  Synth s, {
  required double seconds,
  required double root,
  required HohWave wave,
}) {
  final (harmonics, tremoloRate, duty) = switch (wave) {
    HohWave.solid => (3, 0.5, 0.5),
    HohWave.sparse => (2, 1.0, 0.25),
    HohWave.exotic => (4, 0.75, 0.25),
    HohWave.slow => (3, 0.25, 0.5),
    HohWave.fast => (5, 2.0, 0.25),
    HohWave.bell => (2, 0.5, 0.12),
    HohWave.harsh => (6, 1.5, 0.5),
    HohWave.sinking => (2, 0.25, 0.75),
  };

  return Pcm(
    s.layer([
      (
        samples: s.drone(seconds: seconds, frequency: root, duty: duty),
        gain: 0.4,
      ),
      (
        samples: s.drone(seconds: seconds, frequency: root * 1.5, duty: 0.25),
        gain: 0.22,
      ),
      (
        samples: s.drone(
          seconds: seconds,
          frequency: root * 2,
          duty: 0.5,
          tremolo: 0.4,
          tremoloRate: tremoloRate,
        ),
        gain: 0.14,
      ),
      for (var harmonic = 3; harmonic <= harmonics; harmonic++)
        (
          samples: s.drone(
            seconds: seconds,
            frequency: root * harmonic,
            duty: 0.25,
            tremolo: 0.5,
            tremoloRate: tremoloRate * harmonic,
          ),
          gain: 0.07,
        ),
    ]),
    sampleRate: s.sampleRate,
  ).normalised(0.3);
}
