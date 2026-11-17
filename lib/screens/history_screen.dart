import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';
import 'shell.dart';

/// History tab: a month calendar plus the workouts logged in it.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _day;

  void _shift(int by) => setState(() {
    _month = DateTime(_month.year, _month.month + by);
    _day = null;
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final inMonth = s.workouts
        .where(
          (w) => w.start.year == _month.year && w.start.month == _month.month,
        )
        .toList();
    final shown = _day == null
        ? inMonth
        : inMonth.where((w) => sameDay(w.start, _day!)).toList();
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('History', style: t.headlineMedium),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_month),
                      style: t.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: isCurrent ? null : () => _shift(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              _MonthGrid(
                month: _month,
                marked: {for (final w in inMonth) w.start.day},
                selected: _day,
                onSelect: (d) => setState(
                  () => _day = _day != null && sameDay(_day!, d) ? null : d,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(label: 'Workouts', value: '${inMonth.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Time trained',
                value: fmtDuration(
                  inMonth.fold(Duration.zero, (a, w) => a + w.duration),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Volume',
                value: fmtVolume(
                  inMonth.fold(0.0, (a, w) => a + w.volume),
                  s.unit,
                ),
                unit: s.unit,
              ),
            ),
          ],
        ),
        SectionHeader(
          _day == null ? 'Workouts' : fmtDate(_day!),
          action: _day == null ? null : 'Show month',
          onAction: () => setState(() => _day = null),
        ),
        if (shown.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.event_available_rounded,
              title: s.workouts.isEmpty
                  ? 'No workouts yet'
                  : _day == null
                  ? 'Nothing logged this month'
                  : 'Rest day',
              message: s.workouts.isEmpty
                  ? 'Finished workouts appear here, with a mark on the calendar '
                        'for every day you trained.'
                  : 'No workout was logged for this period.',
            ),
          ),
        for (final w in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WorkoutCard(workout: w),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.marked,
    required this.selected,
    required this.onSelect,
  });

  final DateTime month;
  final Set<int> marked;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    final today = DateTime.now();
    final rows = ((offset + days) / 7).ceil();

    Widget cell(int index) {
      final d = index - offset + 1;
      if (d < 1 || d > days) return const Expanded(child: SizedBox(height: 42));
      final date = DateTime(month.year, month.month, d);
      final has = marked.contains(d);
      final isToday = sameDay(date, today);
      final isSel = selected != null && sameDay(date, selected!);
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(date),
          child: SizedBox(
            height: 42,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: has
                      ? p.accent
                      : isSel
                      ? p.cardHigh
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSel
                      ? Border.all(color: p.text, width: 2)
                      : isToday && !has
                      ? Border.all(color: p.accent, width: 1.5)
                      : null,
                ),
                child: Text(
                  '$d',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: has || isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: has
                        ? p.onAccent
                        : date.isAfter(today)
                        ? p.muted.withValues(alpha: 0.5)
                        : p.text,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    d,
                    style: t.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows; r++)
          Row(children: [for (var c = 0; c < 7; c++) cell(r * 7 + c)]),
      ],
    );
  }
}

/// Summary of a finished workout; opens the detail screen on tap.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.read<AppState>();
    final w = workout;

    Widget meta(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: p.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: p.muted,
            fontFeatures: tabular,
          ),
        ),
      ],
    );

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: w.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  w.name,
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(fmtRelativeDay(w.start), style: t.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              meta(Icons.schedule_rounded, fmtDuration(w.duration)),
              meta(
                Icons.stacked_bar_chart_rounded,
                '${fmtVolume(w.volume, s.unit)} ${s.unit}',
              ),
              meta(Icons.format_list_numbered_rounded, '${w.setCount} sets'),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in w.entries.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${e.doneSets.length} × ${s.exercise(e.exerciseId).name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(
                  color: p.text.withValues(alpha: 0.85),
                ),
              ),
            ),
          if (w.entries.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('+ ${w.entries.length - 4} more', style: t.bodySmall),
            ),
        ],
      ),
    );
  }
}

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final w = s.workouts.where((x) => x.id == workoutId).firstOrNull;
    if (w == null) return const Scaffold();
    final unit = s.unit;

    return Scaffold(
      appBar: AppBar(
        title: Text(w.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'rename':
                  final name = await promptText(
                    context,
                    title: 'Workout name',
                    initial: w.name,
                  );
                  if (name != null && name.isNotEmpty) s.renameWorkout(w, name);
                case 'routine':
                  s.saveRoutine(s.routineFromWorkout(w));
                  if (context.mounted) {
                    toast(context, 'Saved "${w.name}" as a routine');
                  }
                case 'delete':
                  final ok = await confirm(
                    context,
                    title: 'Delete workout?',
                    message:
                        'This removes the workout and any records it set. '
                        'This cannot be undone.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (ok && context.mounted) {
                    Navigator.pop(context);
                    s.deleteWorkout(w);
                  }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(
                value: 'routine',
                child: Text('Save as routine'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: p.danger)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '${fmtDate(w.start)} · ${fmtTime(w.start)}'
              '${w.end != null ? '–${fmtTime(w.end!)}' : ''}',
              style: t.bodyMedium?.copyWith(color: p.muted),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Duration',
                  value: fmtDuration(w.duration),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Volume',
                  value: fmtVolume(w.volume, unit),
                  unit: unit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(label: 'Sets', value: '${w.setCount}'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final e in w.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EntryDetail(entry: e),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => startWorkout(context, repeat: w),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Repeat this workout'),
          ),
        ],
      ),
    );
  }
}

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({required this.entry});

  final WorkoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.read<AppState>();
    final ex = s.exercise(entry.exerciseId);
    var n = 0;
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(exerciseId: ex.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExerciseAvatar(ex, size: 38),
              const SizedBox(width: 12),
              Expanded(child: Text(ex.name, style: t.titleMedium)),
              Icon(Icons.chevron_right_rounded, color: p.muted),
            ],
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(entry.note, style: t.bodySmall),
          ],
          const SizedBox(height: 10),
          for (final x in entry.doneSets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      switch (x.type) {
                        SetType.warmup => 'W',
                        SetType.drop => 'D',
                        SetType.failure => 'F',
                        SetType.normal => '${++n}',
                      },
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: switch (x.type) {
                          SetType.warmup => p.gold,
                          SetType.drop => p.blue,
                          SetType.failure => p.danger,
                          SetType.normal => p.muted,
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      describeSet(x, ex.kind, s.unit),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                  if (ex.kind == ExerciseKind.weighted &&
                      x.e1rm > 0 &&
                      !x.isWarmup)
                    Text(
                      '1RM ${fmtWeight(x.e1rm, s.unit).split('.').first}',
                      style: t.bodySmall?.copyWith(fontFeatures: tabular),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
