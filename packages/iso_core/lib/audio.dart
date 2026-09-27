/// The sound synthesiser, on its own.
///
/// The synthesiser is pure Dart: a pulse generator, a noise source, a few
/// envelopes and a WAV encoder. It is a separate library from the rest of
/// `iso_core` so a generator can run it on the plain Dart VM, without pulling in
/// Flame or the widget layer, which is what `tool/generate_audio.dart` does in
/// both games.
library;

export 'src/audio/audio_synth.dart';
