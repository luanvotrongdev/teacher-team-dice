import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/lottery.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../routes.dart';

/// Shows a saved quiz. Each press of Lottery rolls the words briefly, then
/// settles on one random word from every column.
class PlayScreen extends ConsumerWidget {
  const PlayScreen({super.key, required this.quizId});
  final int quizId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Quiz q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete quiz?'),
        content: Text('"${q.name}" and its words will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(quizRepositoryProvider).deleteQuiz(q.id);
    ref.invalidate(quizListProvider);
    if (context.mounted) context.go(WordLotteryRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(quizProvider(quizId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (q) {
        if (q == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Quiz not found')));
        return Scaffold(
          appBar: AppBar(
            title: Text(q.name),
            actions: [
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref, q),
              ),
            ],
          ),
          body: LotteryBoard(columns: q.columns),
        );
      },
    );
  }
}

class LotteryBoard extends StatefulWidget {
  const LotteryBoard({super.key, required this.columns, this.random});
  final List<List<String>> columns;
  final Random? random;

  /// How long the words roll before settling. Tests rely on this.
  static const rollDuration = Duration(milliseconds: 800);
  static const _tick = Duration(milliseconds: 80);

  @override
  State<LotteryBoard> createState() => _LotteryBoardState();
}

class _LotteryBoardState extends State<LotteryBoard> {
  late final Random _rng = widget.random ?? Random();
  List<String>? _words;
  List<String>? _result;
  Timer? _timer;
  int _ticks = 0;

  bool get _rolling => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final total = LotteryBoard.rollDuration.inMilliseconds ~/ LotteryBoard._tick.inMilliseconds;
    _ticks = 0;
    _timer = Timer.periodic(LotteryBoard._tick, (t) {
      _ticks++;
      setState(() {
        if (_ticks >= total) {
          t.cancel();
          _timer = null;
          _result = drawCombination(widget.columns, _rng, previous: _result);
          _words = _result;
        } else {
          _words = drawCombination(widget.columns, _rng);
        }
      });
    });
    setState(() => _words = drawCombination(widget.columns, _rng));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = _words;
    final settled = !_rolling && words != null;
    // Landscape: the words sit side by side in one row. Portrait: they stack top to bottom.
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final cards = [
      for (var i = 0; i < widget.columns.length; i++)
        _WordCard(
          label: 'Column ${i + 1}',
          word: words?[i] ?? '?',
          // While rolling every tick swaps the word; once settled the key changes once more.
          switchKey: '${_rolling ? _ticks : 'done'}-$i-${words?[i]}',
          highlight: settled,
          fillHeight: landscape,
        ),
    ];

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final width = box.maxWidth - 32;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (words == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text('Press Lottery to draw a combination', style: theme.textTheme.bodyLarge),
                      ),
                    if (landscape) _row(cards, width) else _column(cards),
                  ],
                ),
              ),
            );
          }),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _rolling ? null : _start,
                icon: const Icon(Icons.casino),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Text('Lottery', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const _gap = 12.0;

  /// All cards in one row, sharing the width and the same height. If there are too many
  /// columns to fit, the row scrolls sideways instead of squeezing the words.
  Widget _row(List<Widget> cards, double width) {
    final n = cards.length;
    final cardW = ((width - _gap * (n - 1)) / n).clamp(140.0, 320.0);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              SizedBox(width: cardW, child: cards[i]),
            ],
          ],
        ),
      ),
    );
  }

  /// All cards stacked, full width (capped on tablets so the cards don't get too wide).
  Widget _column(List<Widget> cards) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            cards[i],
          ],
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.label,
    required this.word,
    required this.switchKey,
    required this.highlight,
    required this.fillHeight,
  });
  final String label;
  final String word;
  final String switchKey;
  final bool highlight;

  /// In a row the card is stretched to its tallest neighbour: keep the label at the top
  /// and center the word in the space below.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wordView = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: Text(
        word,
        key: ValueKey(switchKey),
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: highlight ? scheme.onPrimaryContainer : null,
        ),
      ),
    );
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            if (fillHeight) Expanded(child: Center(child: wordView)) else wordView,
          ],
        ),
      ),
    );
  }
}
