import 'dart:math';

import '../models.dart';
import '../utils/format.dart';
import 'seed.dart';

/// Sample history so charts and records can be previewed: ten weeks of a
/// push / pull / legs split with gradual progress.
({List<Workout> workouts, List<Routine> routines, List<BodyEntry> body})
buildDemoData() {
  final rnd = Random(7);
  final program = seedPrograms.firstWhere((p) => p.id == 'ppl');
  final routines = [
    for (final d in program.days)
      Routine(
        id: 'demo_${d.name.toLowerCase()}',
        name: d.name,
        items: [
          for (final (ex, sets, lo, hi, rest) in d.items)
            RoutineItem(
              exerciseId: ex,
              sets: sets,
              repMin: lo,
              repMax: hi,
              restSec: rest,
            ),
        ],
      ),
  ];

  // Starting working weights in kg.
  const start = {
    'bench_press': 55.0,
    'db_shoulder_press': 16.0,
    'incline_db_press': 20.0,
    'lateral_raise': 7.0,
    'triceps_pushdown': 22.5,
    'overhead_triceps_ext': 17.5,
    'deadlift': 90.0,
    'seated_cable_row': 45.0,
    'face_pull': 17.5,
    'barbell_curl': 25.0,
    'hammer_curl': 12.0,
    'squat': 75.0,
    'romanian_deadlift': 65.0,
    'leg_press': 120.0,
    'lying_leg_curl': 32.5,
    'standing_calf_raise': 60.0,
  };

  final workouts = <Workout>[];
  final monday = weekStart(DateTime.now());
  const weeks = 10;
  // Mon, Tue, Thu, Sat; hours of the day vary a little.
  const days = [0, 1, 3, 5];
  var session = 0;
  for (var wk = weeks - 1; wk >= 0; wk--) {
    for (final d in days) {
      final date = DateTime(monday.year, monday.month, monday.day - wk * 7 + d);
      final begin = date.add(
        Duration(hours: 6 + rnd.nextInt(3), minutes: rnd.nextInt(50)),
      );
      final ended = begin.add(const Duration(minutes: 90));
      if (ended.isAfter(DateTime.now())) continue;
      // Skip the odd older session so the calendar looks realistic.
      if (wk > 2 && rnd.nextInt(9) == 0) continue;
      final routine = routines[session % routines.length];
      session++;
      final progress = (weeks - 1 - wk) / (weeks - 1);
      final entries = <WorkoutEntry>[];
      for (final item in routine.items) {
        final base = start[item.exerciseId];
        final sets = <SetEntry>[];
        for (var i = 0; i < item.sets; i++) {
          if (base == null) {
            // Bodyweight exercises: reps creep up over time.
            sets.add(
              SetEntry(
                reps: max(
                  3,
                  item.repMin + (progress * 4).round() - i + rnd.nextInt(2),
                ),
                done: true,
              ),
            );
          } else {
            final step = base >= 60 ? 2.5 : (base >= 20 ? 2.5 : 1.0);
            final gain = base * 0.22 * progress;
            final weight = ((base + gain) / step).round() * step;
            final reps = (item.repMax - i - rnd.nextInt(2)).clamp(
              item.repMin,
              item.repMax,
            );
            sets.add(SetEntry(weight: weight, reps: reps, done: true));
          }
        }
        entries.add(
          WorkoutEntry(
            exerciseId: item.exerciseId,
            sets: sets,
            restSec: item.restSec,
            repMin: item.repMin,
            repMax: item.repMax,
          ),
        );
      }
      workouts.add(
        Workout(
          id: 'demo_w$session',
          name: routine.name,
          routineId: routine.id,
          start: begin,
          end: begin.add(Duration(minutes: 52 + rnd.nextInt(24))),
          entries: entries,
        ),
      );
    }
  }

  final body = <BodyEntry>[
    for (var wk = weeks - 1; wk >= 0; wk--)
      BodyEntry(
        id: 'demo_b$wk',
        date: DateTime(monday.year, monday.month, monday.day - wk * 7),
        weight: 71.2 + (weeks - 1 - wk) * 0.28 + rnd.nextDouble() * 0.5,
        bodyFat: wk % 3 == 0 ? 17.5 - (weeks - 1 - wk) * 0.12 : null,
        measurements: wk % 3 == 0
            ? {
                'Chest': 98 + (weeks - 1 - wk) * 0.3,
                'Biceps': 34.5 + (weeks - 1 - wk) * 0.12,
                'Waist': 82 - (weeks - 1 - wk) * 0.1,
                'Thigh': 56 + (weeks - 1 - wk) * 0.2,
              }
            : null,
      ),
  ]..removeWhere((b) => b.date.isAfter(DateTime.now()));

  return (workouts: workouts, routines: routines, body: body);
}
