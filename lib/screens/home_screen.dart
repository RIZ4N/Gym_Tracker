import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'body_screen.dart';
import 'history_screen.dart';
import 'routines_screen.dart';
import 'settings_screen.dart';
import 'shell.dart';
import 'tools_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Up late';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final name = s.settings.name.trim();
    final week = s.thisWeek;
    final next = s.nextRoutine;

    void push(Widget screen) => Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => screen));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM')
                          .format(DateTime.now())
                          .toUpperCase(),
                      style: t.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name.isEmpty ? _greeting() : '${_greeting()}, $name',
                      style: t.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => push(const SettingsScreen()),
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              style: IconButton.styleFrom(backgroundColor: p.card),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _WeekCard(state: s),
        const SizedBox(height: 12),
        if (s.active != null)
          FilledButton.icon(
            onPressed: () => openActiveWorkout(context),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Resume ${s.active!.name}'),
          )
        else if (next != null)
          AppCard(
            color: p.accent,
            onTap: () => startWorkout(context, routine: next),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UP NEXT',
                        style: t.labelSmall?.copyWith(
                          color: p.onAccent.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        next.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleLarge?.copyWith(color: p.onAccent),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${next.items.length} exercises · '
                        '~${estimateMinutes(next, s.settings.defaultRest)} min',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.onAccent.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: p.onAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: p.accent,
                    size: 28,
                  ),
                ),
              ],
            ),
          )
        else
          FilledButton.icon(
            onPressed: () => startWorkout(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Start a workout'),
          ),
        if (s.active == null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (next != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => startWorkout(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Empty workout', maxLines: 1),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Shell.goToTab(context, 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.list_alt_rounded, size: 20),
                  label: Text(
                    next != null ? 'All routines' : 'Browse routines',
                  ),
                ),
              ),
            ],
          ),
        ],
        const SectionHeader('This week'),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.stacked_bar_chart_rounded,
                label: 'Volume',
                value: fmtVolume(
                  week.fold(0.0, (a, w) => a + w.volume),
                  s.unit,
                ),
                unit: s.unit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.schedule_rounded,
                label: 'Time trained',
                value: fmtDuration(
                  week.fold(Duration.zero, (a, w) => a + w.duration),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.format_list_numbered_rounded,
                label: 'Sets',
                value: '${week.fold(0, (a, w) => a + w.setCount)}',
              ),
            ),
          ],
        ),
        SectionHeader(
          'Recent workouts',
          action: s.workouts.isEmpty ? null : 'See all',
          onAction: () => Shell.goToTab(context, 2),
        ),
        if (s.workouts.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'Your first workout awaits',
              message:
                  'Start an empty workout or pick a routine. Everything you '
                  'log shows up here.',
            ),
          ),
        for (final w in s.workouts.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WorkoutCard(workout: w),
          ),
        const SectionHeader('Tools'),
        Row(
          children: [
            Expanded(
              child: _ToolCard(
                icon: Icons.bolt_rounded,
                label: '1RM\ncalculator',
                onTap: () => push(const OneRmScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToolCard(
                icon: Icons.album_outlined,
                label: 'Plate\ncalculator',
                onTap: () => push(const PlateCalcScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToolCard(
                icon: Icons.monitor_weight_outlined,
                label: 'Body\ntracking',
                onTap: () => push(const BodyScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.p.accent),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

/// Weekly goal ring, streak and a Monday-to-Sunday strip.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = state;
    final goal = s.settings.weeklyGoal;
    final done = s.thisWeek.length;
    final streak = s.weekStreak;
    final monday = weekStart(DateTime.now());
    final today = dayOf(DateTime.now());
    final left = goal - done;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              RingProgress(
                progress: goal == 0 ? 0 : done / goal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$done/$goal',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: p.text,
                        fontFeatures: tabular,
                      ),
                    ),
                    Text(
                      'workouts',
                      style: t.labelSmall?.copyWith(letterSpacing: 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      left <= 0
                          ? 'Weekly goal reached'
                          : done == 0
                          ? 'Let\'s get started'
                          : '$left more to hit your goal',
                      style: t.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      left <= 0
                          ? 'Great consistency. Anything extra is a bonus.'
                          : 'Your target is $goal workouts a week.',
                      style: t.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Pill(
                      streak == 0 ? 'No streak yet' : '$streak-week streak',
                      icon: Icons.local_fire_department_rounded,
                      color: streak == 0 ? p.muted : p.gold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _day(
                    context,
                    DateTime(monday.year, monday.month, monday.day + i),
                    today,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _day(BuildContext context, DateTime date, DateTime today) {
    final p = context.p;
    final trained = state.workoutsOn(date).isNotEmpty;
    final isToday = sameDay(date, today);
    return Column(
      children: [
        Text(
          DateFormat('E').format(date).substring(0, 1),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isToday ? p.text : p.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: trained ? p.accent : p.cardHigh,
            shape: BoxShape.circle,
            border: isToday && !trained
                ? Border.all(color: p.accent, width: 1.5)
                : null,
          ),
          child: trained
              ? Icon(Icons.check_rounded, size: 18, color: p.onAccent)
              : Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: date.isAfter(today) ? p.muted : p.text,
                    fontFeatures: tabular,
                  ),
                ),
        ),
      ],
    );
  }
}
