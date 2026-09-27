import 'package:flutter/material.dart';
import 'package:knightlore/knightlore.dart';

/// The front door: title, pause, status scroll, victory and defeat.
class GameOverlay extends StatelessWidget {
  const GameOverlay({required this.game, super.key});

  final KnightLoreGame game;

  @override
  Widget build(BuildContext context) {
    switch (game.screen) {
      case GameScreen.title:
        return _TitleScreen(game: game);
      case GameScreen.paused:
        return _Panel(
          title: 'Paused',
          lines: const [
            'escape or p to carry on',
            'i shows the status scroll',
          ],
        );
      case GameScreen.status:
        return _StatusScroll(game: game);
      case GameScreen.victory:
        return _Panel(
          title: 'The curse is broken',
          lines: [
            game.objective,
            'days left: ${game.session?.curse.daysLeft ?? 0}',
            'press space to return to the title',
          ],
          accent: const Color(0xFF7FD18B),
        );
      case GameScreen.defeat:
        return _Panel(
          title: 'The wolf has you',
          lines: [
            game.session == null
                ? 'The forty days ran out.'
                : 'days left: ${game.session!.curse.daysLeft}',
            'press space to return to the title',
          ],
          accent: const Color(0xFFE57373),
        );
      case GameScreen.playing:
        return const SizedBox.shrink();
    }
  }
}

class _TitleScreen extends StatelessWidget {
  const _TitleScreen({required this.game});

  final KnightLoreGame game;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KNIGHT LORE',
            style: TextStyle(
              fontSize: 42,
              letterSpacing: 6,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE6E8EE),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Forty days to break a werewolf curse.',
            style: TextStyle(color: Color(0xFF9AA3B2)),
          ),
          const SizedBox(height: 18),
          _Bullet('Walk the castle in eight directions'),
          _Bullet('The cauldron asks for six treasures'),
          _Bullet('At night the curse splits you into four knights'),
          _Bullet('Open chests for scrolls and cast them with 1 to 9'),
          const SizedBox(height: 18),
          Text(
            'press space to begin',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'An homage built on the reusable iso_core engine. All rooms, art and '
            'sounds in this build are original work, not the 1984 game.',
            style: TextStyle(color: Color(0xFF6C7484), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatusScroll extends StatelessWidget {
  const _StatusScroll({required this.game});

  final KnightLoreGame game;

  @override
  Widget build(BuildContext context) {
    final session = game.session;
    final curse = session?.curse;
    return _Shell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS SCROLL',
            style: TextStyle(
              fontSize: 20,
              letterSpacing: 3,
              color: Color(0xFFE6E8EE),
            ),
          ),
          const SizedBox(height: 12),
          if (session != null && curse != null) ...[
            _Row('room', session.roomId.replaceAll('_', ' ')),
            _Row('days left', '${curse.daysLeft}'),
            _Row('form', curse.form.id),
            _Row(
              'ingredients',
              '${CurseState.totalIngredients - curse.ingredientsLeft}'
                  '/${CurseState.totalIngredients}',
            ),
            _Row('cauldron wants', curse.demandedIngredient ?? 'nothing yet'),
            const SizedBox(height: 10),
            const Text(
              'CARRYING',
              style: TextStyle(color: Color(0xFF7C8494), fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in session.inventory.items.whereType<String>())
                  _Pill(KlItems.nameOf(item)),
                if (session.inventory.usedSlots == 0)
                  const Text(
                    'nothing yet',
                    style: TextStyle(color: Color(0xFF7C8494)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'SPELLS',
              style: TextStyle(color: Color(0xFF7C8494), fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final active in curse.spells.active)
                  _Pill(
                    '${active.spell.name} '
                    '${(active.fraction * 100).round()}%',
                    colour: const Color(0xFF8AB4F8),
                  ),
                if (curse.spells.active.isEmpty)
                  const Text(
                    'none cast',
                    style: TextStyle(color: Color(0xFF7C8494)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'press i to close',
            style: TextStyle(color: Color(0xFF9AA3B2)),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.lines,
    this.accent,
  });

  final String title;
  final List<String> lines;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 30,
              letterSpacing: 3,
              color: accent ?? const Color(0xFFE6E8EE),
            ),
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child:
                  Text(line, style: const TextStyle(color: Color(0xFF9AA3B2))),
            ),
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xF0101216),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('· ', style: TextStyle(color: Color(0xFF7C8494))),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFFD5DAE3))),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF7C8494), fontSize: 12),
            ),
          ),
          Text(value, style: const TextStyle(color: Color(0xFFE6E8EE))),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.colour});

  final String label;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F27),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: (colour ?? const Color(0xFF3A3F4B))),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 12, color: colour ?? const Color(0xFFD5DAE3)),
      ),
    );
  }
}
