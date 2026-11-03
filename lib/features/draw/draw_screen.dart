import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/shuffle_service.dart';
import '../../data/providers.dart';
import '../../models/models.dart';

class DrawScreen extends ConsumerWidget {
  const DrawScreen({super.key, required this.classId});
  final int classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classProvider(classId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (c) => c == null
          ? Scaffold(appBar: AppBar(), body: const Center(child: Text('Class not found')))
          : _DrawBody(cls: c),
    );
  }
}

enum _Phase { loading, scramble, dealing, done }

const _cardH = 32.0;
const _cardGap = 4.0;
const _poolCardW = 130.0;
const _headerH = 64.0;
const _gap = 12.0;

class _DrawBody extends ConsumerStatefulWidget {
  const _DrawBody({required this.cls});
  final ClassModel cls;

  @override
  ConsumerState<_DrawBody> createState() => _DrawBodyState();
}

class _DrawBodyState extends ConsumerState<_DrawBody> {
  final _rng = Random();
  Timer? _timer;
  _Phase _phase = _Phase.loading;
  bool _visible = false;
  bool _saved = false;
  bool _saving = false;

  late List<Student> _students; // current display order in the pool
  late List<List<Student>> _assignment; // final result per group
  final _dealt = <int>{}; // student ids already in their group

  ClassModel get cls => widget.cls;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _students = List.of(cls.students);
    _assignment = assignEvenly(cls.students, cls.groups.length, random: _rng);
    _dealt.clear();
    _saved = false;
    setState(() {
      _phase = _Phase.loading;
      _visible = false;
    });
    // loading ~0.5s
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _visible = true);
    });
    _timer = Timer(const Duration(milliseconds: 500), _scramble);
  }

  void _scramble() {
    setState(() => _phase = _Phase.scramble);
    var ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      ticks++;
      setState(() => _students.shuffle(_rng));
      if (ticks >= 4) {
        t.cancel();
        _deal();
      }
    });
  }

  void _deal() {
    setState(() => _phase = _Phase.dealing);
    final order = List.of(_students);
    final batch = max(1, (order.length / 45).ceil()); // ~1.5s at 33ms ticks
    var next = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 33), (t) {
      if (next >= order.length) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) setState(() => _phase = _Phase.done);
        });
        return;
      }
      setState(() {
        for (var i = 0; i < batch && next < order.length; i++) {
          _dealt.add(order[next++].id);
        }
      });
    });
  }

  void _skip() {
    _timer?.cancel();
    setState(() {
      _visible = true;
      _dealt.addAll(cls.students.map((s) => s.id));
      _phase = _Phase.done;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(repositoryProvider).saveAssignment(cls.id, {
        for (var i = 0; i < cls.groups.length; i++) cls.groups[i].id: _assignment[i].map((s) => s.id).toList(),
      });
      ref.invalidate(classListProvider);
      ref.invalidate(classProvider(cls.id));
      if (mounted) setState(() => _saved = true);
      messenger.showSnackBar(const SnackBar(content: Text('Groups saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _phase == _Phase.done;
    return Scaffold(
      appBar: AppBar(
        title: Text(cls.name),
        actions: [
          if (!done) TextButton(onPressed: _skip, child: const Text('Skip')),
          if (done) ...[
            TextButton.icon(onPressed: _start, icon: const Icon(Icons.casino), label: const Text('Re-roll')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saving || _saved ? null : _save,
              icon: Icon(_saved ? Icons.check : Icons.save),
              label: Text(_saved ? 'Saved' : 'Save'),
            ),
            if (_saved)
              TextButton(onPressed: () => context.pushReplacement('/class/${cls.id}'), child: const Text('View / Export')),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: LayoutBuilder(builder: (context, box) => _buildStage(context, box.maxWidth, box.maxHeight)),
    );
  }

  Widget _buildStage(BuildContext context, double w, double viewH) {
    final scheme = Theme.of(context).colorScheme;
    final g = cls.groups.length;
    final n = cls.students.length;

    // Pool grid.
    final poolCols = max(1, ((w - _gap) / (_poolCardW + _gap)).floor());
    final poolRows = (n / poolCols).ceil();
    final poolH = poolRows * (_cardH + _gap) + _gap;
    late final double poolTop;
    Offset poolPos(int i) => Offset(_gap + (i % poolCols) * (_poolCardW + _gap), poolTop + (i ~/ poolCols) * (_cardH + _gap));

    // Group boxes.
    const minColW = 170.0;
    final cols = min(g, max(1, ((w - _gap) / (minColW + _gap)).floor()));
    final colW = (w - _gap * (cols + 1)) / cols;
    final maxMembers = _assignment.fold<int>(0, (m, l) => max(m, l.length));
    final boxH = _headerH + maxMembers * (_cardH + _cardGap) + 8;
        Offset boxPos(int gi) => Offset(_gap + (gi % cols) * (colW + _gap), _gap + (gi ~/ cols) * (boxH + _gap));
    final groupRows = (g / cols).ceil();
    poolTop = groupRows * (boxH + _gap) + _gap + 8;
    final totalH = max(viewH, poolTop + poolH);

    // Target slot per student.
    final slot = <int, (int, int)>{};
    for (var gi = 0; gi < _assignment.length; gi++) {
      for (var k = 0; k < _assignment[gi].length; k++) {
        slot[_assignment[gi][k].id] = (gi, k);
      }
    }
    final poolIndex = {for (var i = 0; i < _students.length; i++) _students[i].id: i};

    final children = <Widget>[
      for (var gi = 0; gi < g; gi++)
        Positioned(
          left: boxPos(gi).dx,
          top: boxPos(gi).dy,
          width: colW,
          height: boxH,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cls.groups[gi].name, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                if (cls.groups[gi].project.isNotEmpty)
                  Text(cls.groups[gi].project, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      for (final s in cls.students)
        () {
          final dealt = _dealt.contains(s.id);
          final Offset pos;
          final double width;
          if (dealt) {
            final (gi, k) = slot[s.id]!;
            pos = boxPos(gi) + Offset(8, _headerH + k * (_cardH + _cardGap));
            width = colW - 16;
          } else {
            pos = poolPos(poolIndex[s.id]!);
            width = _poolCardW;
          }
          return AnimatedPositioned(
            key: ValueKey(s.id),
            duration: Duration(milliseconds: _phase == _Phase.scramble ? 220 : 380),
            curve: Curves.easeInOutCubic,
            left: pos.dx,
            top: pos.dy,
            width: width,
            height: _cardH,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _visible ? 1 : 0,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: dealt ? scheme.primaryContainer : scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))],
                ),
                child: Text(s.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              ),
            ),
          );
        }(),
    ];

    return SingleChildScrollView(
      child: SizedBox(width: w, height: totalH, child: Stack(children: children)),
    );
  }
}
