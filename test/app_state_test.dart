import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/demo.dart';
import 'package:gym_tracker/data/seed.dart';
import 'package:gym_tracker/models.dart';
import 'package:gym_tracker/state/app_state.dart';
import 'package:gym_tracker/utils/format.dart';
import 'package:gym_tracker/widgets/pickers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Workout _workout(
  DateTime start,
  String exerciseId,
  List<(double, int)> sets, {
  String? routineId,
}) => Workout(
  id: newId(),
  name: 'Test',
  routineId: routineId,
  start: start,
  end: start.add(const Duration(minutes: 45)),
  entries: [
    WorkoutEntry(
      exerciseId: exerciseId,
      sets: [
        for (final (w, r) in sets) SetEntry(weight: w, reps: r, done: true),
      ],
    ),
  ],
);

Future<AppState> _fresh() async {
  SharedPreferences.setMockInitialValues({});
  final s = AppState();
  await s.load();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed data is consistent', () {
    final ids = seedExercises.map((e) => e.id).toSet();
    expect(ids.length, seedExercises.length, reason: 'duplicate exercise id');
    for (final e in seedExercises) {
      expect(muscleGroups, contains(e.muscle));
      expect(equipmentTypes, contains(e.equipment));
    }
    for (final p in seedPrograms) {
      for (final d in p.days) {
        for (final (id, sets, lo, hi, _) in d.items) {
          expect(ids, contains(id), reason: '${p.name} / ${d.name}');
          expect(sets, greaterThan(0));
          expect(hi, greaterThanOrEqualTo(lo));
        }
      }
    }
  });

  test('finishing drops unticked sets and reports records', () async {
    final s = await _fresh();
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    s.replaceData(
      newWorkouts: [
        _workout(lastWeek, 'bench_press', [(60, 8), (60, 7)]),
      ],
      newRoutines: [],
      newBody: [],
    );
    expect(s.recordsFor('bench_press').maxWeight, 60);
    expect(s.previousSets('bench_press').length, 2);

    s.startEmpty();
    s.addExercisesToActive(['bench_press']);
    final entry = s.active!.entries.single;
    entry.sets
      ..clear()
      ..addAll([
        SetEntry(weight: 62.5, reps: 8, done: true),
        SetEntry(weight: 62.5, reps: 6, done: true),
        SetEntry(weight: 62.5, reps: 5),
      ]);
    expect(s.isPrSet('bench_press', entry.sets.first), isTrue);

    final result = s.finishActive()!;
    expect(result.workout.entries.single.sets.length, 2);
    expect(result.prs.map((p) => p.label), contains('Heaviest weight'));
    expect(result.prs.map((p) => p.label), contains('Best estimated 1RM'));
    expect(s.active, isNull);
    expect(s.workouts.length, 2);
    expect(s.recordsFor('bench_press').maxWeight, 62.5);
  });

  test('a workout with nothing ticked is not saved', () async {
    final s = await _fresh();
    s.startEmpty();
    s.addExercisesToActive(['squat']);
    expect(s.finishActive(), isNull);
    expect(s.workouts, isEmpty);
  });

  test('first session of an exercise is not counted as a record', () async {
    final s = await _fresh();
    s.startEmpty();
    s.addExercisesToActive(['squat']);
    s.active!.entries.single.sets.single
      ..weight = 100
      ..reps = 5
      ..done = true;
    expect(s.finishActive()!.prs, isEmpty);
  });

  test('week streak counts consecutive weeks that met the goal', () async {
    final s = await _fresh();
    s.updateSettings((x) => x.weeklyGoal = 2);
    final monday = weekStart(DateTime.now());
    DateTime day(int weeksAgo, int offset) => DateTime(
      monday.year,
      monday.month,
      monday.day - 7 * weeksAgo + offset,
      7,
    );
    s.replaceData(
      newWorkouts: [
        // Two weeks ago and last week hit the goal; three weeks ago did not.
        _workout(day(3, 0), 'squat', [(80, 5)]),
        _workout(day(2, 0), 'squat', [(80, 5)]),
        _workout(day(2, 2), 'squat', [(80, 5)]),
        _workout(day(1, 1), 'squat', [(80, 5)]),
        _workout(day(1, 3), 'squat', [(80, 5)]),
      ],
      newRoutines: [],
      newBody: [],
    );
    // The current week has not met the goal yet but must not break the streak.
    expect(s.weekStreak, 2);
  });

  test(
    'progression hint asks for more weight once the rep target is hit',
    () async {
      final s = await _fresh();
      s.replaceData(
        newWorkouts: [
          _workout(DateTime.now().subtract(const Duration(days: 2)), 'squat', [
            (80, 10),
            (80, 10),
          ]),
        ],
        newRoutines: [],
        newBody: [],
      );
      final hit = s.suggestionFor(
        WorkoutEntry(exerciseId: 'squat', repMin: 6, repMax: 10),
      );
      expect(hit, contains('82.5 kg'));
      final notYet = s.suggestionFor(
        WorkoutEntry(exerciseId: 'squat', repMin: 8, repMax: 12),
      );
      expect(notYet, contains('Aim for 11–12 reps'));
    },
  );

  test('backup round-trips and rejects foreign files', () async {
    final s = await _fresh();
    final demo = buildDemoData();
    s.replaceData(
      newWorkouts: demo.workouts,
      newRoutines: demo.routines,
      newBody: demo.body,
    );
    s.addCustomExercise(
      name: 'Sled Push',
      muscle: 'Quads',
      equipment: 'Other',
      kind: ExerciseKind.timed,
    );
    final backup = s.exportJson();
    final volume = s.workouts.fold(0.0, (a, w) => a + w.volume);

    final restored = await _fresh();
    restored.importJson(backup);
    expect(restored.workouts.length, s.workouts.length);
    expect(restored.routines.length, 3);
    expect(restored.body.length, s.body.length);
    expect(restored.workouts.fold(0.0, (a, w) => a + w.volume), volume);
    expect(restored.exercises.any((e) => e.name == 'Sled Push'), isTrue);

    expect(() => restored.importJson('not json'), throwsFormatException);
    expect(() => restored.importJson('{"app":"other"}'), throwsFormatException);
    expect(restored.workouts.length, s.workouts.length);
  });

  test('data survives a restart', () async {
    final s = await _fresh();
    s.startEmpty();
    s.addExercisesToActive(['squat']);
    s.active!.entries.single.sets.single
      ..weight = 100
      ..reps = 5
      ..done = true;
    s.finishActive();
    s.saveRoutine(Routine(id: 'r1', name: 'Legs'));

    final again = AppState();
    await again.load();
    expect(again.workouts.single.volume, 500);
    expect(again.routines.single.name, 'Legs');
  });

  test('units and input parsing', () {
    expect(fmtWeight(unitToKg(135, 'lb'), 'lb'), '135');
    expect(fmtWeight(62.5, 'kg'), '62.5');
    expect(fmtNum(60), '60');
    expect(parseSeconds('1:30'), 90);
    expect(parseSeconds('45'), 45);
    expect(parseDecimal('62,5'), 62.5);
    expect(fmtClock(const Duration(seconds: 3725)), '1:02:05');
    expect(SetEntry(weight: 100, reps: 5).e1rm, closeTo(116.67, 0.01));
  });
}
