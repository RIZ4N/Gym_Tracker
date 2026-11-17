import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../main.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tick.dart';
import 'active_workout_screen.dart';
import 'exercises_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'routines_screen.dart';

void openActiveWorkout(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const ActiveWorkoutScreen(),
    ),
  );
}

/// Starts a workout (empty, from a routine or repeating a past one) and opens
/// it. Asks first if another workout is already running.
Future<void> startWorkout(
  BuildContext context, {
  Routine? routine,
  Workout? repeat,
}) async {
  final s = context.read<AppState>();
  if (s.active != null) {
    final ok = await confirm(
      context,
      title: 'Workout in progress',
      message:
          '"${s.active!.name}" is still running. Discard it and start a new '
          'workout?',
      confirmLabel: 'Discard & start',
      destructive: true,
    );
    if (!ok) return;
  }
  if (routine != null) {
    s.startFromRoutine(routine);
  } else if (repeat != null) {
    s.repeatWorkout(repeat);
  } else {
    s.startEmpty();
  }
  if (context.mounted) openActiveWorkout(context);
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  static void goToTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_ShellState>()?._go(index);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  Timer? _restWatch;

  void _go(int i) => setState(() => _index = i);

  late final AppState _state = context.read<AppState>();
  bool _awake = false;

  /// Keeps the screen on for as long as a workout is running.
  void _syncWakelock() {
    final want = _state.active != null;
    if (want == _awake) return;
    _awake = want;
    WakelockPlus.toggle(enable: want).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _state.addListener(_syncWakelock);
    _syncWakelock();
    // Fires the "rest over" alert even when the workout screen is closed.
    _restWatch = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final s = _state;
      final end = s.restEndsAt;
      if (end != null && !end.isAfter(DateTime.now())) {
        s.stopRest();
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Rest is over — time for your next set'),
              duration: Duration(seconds: 3),
            ),
          );
      }
    });
  }

  @override
  void dispose() {
    _state.removeListener(_syncWakelock);
    _restWatch?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final hasActive = context.select<AppState, bool>((s) => s.active != null);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            RoutinesScreen(),
            HistoryScreen(),
            ProgressScreen(),
            ExercisesScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasActive) const _ActiveBar(),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _go,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center_rounded),
                  label: 'Workouts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: 'Progress',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Exercises',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Strip above the navigation bar while a workout is running.
class _ActiveBar extends StatelessWidget {
  const _ActiveBar();

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final s = context.watch<AppState>();
    final w = s.active;
    if (w == null) return const SizedBox.shrink();
    return Material(
      color: p.accent,
      child: InkWell(
        onTap: () => openActiveWorkout(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Icon(Icons.play_circle_fill_rounded, color: p.onAccent, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: p.onAccent,
                      ),
                    ),
                    TickBuilder(
                      builder: (_) {
                        final rest = s.restEndsAt?.difference(DateTime.now());
                        return Text(
                          rest != null && !rest.isNegative
                              ? 'Resting · ${fmtClock(rest + const Duration(milliseconds: 999))}'
                              : 'In progress · ${fmtClock(w.duration)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.onAccent.withValues(alpha: 0.75),
                            fontFeatures: tabular,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Text(
                'Resume',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: p.onAccent,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.onAccent),
            ],
          ),
        ),
      ),
    );
  }
}
