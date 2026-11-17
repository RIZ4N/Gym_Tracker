import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'body_screen.dart';
import 'exercise_detail_screen.dart';

/// Progress tab: totals, consistency, muscle balance, body weight, records.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// Weeks to look back; 0 means all time.
  int _weeks = 4;
  bool _allRecords = false;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final unit = s.unit;
    final now = DateTime.now();
    final from = _weeks == 0
        ? DateTime(2000)
        : DateTime(now.year, now.month, now.day - _weeks * 7 + 1);
    final list = s.workoutsSince(from);
    final total = list.fold(Duration.zero, (a, w) => a + w.duration);
    final muscles = s.muscleSets(from);
    final maxSets = muscles.isEmpty ? 1 : muscles.first.value;
    final weekly = s.weeklyCounts(8);
    final records = s.topRecords;
    final weights = [
      for (final b in s.body.reversed)
        if (b.weight != null) ChartPoint(b.date, kgToUnit(b.weight!, unit)),
    ];

    void openBody() => Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const BodyScreen()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('Progress', style: t.headlineMedium),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 4, label: Text('4 weeks')),
              ButtonSegment(value: 12, label: Text('12 weeks')),
              ButtonSegment(value: 52, label: Text('1 year')),
              ButtonSegment(value: 0, label: Text('All')),
            ],
            selected: {_weeks},
            onSelectionChanged: (v) => setState(() => _weeks = v.first),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.fitness_center_rounded,
                label: 'Workouts',
                value: '${list.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.stacked_bar_chart_rounded,
                label: 'Total volume',
                value: fmtVolume(list.fold(0.0, (a, w) => a + w.volume), unit),
                unit: unit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.schedule_rounded,
                label: 'Time trained',
                value: fmtDuration(total),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.timelapse_rounded,
                label: 'Average session',
                value: list.isEmpty
                    ? '—'
                    : fmtDuration(
                        Duration(seconds: total.inSeconds ~/ list.length),
                      ),
              ),
            ),
          ],
        ),
        const SectionHeader('Workouts per week'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarChartView(
                values: [for (final (_, c) in weekly) c.toDouble()],
                labels: [
                  for (final (d, _) in weekly) fmtShortDate(d).split(' ').first,
                ],
                goal: s.settings.weeklyGoal.toDouble(),
              ),
              const SizedBox(height: 10),
              Text(
                'Last 8 weeks, labelled by the Monday date. The dashed line '
                'is your goal of ${s.settings.weeklyGoal} a week.',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
        const SectionHeader('Muscle balance'),
        AppCard(
          child: muscles.isEmpty
              ? const EmptyState(
                  icon: Icons.donut_small_rounded,
                  title: 'Nothing to show yet',
                  message:
                      'Working sets per muscle group appear here, so you can '
                      'spot what you are neglecting.',
                )
              : Column(
                  children: [
                    for (final m in muscles)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 88,
                              child: Text(m.key, style: t.bodyMedium),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: m.value / maxSets,
                                  minHeight: 10,
                                  color: muscleColor(m.key),
                                  backgroundColor: p.cardHigh,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 62,
                              child: Text(
                                '${m.value} sets',
                                textAlign: TextAlign.right,
                                style: t.bodySmall?.copyWith(
                                  fontFeatures: tabular,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        SectionHeader('Body weight', action: 'Open', onAction: openBody),
        AppCard(
          onTap: openBody,
          child: weights.isEmpty
              ? const EmptyState(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Track your body',
                  message:
                      'Log your weight and measurements to see how your body '
                      'changes alongside your training.',
                )
              : LineChartView(
                  points: weights,
                  color: p.blue,
                  height: 150,
                  format: (v) => '${fmtNum(v, decimals: 1)} $unit',
                ),
        ),
        const SectionHeader('Personal records'),
        if (records.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No records yet',
              message:
                  'Your best lifts for each exercise are collected here as '
                  'you train.',
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final (ex, r) in records.take(_allRecords ? 999 : 6))
                  ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseDetailScreen(exerciseId: ex.id),
                      ),
                    ),
                    leading: ExerciseAvatar(ex, size: 40),
                    title: Text(
                      ex.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Best ${fmtWeight(r.maxWeight, unit)} $unit × ${r.maxWeightReps}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${fmtWeight(r.bestE1rm, unit).split('.').first} $unit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.gold,
                            fontFeatures: tabular,
                          ),
                        ),
                        Text(
                          'est. 1RM',
                          style: t.labelSmall?.copyWith(letterSpacing: 0),
                        ),
                      ],
                    ),
                  ),
                if (records.length > 6)
                  TextButton(
                    onPressed: () => setState(() => _allRecords = !_allRecords),
                    child: Text(
                      _allRecords ? 'Show fewer' : 'Show all ${records.length}',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
