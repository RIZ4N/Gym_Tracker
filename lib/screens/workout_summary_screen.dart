import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Shown right after finishing a workout.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key, required this.result});

  final FinishResult result;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final w = result.workout;
    final prs = result.prs;
    final done = s.thisWeek.length;
    final goal = s.settings.weeklyGoal;
    final canSave =
        w.routineId == null && !s.routines.any((r) => r.name == w.name);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: p.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.35),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: Icon(Icons.check_rounded, size: 46, color: p.onAccent),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Workout complete',
              style: t.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${w.name} · ${fmtDate(w.start)}',
              style: t.bodyMedium?.copyWith(color: p.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.schedule_rounded,
                    label: 'Duration',
                    value: fmtDuration(w.duration),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.stacked_bar_chart_rounded,
                    label: 'Volume',
                    value: fmtVolume(w.volume, s.unit),
                    unit: s.unit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Sets',
                    value: '${w.setCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.fitness_center_rounded,
                    label: 'Exercises',
                    value: '${w.entries.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: done >= goal ? p.accent : p.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      done >= goal
                          ? 'Weekly goal reached — $done of $goal workouts done!'
                          : '$done of $goal workouts this week. '
                                '${goal - done} to go.',
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (prs.isNotEmpty) ...[
              SectionHeader(
                '${prs.length} new ${prs.length == 1 ? 'record' : 'records'}',
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                border: p.gold.withValues(alpha: 0.4),
                child: Column(
                  children: [
                    for (final pr in prs)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events_rounded, color: p.gold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.exercise(pr.exerciseId).name,
                                    style: t.titleSmall,
                                  ),
                                  Text(pr.label, style: t.bodySmall),
                                ],
                              ),
                            ),
                            Text(
                              pr.value,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: p.gold,
                                fontFeatures: tabular,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
            if (canSave) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  s.saveRoutine(s.routineFromWorkout(w));
                  toast(context, 'Saved "${w.name}" as a routine');
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save as routine'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
