// Crown state for Head over Heels.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The crowns of every planet, and which planet the party is standing on.
///
/// One truth for two readers: the guardian of a throne room asks for the crowns
/// of its own planet, and the HUD shows the player the same number. The count
/// used to live in the game object while the HUD showed a number written in the
/// widget, so the two could not be compared and the player was told `2/5` no
/// matter what they picked up.
class CrownsNotifier extends StateNotifier<CrownsState> {
  CrownsNotifier() : super(const CrownsState());

  /// Records a crown for [planetId].
  void collect(String planetId) {
    state = state.copyWith(
      byPlanet: {
        ...state.byPlanet,
        planetId: (state.byPlanet[planetId] ?? 0) + 1,
      },
    );
  }

  /// The planet the party is on, which is the one the HUD counts.
  void arriveOn(String? planetId) {
    if (state.planet == planetId) return;
    state = state.copyWith(planet: planetId);
  }

  /// How many crowns [planetId] has collected.
  int for_(String planetId) => state.byPlanet[planetId] ?? 0;
}

/// What the HUD shows and the guardian asks about.
class CrownsState {
  const CrownsState({this.byPlanet = const {}, this.planet});

  /// Crowns collected, per planet.
  final Map<String, int> byPlanet;

  /// The planet the party is on, or null before the first room loads.
  final String? planet;

  CrownsState copyWith({Map<String, int>? byPlanet, String? planet}) =>
      CrownsState(
        byPlanet: byPlanet ?? this.byPlanet,
        planet: planet ?? this.planet,
      );
}

final crownsProvider = StateNotifierProvider<CrownsNotifier, CrownsState>(
  (ref) => CrownsNotifier(),
);
