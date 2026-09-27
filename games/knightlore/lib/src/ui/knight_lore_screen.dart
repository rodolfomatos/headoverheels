import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:knightlore/knightlore.dart';

/// The game screen: the Flame world, the heads up display and the keyboard.
class KnightLoreScreen extends StatefulWidget {
  const KnightLoreScreen(
      {super.key, this.config = const KnightLoreGameConfig()});

  final KnightLoreGameConfig config;

  @override
  State<KnightLoreScreen> createState() => _KnightLoreScreenState();
}

class _KnightLoreScreenState extends State<KnightLoreScreen> {
  late final KnightLoreGame _game;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _game = KnightLoreGame(config: widget.config);
  }

  @override
  void dispose() {
    _game.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = _keyFor(event.logicalKey);
    if (key == null) return KeyEventResult.ignored;
    _game.handleKey(key);
    setState(() {});
    return KeyEventResult.handled;
  }

  String? _keyFor(final key) {
    if (key.keyId == LogicalKeyboardKey.arrowUp.keyId) return 'arrowUp';
    if (key.keyId == LogicalKeyboardKey.arrowDown.keyId) return 'arrowDown';
    if (key.keyId == LogicalKeyboardKey.arrowLeft.keyId) return 'arrowLeft';
    if (key.keyId == LogicalKeyboardKey.arrowRight.keyId) return 'arrowRight';
    if (key.keyId == LogicalKeyboardKey.space.keyId) return ' ';
    if (key.keyId == LogicalKeyboardKey.enter.keyId) return 'enter';
    final character = key.character;
    if (character == null || character.isEmpty) return null;
    return character.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101216),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: GameWidget(
                game: _game,
              ),
            ),
            Positioned.fill(child: _NightVeil(isNight: _game.isNight)),
            Positioned.fill(
                child: _Hud(game: _game, onRefresh: () => setState(() {}))),
            if (!_game.assetsReady) const _Loader(),
          ],
        ),
      ),
    );
  }
}

class _NightVeil extends StatelessWidget {
  const _NightVeil({required this.isNight});

  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: isNight ? const Color(0x552A3B7A) : const Color(0x00000000),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6101216),
      child: const Center(child: Text('Loading the castle…')),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.game, required this.onRefresh});

  final KnightLoreGame game;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final session = game.session;
    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBar(game: game),
              const SizedBox(height: 8),
              if (session != null)
                _InventoryStrip(inventory: session.inventory),
              const Spacer(),
              if (game.error != null)
                Text(
                  'Could not load: ${game.error}',
                  style: const TextStyle(color: Color(0xFFE57373)),
                ),
              if (game.message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC161A22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    game.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              const SizedBox(height: 6),
              const Text(
                'arrows / wasd walk · space act · f skip to night',
                style: TextStyle(color: Color(0xFF7C8494), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.game});

  final KnightLoreGame game;

  @override
  Widget build(BuildContext context) {
    final session = game.session;
    final curse = session?.curse;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _Chip(
          label:
              session == null ? 'loading' : session.roomId.replaceAll('_', ' '),
        ),
        if (curse != null) _Chip(label: 'days ${curse.daysLeft}'),
        if (curse != null)
          _Chip(
            label: 'ingredients '
                '${CurseState.totalIngredients - curse.ingredientsLeft}'
                '/${CurseState.totalIngredients}',
          ),
        _Chip(
          label: game.isNight ? 'night' : 'day',
          colour:
              game.isNight ? const Color(0xFF6C8AE4) : const Color(0xFFE0A24A),
        ),
        if (curse != null && curse.demandedIngredient != null)
          _Chip(
            label: 'wants ${curse.demandedIngredient}',
            colour: const Color(0xFF9AD06C),
          ),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(value: game.dayProgress.clamp(0, 1)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.colour});

  final String label;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC161A22),
        borderRadius: BorderRadius.circular(4),
        border: colour == null
            ? null
            : Border.all(color: colour!.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 12, color: colour ?? const Color(0xFFE6E8EE)),
      ),
    );
  }
}

class _InventoryStrip extends StatelessWidget {
  const _InventoryStrip({required this.inventory});

  final Inventory inventory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var slot = 0; slot < inventory.slots; slot++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xCC161A22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: slot < inventory.usedSlots
                      ? const Color(0xFF6C8AE4)
                      : const Color(0xFF2C313B),
                ),
              ),
              child: slot < inventory.usedSlots
                  ? Text(
                      '${slot + 1}',
                      style: const TextStyle(fontSize: 11),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

/// The app, so `flutter run` and the web build share one entry point.
class KnightLoreApp extends StatelessWidget {
  const KnightLoreApp({super.key, this.config = const KnightLoreGameConfig()});

  final KnightLoreGameConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knight Lore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: KnightLoreScreen(config: config),
    );
  }
}
