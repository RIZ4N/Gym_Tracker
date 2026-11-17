import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'exercises_screen.dart';

/// One-line description of a logged set, e.g. "60 kg × 8".
String describeSet(SetEntry s, ExerciseKind kind, String unit) {
  switch (kind) {
    case ExerciseKind.timed:
      return fmtSeconds(s.seconds ?? 0);
    case ExerciseKind.bodyweight:
      final w = s.weight ?? 0;
      return w > 0
          ? '+${fmtWeight(w, unit)} $unit × ${s.reps ?? 0}'
          : '${s.reps ?? 0} reps';
    case ExerciseKind.weighted:
      return '${fmtWeight(s.weight ?? 0, unit)} $unit × ${s.reps ?? 0}';
  }
}

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  int _metric = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final ex = s.exercise(widget.exerciseId);
    final history = s.historyFor(ex.id);
    final rec = s.recordsFor(ex.id);
    final unit = s.unit;
    final kind = ex.kind;

    final metrics = switch (kind) {
      ExerciseKind.weighted => ['Est. 1RM', 'Top weight', 'Volume'],
      ExerciseKind.bodyweight => ['Top reps', 'Total reps'],
      ExerciseKind.timed => ['Longest', 'Total time'],
    };
    final metric = min(_metric, metrics.length - 1);

    double valueOf(WorkoutEntry e) {
      final sets = e.workSets.toList();
      if (sets.isEmpty) return 0;
      switch (kind) {
        case ExerciseKind.weighted:
          return switch (metric) {
            0 => kgToUnit(sets.map((x) => x.e1rm).reduce(max), unit),
            1 => kgToUnit(sets.map((x) => x.weight ?? 0).reduce(max), unit),
            _ => kgToUnit(e.volume, unit),
          };
        case ExerciseKind.bodyweight:
          return metric == 0
              ? sets.map((x) => x.reps ?? 0).reduce(max).toDouble()
              : sets.fold(0.0, (a, x) => a + (x.reps ?? 0));
        case ExerciseKind.timed:
          return metric == 0
              ? sets.map((x) => x.seconds ?? 0).reduce(max).toDouble()
              : sets.fold(0.0, (a, x) => a + (x.seconds ?? 0));
      }
    }

    String fmtValue(double v) => switch (kind) {
      ExerciseKind.weighted =>
        metric == 2
            ? fmtVolume(unitToKg(v, unit), unit)
            : fmtNum(v, decimals: 1),
      ExerciseKind.bodyweight => fmtNum(v, decimals: 0),
      ExerciseKind.timed => fmtSeconds(v.round()),
    };

    final points = [
      for (final (w, e) in history.reversed)
        if (e.workSets.isNotEmpty) ChartPoint(w.start, valueOf(e)),
    ];

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (ex.custom)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  await showExerciseEditor(context, existing: ex);
                } else {
                  final ok = await confirm(
                    context,
                    title: 'Delete exercise?',
                    message:
                        '"${ex.name}" will be removed from your library and '
                        'routines. Past workouts keep their records.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (ok && context.mounted) {
                    s.deleteCustomExercise(ex);
                    Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: p.danger)),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Row(
            children: [
              ExerciseAvatar(ex, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name, style: t.headlineSmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Pill(ex.muscle, color: muscleColor(ex.muscle)),
                        Pill(ex.equipment),
                        for (final m in ex.secondary) Pill(m),
                        if (ex.custom) Pill('Custom', color: p.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: EmptyState(
                icon: Icons.show_chart_rounded,
                title: 'No history yet',
                message:
                    'Log this exercise in a workout and your records, charts '
                    'and past sessions will show up here.',
              ),
            )
          else ...[
            const SectionHeader('Personal records'),
            _RecordGrid(rec: rec, kind: kind, unit: unit),
            const SectionHeader('Progress'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < metrics.length; i++)
                        ChoiceChip(
                          label: Text(metrics[i]),
                          selected: metric == i,
                          onSelected: (_) => setState(() => _metric = i),
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: metric == i ? p.onAccent : p.text,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LineChartView(points: points, format: fmtValue),
                ],
              ),
            ),
            const SectionHeader('History'),
            for (final (w, e) in history.take(30))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(w.name, style: t.titleSmall)),
                          Text(fmtRelativeDay(w.start), style: t.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final x in e.doneSets)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: p.cardHigh,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '${x.isWarmup ? 'W  ' : ''}${describeSet(x, kind, unit)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: x.isWarmup ? p.muted : p.text,
                                  fontFeatures: tabular,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (e.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(e.note, style: t.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecordGrid extends StatelessWidget {
  const _RecordGrid({
    required this.rec,
    required this.kind,
    required this.unit,
  });

  final Records rec;
  final ExerciseKind kind;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final gold = context.p.gold;
    final tiles = switch (kind) {
      ExerciseKind.weighted => [
        StatTile(
          icon: Icons.emoji_events_rounded,
          color: gold,
          label: 'Heaviest · ${rec.maxWeightReps} reps',
          value: fmtWeight(rec.maxWeight, unit),
          unit: unit,
        ),
        StatTile(
          icon: Icons.bolt_rounded,
          color: gold,
          label: 'Estimated 1RM',
          value: fmtWeight(rec.bestE1rm, unit).split('.').first,
          unit: unit,
        ),
        StatTile(
          icon: Icons.stacked_bar_chart_rounded,
          label: 'Best session volume',
          value: fmtVolume(rec.bestSessionVolume, unit),
          unit: unit,
        ),
        StatTile(
          icon: Icons.repeat_rounded,
          label: 'Sessions logged',
          value: '${rec.sessions}',
        ),
      ],
      ExerciseKind.bodyweight => [
        StatTile(
          icon: Icons.emoji_events_rounded,
          color: gold,
          label: 'Most reps in a set',
          value: '${rec.maxReps}',
        ),
        StatTile(
          icon: Icons.repeat_rounded,
          label: 'Sessions logged',
          value: '${rec.sessions}',
        ),
      ],
      ExerciseKind.timed => [
        StatTile(
          icon: Icons.emoji_events_rounded,
          color: gold,
          label: 'Longest set',
          value: fmtSeconds(rec.maxSeconds),
        ),
        StatTile(
          icon: Icons.repeat_rounded,
          label: 'Sessions logged',
          value: '${rec.sessions}',
        ),
      ],
    };
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: tiles,
    );
  }
}
