import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';
import '../widgets/tick.dart';
import 'exercise_detail_screen.dart';
import 'exercises_screen.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  Future<void> _finish(BuildContext context, AppState s) async {
    final w = s.active!;
    FocusManager.instance.primaryFocus?.unfocus();
    if (w.setCount == 0) {
      final ok = await confirm(
        context,
        title: 'No sets completed',
        message:
            'Tick off at least one set to save this workout. Discard it '
            'instead?',
        confirmLabel: 'Discard workout',
        destructive: true,
      );
      if (ok && context.mounted) {
        s.discardActive();
        Navigator.pop(context);
      }
      return;
    }
    final open = w.entries.fold(
      0,
      (a, e) => a + e.sets.where((x) => !x.done).length,
    );
    final ok = await confirm(
      context,
      title: 'Finish workout?',
      message: open > 0
          ? '$open unticked ${open == 1 ? 'set' : 'sets'} will not be saved.'
          : 'Nice work. Ready to save this workout?',
      confirmLabel: 'Finish',
    );
    if (!ok || !context.mounted) return;
    final result = s.finishActive();
    if (result == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(result: result)),
    );
  }

  Future<void> _discard(BuildContext context, AppState s) async {
    final ok = await confirm(
      context,
      title: 'Discard workout?',
      message: 'Everything logged in this session will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (ok && context.mounted) {
      s.discardActive();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final s = context.watch<AppState>();
    final w = s.active;
    if (w == null) return const Scaffold();
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          tooltip: 'Minimise',
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final name = await promptText(
              context,
              title: 'Workout name',
              initial: w.name,
            );
            if (name != null && name.isNotEmpty) {
              w.name = name;
              s.activeChanged();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_rounded, size: 14, color: p.muted),
                ],
              ),
              TickBuilder(
                builder: (_) => Text(
                  fmtClock(w.duration),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: () => _finish(context, s),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Finish'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _Totals(workout: w, unit: s.unit),
            const SizedBox(height: 14),
            if (w.entries.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.add_rounded,
                  title: 'Add your first exercise',
                  message:
                      'Pick exercises from the library, then log weight and '
                      'reps for each set.',
                  actionLabel: 'Add exercise',
                  onAction: () => _addExercises(context, s),
                ),
              ),
            for (var i = 0; i < w.entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _EntryCard(
                  key: ObjectKey(w.entries[i]),
                  entry: w.entries[i],
                  index: i,
                ),
              ),
            if (w.entries.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _addExercises(context, s),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add exercise'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _discard(context, s),
              style: TextButton.styleFrom(foregroundColor: p.danger),
              child: const Text('Discard workout'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: s.restEndsAt == null ? null : const RestBar(),
    );
  }

  Future<void> _addExercises(BuildContext context, AppState s) async {
    final ids = await pickExercises(context);
    if (ids != null && ids.isNotEmpty) s.addExercisesToActive(ids);
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.workout, required this.unit});

  final Workout workout;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget cell(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: p.text,
              fontFeatures: tabular,
            ),
          ),
        ],
      ),
    );
    final total = workout.entries.fold(0, (a, e) => a + e.sets.length);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          cell('VOLUME', '${fmtVolume(workout.volume, unit)} $unit'),
          cell('SETS', '${workout.setCount} / $total'),
          cell('EXERCISES', '${workout.entries.length}'),
        ],
      ),
    );
  }
}

class _EntryCard extends StatefulWidget {
  const _EntryCard({super.key, required this.entry, required this.index});

  final WorkoutEntry entry;
  final int index;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  late final _note = TextEditingController(text: widget.entry.note);
  late bool _showNote = widget.entry.note.isNotEmpty;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.read<AppState>();
    final entry = widget.entry;
    final ex = s.exercise(entry.exerciseId);
    final prev = s.previousSets(ex.id);
    final rest = entry.restSec ?? s.settings.defaultRest;
    final hint = s.suggestionFor(entry);
    final entries = s.active!.entries;

    final target = [
      if (entry.repMin != null && entry.repMax != null)
        entry.repMin == entry.repMax
            ? '${entry.repMin} reps'
            : '${entry.repMin}–${entry.repMax} reps',
      'Rest ${fmtSeconds(rest)}',
    ].join(' · ');

    final timed = ex.kind == ExerciseKind.timed;
    final labelStyle = t.labelSmall;

    var number = 0;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExerciseAvatar(ex, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailScreen(exerciseId: ex.id),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium,
                      ),
                      Text(target, style: t.bodySmall),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: p.muted),
                onSelected: (v) async {
                  switch (v) {
                    case 'rest':
                      final r = await pickRest(context, rest);
                      if (r != null) {
                        entry.restSec = r;
                        s.activeChanged();
                      }
                    case 'note':
                      setState(() => _showNote = true);
                    case 'up':
                      entries.insert(
                        widget.index - 1,
                        entries.removeAt(widget.index),
                      );
                      s.activeChanged();
                    case 'down':
                      entries.insert(
                        widget.index + 1,
                        entries.removeAt(widget.index),
                      );
                      s.activeChanged();
                    case 'remove':
                      entries.removeAt(widget.index);
                      s.activeChanged();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rest', child: Text('Rest timer')),
                  if (!_showNote)
                    const PopupMenuItem(value: 'note', child: Text('Add note')),
                  if (widget.index > 0)
                    const PopupMenuItem(value: 'up', child: Text('Move up')),
                  if (widget.index < entries.length - 1)
                    const PopupMenuItem(
                      value: 'down',
                      child: Text('Move down'),
                    ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Remove exercise',
                      style: TextStyle(color: p.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: p.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_showNote) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: t.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Notes for this exercise',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) {
                entry.note = v.trim();
                s.activeChanged(notify: false);
              },
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'SET',
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('PREVIOUS', style: labelStyle)),
              if (!timed) ...[
                SizedBox(
                  width: 72,
                  child: Text(
                    ex.kind == ExerciseKind.bodyweight
                        ? '+${s.unit.toUpperCase()}'
                        : s.unit.toUpperCase(),
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: timed ? 96 : 60,
                child: Text(
                  timed ? 'TIME' : 'REPS',
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < entry.sets.length; i++)
            _SetRow(
              key: ObjectKey(entry.sets[i]),
              entry: entry,
              set: entry.sets[i],
              kind: ex.kind,
              label: entry.sets[i].type == SetType.normal
                  ? '${++number}'
                  : null,
              previous: i < prev.length ? prev[i] : null,
              above: i > 0 ? entry.sets[i - 1] : null,
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () {
              entry.sets.add(SetEntry());
              s.activeChanged();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add set'),
            style: TextButton.styleFrom(foregroundColor: p.text),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.entry,
    required this.set,
    required this.kind,
    required this.label,
    required this.previous,
    required this.above,
  });

  final WorkoutEntry entry;
  final SetEntry set;
  final ExerciseKind kind;

  /// Set number, or null for warm-up / drop / failure sets.
  final String? label;

  /// The matching set from the last session.
  final SetEntry? previous;

  /// The set directly above in this workout.
  final SetEntry? above;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  final _w = TextEditingController();
  final _r = TextEditingController();

  AppState get _state => context.read<AppState>();
  bool get _timed => widget.kind == ExerciseKind.timed;

  @override
  void initState() {
    super.initState();
    _sync(force: true);
  }

  @override
  void didUpdateWidget(_SetRow old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _w.dispose();
    _r.dispose();
    super.dispose();
  }

  double? _fieldWeight() {
    final v = parseDecimal(_w.text);
    return v == null ? null : unitToKg(v, _state.unit);
  }

  int? _fieldCount() => _timed ? parseSeconds(_r.text) : int.tryParse(_r.text);

  /// Pushes model values into the text fields when they have drifted apart,
  /// e.g. after values were filled in from the previous session.
  void _sync({bool force = false}) {
    final s = widget.set;
    final fw = _fieldWeight();
    final same =
        (fw == null && s.weight == null) ||
        (fw != null && s.weight != null && (fw - s.weight!).abs() < 1e-6);
    if (force || !same) {
      _w.text = s.weight == null ? '' : fmtWeight(s.weight!, _state.unit);
    }
    final count = _timed ? s.seconds : s.reps;
    if (force || _fieldCount() != count) {
      _r.text = count == null
          ? ''
          : _timed
          ? fmtSeconds(count)
          : '$count';
    }
  }

  SetEntry? get _hint => widget.previous ?? widget.above;

  void _toggle() {
    final s = widget.set;
    final state = _state;
    if (s.done) {
      s.done = false;
      state.activeChanged();
      return;
    }
    final hint = _hint;
    if (_timed) {
      s.seconds ??= hint?.seconds;
      if ((s.seconds ?? 0) <= 0) {
        toast(context, 'Enter a time first');
        return;
      }
    } else {
      s.reps ??= hint?.reps;
      s.weight ??= hint?.weight;
      if ((s.reps ?? 0) <= 0) {
        toast(context, 'Enter your reps first');
        return;
      }
      if (widget.kind == ExerciseKind.weighted) s.weight ??= 0;
    }
    s.done = true;
    HapticFeedback.mediumImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    if (state.settings.autoRest) {
      state.startRest(widget.entry.restSec ?? state.settings.defaultRest);
    }
    state.activeChanged();
  }

  String _previousText(String unit) {
    final pr = widget.previous;
    if (pr == null) return '—';
    if (_timed) return fmtSeconds(pr.seconds ?? 0);
    final w = pr.weight ?? 0;
    if (widget.kind == ExerciseKind.bodyweight) {
      return w > 0 ? '+${fmtWeight(w, unit)} × ${pr.reps}' : '${pr.reps} reps';
    }
    return '${fmtWeight(w, unit)} × ${pr.reps}';
  }

  Widget _field(
    TextEditingController c, {
    required String hint,
    required double width,
    required TextInputType keyboard,
    required List<TextInputFormatter> formatters,
    required ValueChanged<String> onChanged,
  }) {
    final p = context.p;
    final done = widget.set.done;
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        inputFormatters: formatters,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next,
        onTap: () => c.selection = TextSelection(
          baseOffset: 0,
          extentOffset: c.text.length,
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: p.text,
          fontFeatures: tabular,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: p.muted.withValues(alpha: 0.55),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 9,
          ),
          fillColor: done ? Colors.transparent : p.cardHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.accent, width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final state = _state;
    final s = widget.set;
    final unit = state.unit;
    final hint = _hint;
    final isPr = state.isPrSet(widget.entry.exerciseId, s);

    final (typeLabel, typeColor) = switch (s.type) {
      SetType.warmup => ('W', p.gold),
      SetType.drop => ('D', p.blue),
      SetType.failure => ('F', p.danger),
      SetType.normal => (widget.label ?? '', p.text),
    };

    return Dismissible(
      key: ObjectKey(s),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: p.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline_rounded, color: p.danger),
      ),
      onDismissed: (_) {
        widget.entry.sets.remove(s);
        state.activeChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: s.done ? p.accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: PopupMenuButton<Object>(
                padding: EdgeInsets.zero,
                tooltip: 'Set type',
                onSelected: (v) {
                  if (v is SetType) {
                    s.type = v;
                  } else {
                    widget.entry.sets.remove(s);
                  }
                  state.activeChanged();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: SetType.normal,
                    child: Text('Normal set'),
                  ),
                  const PopupMenuItem(
                    value: SetType.warmup,
                    child: Text('Warm-up'),
                  ),
                  const PopupMenuItem(
                    value: SetType.drop,
                    child: Text('Drop set'),
                  ),
                  const PopupMenuItem(
                    value: SetType.failure,
                    child: Text('To failure'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete set',
                      style: TextStyle(color: p.danger),
                    ),
                  ),
                ],
                child: Center(
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: typeColor,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _previousText(unit),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.muted,
                  fontFeatures: tabular,
                ),
              ),
            ),
            if (!_timed) ...[
              _field(
                _w,
                width: 72,
                hint: hint?.weight != null && hint!.weight! > 0
                    ? fmtWeight(hint.weight!, unit)
                    : widget.kind == ExerciseKind.bodyweight
                    ? '0'
                    : '',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                onChanged: (_) {
                  s.weight = _fieldWeight();
                  state.activeChanged();
                },
              ),
              const SizedBox(width: 8),
            ],
            _field(
              _r,
              width: _timed ? 96 : 60,
              hint: _timed
                  ? (hint?.seconds != null
                        ? fmtSeconds(hint!.seconds!)
                        : '0:00')
                  : (hint?.reps != null ? '${hint!.reps}' : ''),
              keyboard: _timed ? TextInputType.datetime : TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(_timed ? r'[0-9:]' : r'[0-9]'),
                ),
                LengthLimitingTextInputFormatter(_timed ? 6 : 4),
              ],
              onChanged: (_) {
                if (_timed) {
                  s.seconds = _fieldCount();
                } else {
                  s.reps = _fieldCount();
                }
                state.activeChanged();
              },
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: s.done ? (isPr ? p.gold : p.accent) : p.cardHigh,
                borderRadius: BorderRadius.circular(11),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _toggle,
                  child: Icon(
                    isPr ? Icons.emoji_events_rounded : Icons.check_rounded,
                    size: 21,
                    color: s.done ? p.onAccent : p.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Countdown shown at the bottom of the workout screen while resting.
class RestBar extends StatelessWidget {
  const RestBar({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final s = context.watch<AppState>();
    if (s.restEndsAt == null) return const SizedBox.shrink();

    Widget adjust(String label, int delta) => TextButton(
      onPressed: () => s.adjustRest(delta),
      style: TextButton.styleFrom(
        foregroundColor: p.text,
        backgroundColor: p.cardHigh,
        minimumSize: const Size(54, 40),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        child: TickBuilder(
          builder: (_) {
            final end = s.restEndsAt;
            if (end == null) return const SizedBox.shrink();
            final left = end.difference(DateTime.now());
            final frac = (left.inMilliseconds / (s.restTotal * 1000)).clamp(
              0.0,
              1.0,
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: frac, minHeight: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: p.accent, size: 22),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'REST',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            fmtClock(left + const Duration(milliseconds: 999)),
                            style: TextStyle(
                              fontSize: 24,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: p.text,
                              fontFeatures: tabular,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      adjust('−15', -15),
                      const SizedBox(width: 8),
                      adjust('+15', 15),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: s.stopRest,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(64, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
