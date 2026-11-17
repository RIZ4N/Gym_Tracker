import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed.dart';
import '../models.dart';
import '../utils/format.dart';

class FinishResult {
  FinishResult(this.workout, this.prs);
  final Workout workout;
  final List<PrHit> prs;
}

/// Single source of truth for the app. Everything is kept in memory and
/// mirrored to local storage as JSON.
class AppState extends ChangeNotifier {
  static const _kSettings = 'settings';
  static const _kCustom = 'custom_exercises';
  static const _kWorkouts = 'workouts';
  static const _kRoutines = 'routines';
  static const _kBody = 'body';
  static const _kActive = 'active_workout';

  SharedPreferences? _prefs;
  bool loaded = false;

  Settings settings = Settings();
  final List<Exercise> _custom = [];
  final Set<String> _archived = {};
  Map<String, Exercise> _byId = {};

  /// Finished workouts, newest first.
  List<Workout> workouts = [];
  List<Routine> routines = [];

  /// Body log, newest first.
  List<BodyEntry> body = [];

  /// Workout in progress, if any.
  Workout? active;
  DateTime? restEndsAt;
  int restTotal = 0;

  Timer? _activeSaveTimer;
  final Map<String, Records> _recordsCache = {};
  Map<String, List<(Workout, WorkoutEntry)>>? _historyIndex;

  String get unit => settings.unit;

  // ---------------------------------------------------------------- loading

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    try {
      final s = p.getString(_kSettings);
      if (s != null) settings = Settings.fromJson(jsonDecode(s));
      _readCustom(p.getString(_kCustom));
      workouts = _readList(p.getString(_kWorkouts), Workout.fromJson);
      routines = _readList(p.getString(_kRoutines), Routine.fromJson);
      body = _readList(p.getString(_kBody), BodyEntry.fromJson);
      final a = p.getString(_kActive);
      if (a != null) active = Workout.fromJson(jsonDecode(a));
    } catch (e) {
      debugPrint('Failed to load saved data: $e');
    }
    _sort();
    _rebuildIndex();
    loaded = true;
    notifyListeners();
  }

  List<T> _readList<T>(String? raw, T Function(Map<String, dynamic>) f) {
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => f(e as Map<String, dynamic>))
        .toList();
  }

  void _readCustom(String? raw) {
    _custom.clear();
    _archived.clear();
    if (raw == null) return;
    for (final j in jsonDecode(raw) as List) {
      final m = j as Map<String, dynamic>;
      _custom.add(Exercise.fromJson(m));
      if (m['archived'] == true) _archived.add(m['id'] as String);
    }
  }

  void _sort() {
    workouts.sort((a, b) => b.start.compareTo(a.start));
    body.sort((a, b) => b.date.compareTo(a.date));
  }

  void _rebuildIndex() {
    _byId = {for (final e in seedExercises) e.id: e};
    for (final e in _custom) {
      _byId[e.id] = e;
    }
  }

  void _invalidate() {
    _recordsCache.clear();
    _historyIndex = null;
  }

  // ----------------------------------------------------------------- saving

  void _saveSettings() =>
      _prefs?.setString(_kSettings, jsonEncode(settings.toJson()));

  void _saveCustom() => _prefs?.setString(
    _kCustom,
    jsonEncode([
      for (final e in _custom)
        {...e.toJson(), if (_archived.contains(e.id)) 'archived': true},
    ]),
  );

  void _saveWorkouts() => _prefs?.setString(
    _kWorkouts,
    jsonEncode(workouts.map((w) => w.toJson()).toList()),
  );

  void _saveRoutines() => _prefs?.setString(
    _kRoutines,
    jsonEncode(routines.map((r) => r.toJson()).toList()),
  );

  void _saveBody() => _prefs?.setString(
    _kBody,
    jsonEncode(body.map((b) => b.toJson()).toList()),
  );

  void _saveActiveNow() {
    _activeSaveTimer?.cancel();
    if (active == null) {
      _prefs?.remove(_kActive);
    } else {
      _prefs?.setString(_kActive, jsonEncode(active!.toJson()));
    }
  }

  void _saveActiveSoon() {
    _activeSaveTimer?.cancel();
    _activeSaveTimer = Timer(const Duration(milliseconds: 400), _saveActiveNow);
  }

  // -------------------------------------------------------------- exercises

  /// Library exercises, alphabetical.
  List<Exercise> get exercises =>
      _byId.values.where((e) => !_archived.contains(e.id)).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Exercise exercise(String id) =>
      _byId[id] ??
      Exercise(
        id: id,
        name: 'Unknown exercise',
        muscle: 'Full Body',
        equipment: 'Other',
      );

  Exercise addCustomExercise({
    required String name,
    required String muscle,
    required String equipment,
    required ExerciseKind kind,
  }) {
    final e = Exercise(
      id: 'c_${newId()}',
      name: name,
      muscle: muscle,
      equipment: equipment,
      kind: kind,
      custom: true,
    );
    _custom.add(e);
    _rebuildIndex();
    _saveCustom();
    notifyListeners();
    return e;
  }

  void updateCustomExercise(
    Exercise e, {
    required String name,
    required String muscle,
    required String equipment,
  }) {
    e
      ..name = name
      ..muscle = muscle
      ..equipment = equipment;
    _saveCustom();
    notifyListeners();
  }

  /// Removes a custom exercise. If it appears in past workouts it is only
  /// hidden from the library so that history keeps its name.
  void deleteCustomExercise(Exercise e) {
    final used =
        historyFor(e.id).isNotEmpty ||
        (active?.entries.any((x) => x.exerciseId == e.id) ?? false);
    if (used) {
      _archived.add(e.id);
    } else {
      _custom.removeWhere((x) => x.id == e.id);
      _rebuildIndex();
    }
    for (final r in routines) {
      r.items.removeWhere((i) => i.exerciseId == e.id);
    }
    _saveRoutines();
    _saveCustom();
    notifyListeners();
  }

  // --------------------------------------------------------------- settings

  void updateSettings(void Function(Settings s) change) {
    change(settings);
    _saveSettings();
    notifyListeners();
  }

  // --------------------------------------------------------------- routines

  void saveRoutine(Routine r) {
    final i = routines.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      routines[i] = r;
    } else {
      routines.add(r);
    }
    _saveRoutines();
    notifyListeners();
  }

  void deleteRoutine(Routine r) {
    routines.removeWhere((x) => x.id == r.id);
    _saveRoutines();
    notifyListeners();
  }

  void duplicateRoutine(Routine r) {
    routines.insert(
      routines.indexOf(r) + 1,
      Routine(
        id: newId(),
        name: '${r.name} (copy)',
        note: r.note,
        items: r.items.map((i) => i.copy()).toList(),
      ),
    );
    _saveRoutines();
    notifyListeners();
  }

  /// Copies every day of a program into the user's routines.
  int addProgram(Program p) {
    var added = 0;
    for (final d in p.days) {
      if (routines.any((r) => r.name == d.name)) continue;
      routines.add(
        Routine(
          id: newId(),
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
      );
      added++;
    }
    _saveRoutines();
    notifyListeners();
    return added;
  }

  Routine routineFromWorkout(Workout w) => Routine(
    id: newId(),
    name: w.name,
    items: [
      for (final e in w.entries)
        RoutineItem(
          exerciseId: e.exerciseId,
          sets: max(1, e.workSets.length),
          repMin: e.repMin ?? 8,
          repMax: e.repMax ?? 12,
          restSec: e.restSec,
        ),
    ],
  );

  /// The routine to suggest next: the one after the most recently used.
  Routine? get nextRoutine {
    if (routines.isEmpty) return null;
    for (final w in workouts) {
      final i = routines.indexWhere((r) => r.id == w.routineId);
      if (i >= 0) return routines[(i + 1) % routines.length];
    }
    return routines.first;
  }

  DateTime? lastUsed(Routine r) {
    for (final w in workouts) {
      if (w.routineId == r.id) return w.start;
    }
    return null;
  }

  // --------------------------------------------------------- active workout

  void startEmpty() {
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'Morning'
        : h < 17
        ? 'Afternoon'
        : 'Evening';
    active = Workout(id: newId(), name: '$part Workout', start: DateTime.now());
    _saveActiveNow();
    notifyListeners();
  }

  void startFromRoutine(Routine r) {
    active = Workout(
      id: newId(),
      name: r.name,
      routineId: r.id,
      start: DateTime.now(),
      entries: [
        for (final i in r.items)
          WorkoutEntry(
            exerciseId: i.exerciseId,
            restSec: i.restSec,
            repMin: i.repMin > 0 ? i.repMin : null,
            repMax: i.repMax > 0 ? i.repMax : null,
            sets: List.generate(i.sets, (_) => SetEntry()),
          ),
      ],
    );
    _saveActiveNow();
    notifyListeners();
  }

  void repeatWorkout(Workout w) {
    active = Workout(
      id: newId(),
      name: w.name,
      routineId: w.routineId,
      start: DateTime.now(),
      entries: [
        for (final e in w.entries)
          WorkoutEntry(
            exerciseId: e.exerciseId,
            restSec: e.restSec,
            repMin: e.repMin,
            repMax: e.repMax,
            sets: [for (final s in e.sets) SetEntry(type: s.type)],
          ),
      ],
    );
    _saveActiveNow();
    notifyListeners();
  }

  void addExercisesToActive(List<String> ids) {
    final a = active;
    if (a == null) return;
    for (final id in ids) {
      a.entries.add(WorkoutEntry(exerciseId: id, sets: [SetEntry()]));
    }
    activeChanged();
  }

  /// Call after mutating [active] in place.
  void activeChanged({bool notify = true}) {
    _saveActiveSoon();
    if (notify) notifyListeners();
  }

  void discardActive() {
    active = null;
    restEndsAt = null;
    _saveActiveNow();
    notifyListeners();
  }

  int get activeDoneSets => active?.setCount ?? 0;

  /// Stores the workout in progress. Sets that were never ticked are dropped.
  FinishResult? finishActive() {
    final a = active;
    if (a == null) return null;
    for (final e in a.entries) {
      e.sets.removeWhere((s) => !s.done);
    }
    a.entries.removeWhere((e) => e.sets.isEmpty);
    if (a.entries.isEmpty) return null;

    final prs = <PrHit>[];
    for (final e in a.entries) {
      prs.addAll(_prsFor(e));
    }

    a.end = DateTime.now();
    workouts.insert(0, a);
    active = null;
    restEndsAt = null;
    _invalidate();
    _sort();
    _saveWorkouts();
    _saveActiveNow();
    notifyListeners();
    return FinishResult(a, prs);
  }

  List<PrHit> _prsFor(WorkoutEntry e) {
    final rec = recordsFor(e.exerciseId);
    if (rec.isEmpty) return const [];
    final ex = exercise(e.exerciseId);
    final sets = e.workSets.toList();
    if (sets.isEmpty) return const [];
    final out = <PrHit>[];
    if (ex.kind == ExerciseKind.timed) {
      final best = sets.map((s) => s.seconds ?? 0).reduce(max);
      if (best > rec.maxSeconds) {
        out.add(PrHit(ex.id, 'Longest time', fmtSeconds(best)));
      }
      return out;
    }
    final heaviest = sets.reduce(
      (a, b) => (b.weight ?? 0) > (a.weight ?? 0) ? b : a,
    );
    if ((heaviest.weight ?? 0) > rec.maxWeight + 1e-6) {
      out.add(
        PrHit(
          ex.id,
          'Heaviest weight',
          '${fmtWeight(heaviest.weight!, unit)} $unit × ${heaviest.reps ?? 0}',
        ),
      );
    }
    final e1 = sets.map((s) => s.e1rm).reduce(max);
    if (ex.kind == ExerciseKind.weighted && e1 > rec.bestE1rm + 1e-6) {
      out.add(
        PrHit(
          ex.id,
          'Best estimated 1RM',
          '${fmtNum(kgToUnit(e1, unit), decimals: 1)} $unit',
        ),
      );
    }
    if (ex.kind == ExerciseKind.bodyweight) {
      final reps = sets.map((s) => s.reps ?? 0).reduce(max);
      if (reps > rec.maxReps) out.add(PrHit(ex.id, 'Most reps', '$reps reps'));
    }
    return out;
  }

  /// Whether a ticked set in the active workout beats the stored records.
  bool isPrSet(String exerciseId, SetEntry s) {
    if (!s.done || s.isWarmup) return false;
    final rec = recordsFor(exerciseId);
    if (rec.isEmpty) return false;
    switch (exercise(exerciseId).kind) {
      case ExerciseKind.timed:
        return (s.seconds ?? 0) > rec.maxSeconds;
      case ExerciseKind.bodyweight:
        return (s.reps ?? 0) > rec.maxReps ||
            (s.weight ?? 0) > rec.maxWeight + 1e-6;
      case ExerciseKind.weighted:
        return (s.weight ?? 0) > rec.maxWeight + 1e-6 ||
            s.e1rm > rec.bestE1rm + 1e-6;
    }
  }

  // ------------------------------------------------------------- rest timer

  void startRest(int seconds) {
    if (seconds <= 0) return;
    restTotal = seconds;
    restEndsAt = DateTime.now().add(Duration(seconds: seconds));
    notifyListeners();
  }

  void adjustRest(int delta) {
    final end = restEndsAt;
    if (end == null) return;
    final next = end.add(Duration(seconds: delta));
    if (!next.isAfter(DateTime.now())) {
      stopRest();
      return;
    }
    restEndsAt = next;
    restTotal = max(1, restTotal + delta);
    notifyListeners();
  }

  void stopRest() {
    if (restEndsAt == null) return;
    restEndsAt = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- history

  void deleteWorkout(Workout w) {
    workouts.removeWhere((x) => x.id == w.id);
    _invalidate();
    _saveWorkouts();
    notifyListeners();
  }

  void renameWorkout(Workout w, String name) {
    w.name = name;
    _saveWorkouts();
    notifyListeners();
  }

  Map<String, List<(Workout, WorkoutEntry)>> get _history {
    final cached = _historyIndex;
    if (cached != null) return cached;
    final idx = <String, List<(Workout, WorkoutEntry)>>{};
    for (final w in workouts) {
      for (final e in w.entries) {
        if (e.doneSets.isEmpty) continue;
        (idx[e.exerciseId] ??= []).add((w, e));
      }
    }
    return _historyIndex = idx;
  }

  /// Every logged session of an exercise, newest first.
  List<(Workout, WorkoutEntry)> historyFor(String exerciseId) =>
      _history[exerciseId] ?? const [];

  /// Sets from the most recent session of an exercise.
  List<SetEntry> previousSets(String exerciseId) {
    final h = historyFor(exerciseId);
    return h.isEmpty ? const [] : h.first.$2.doneSets.toList();
  }

  Records recordsFor(String exerciseId) =>
      _recordsCache[exerciseId] ??= _computeRecords(exerciseId);

  Records _computeRecords(String exerciseId) {
    final r = Records();
    for (final (w, e) in historyFor(exerciseId)) {
      final sets = e.workSets;
      if (sets.isEmpty) continue;
      r.sessions++;
      r.bestSessionVolume = max(r.bestSessionVolume, e.volume);
      for (final s in sets) {
        final wt = s.weight ?? 0;
        if (wt > r.maxWeight) {
          r.maxWeight = wt;
          r.maxWeightReps = s.reps ?? 0;
          r.maxWeightDate = w.start;
        }
        if (s.e1rm > r.bestE1rm) {
          r.bestE1rm = s.e1rm;
          r.bestE1rmDate = w.start;
        }
        r.maxReps = max(r.maxReps, s.reps ?? 0);
        r.maxSeconds = max(r.maxSeconds, s.seconds ?? 0);
      }
    }
    return r;
  }

  /// A short progressive-overload hint based on the last session.
  String? suggestionFor(WorkoutEntry entry) {
    final ex = exercise(entry.exerciseId);
    if (ex.kind != ExerciseKind.weighted) return null;
    final h = historyFor(ex.id);
    if (h.isEmpty) return null;
    final sets = h.first.$2.workSets.where((s) => (s.weight ?? 0) > 0).toList();
    if (sets.isEmpty) return null;
    final top = sets.map((s) => s.weight!).reduce(max);
    final topSets = sets.where((s) => s.weight == top);
    final minReps = topSets.map((s) => s.reps ?? 0).reduce(min);
    final target = entry.repMax ?? 12;
    final step = unit == 'lb' ? 5 * kgPerLb : 2.5;
    if (minReps >= target) {
      return 'You hit $minReps reps on every set last time. '
          'Try ${fmtWeight(top + step, unit)} $unit.';
    }
    return 'Last time: ${fmtWeight(top, unit)} $unit × $minReps. '
        'Aim for ${minReps + 1}${entry.repMax != null ? '–$target' : '+'} reps.';
  }

  // ------------------------------------------------------------------ stats

  List<Workout> workoutsOn(DateTime day) =>
      workouts.where((w) => sameDay(w.start, day)).toList();

  List<Workout> workoutsSince(DateTime from) =>
      workouts.where((w) => !w.start.isBefore(from)).toList();

  List<Workout> get thisWeek => workoutsSince(weekStart(DateTime.now()));

  /// Consecutive weeks in which the weekly goal was met. The current week
  /// only counts once its goal is reached, but never breaks the streak.
  int get weekStreak {
    final counts = <DateTime, int>{};
    for (final w in workouts) {
      final k = weekStart(w.start);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final goal = max(1, settings.weeklyGoal);
    var week = weekStart(DateTime.now());
    var streak = 0;
    if ((counts[week] ?? 0) >= goal) streak++;
    while (true) {
      week = DateTime(week.year, week.month, week.day - 7);
      if ((counts[week] ?? 0) < goal) break;
      streak++;
    }
    return streak;
  }

  /// Workout counts for the last [n] weeks, oldest first.
  List<(DateTime, int)> weeklyCounts(int n) {
    final now = weekStart(DateTime.now());
    final out = <(DateTime, int)>[];
    for (var i = n - 1; i >= 0; i--) {
      final start = DateTime(now.year, now.month, now.day - 7 * i);
      final end = DateTime(start.year, start.month, start.day + 7);
      final c = workouts
          .where((w) => !w.start.isBefore(start) && w.start.isBefore(end))
          .length;
      out.add((start, c));
    }
    return out;
  }

  /// Working sets per primary muscle group since [from], largest first.
  List<MapEntry<String, int>> muscleSets(DateTime from) {
    final m = <String, int>{};
    for (final w in workoutsSince(from)) {
      for (final e in w.entries) {
        final n = e.workSets.length;
        if (n == 0) continue;
        final muscle = exercise(e.exerciseId).muscle;
        m[muscle] = (m[muscle] ?? 0) + n;
      }
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Exercises with records, strongest estimated 1RM first.
  List<(Exercise, Records)> get topRecords {
    final out = <(Exercise, Records)>[];
    for (final id in _history.keys) {
      final ex = exercise(id);
      if (ex.kind != ExerciseKind.weighted) continue;
      final r = recordsFor(id);
      if (r.bestE1rm > 0) out.add((ex, r));
    }
    out.sort((a, b) => b.$2.bestE1rm.compareTo(a.$2.bestE1rm));
    return out;
  }

  // ------------------------------------------------------------------- body

  void saveBodyEntry(BodyEntry b) {
    final i = body.indexWhere((x) => x.id == b.id);
    if (i >= 0) {
      body[i] = b;
    } else {
      body.add(b);
    }
    _sort();
    _saveBody();
    notifyListeners();
  }

  void deleteBodyEntry(BodyEntry b) {
    body.removeWhere((x) => x.id == b.id);
    _saveBody();
    notifyListeners();
  }

  double? get latestWeight {
    for (final b in body) {
      if (b.weight != null) return b.weight;
    }
    return null;
  }

  /// Most recent value of a measurement and the one before it.
  (double?, double?) latestMeasurement(String key) {
    double? latest;
    for (final b in body) {
      final v = b.measurements[key];
      if (v == null) continue;
      if (latest == null) {
        latest = v;
      } else {
        return (latest, v);
      }
    }
    return (latest, null);
  }

  // ----------------------------------------------------------------- backup

  String exportJson() => const JsonEncoder.withIndent(' ').convert({
    'app': 'gym_tracker',
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'settings': settings.toJson(),
    'customExercises': [
      for (final e in _custom)
        {...e.toJson(), if (_archived.contains(e.id)) 'archived': true},
    ],
    'workouts': workouts.map((w) => w.toJson()).toList(),
    'routines': routines.map((r) => r.toJson()).toList(),
    'body': body.map((b) => b.toJson()).toList(),
  });

  /// Replaces all data with a backup. Throws [FormatException] when the file
  /// is not a Gym Tracker backup; in that case nothing is changed.
  void importJson(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('This file is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'gym_tracker') {
      throw const FormatException('This is not a Gym Tracker backup file.');
    }
    final List<Workout> w;
    final List<Routine> r;
    final List<BodyEntry> b;
    final Settings s;
    try {
      s = Settings.fromJson(decoded['settings'] as Map<String, dynamic>? ?? {});
      w = _readList(jsonEncode(decoded['workouts'] ?? []), Workout.fromJson);
      r = _readList(jsonEncode(decoded['routines'] ?? []), Routine.fromJson);
      b = _readList(jsonEncode(decoded['body'] ?? []), BodyEntry.fromJson);
      _readCustom(jsonEncode(decoded['customExercises'] ?? []));
    } catch (_) {
      _readCustom(_prefs?.getString(_kCustom));
      throw const FormatException('The backup file is damaged.');
    }
    settings = s;
    workouts = w;
    routines = r;
    body = b;
    _sort();
    _rebuildIndex();
    _invalidate();
    _saveAll();
    notifyListeners();
  }

  void clearAll() {
    final keep = settings;
    workouts = [];
    routines = [];
    body = [];
    _custom.clear();
    _archived.clear();
    active = null;
    restEndsAt = null;
    settings = keep;
    _rebuildIndex();
    _invalidate();
    _saveAll();
    _saveActiveNow();
    notifyListeners();
  }

  /// Replaces workouts, routines and body log wholesale (used by demo data).
  void replaceData({
    required List<Workout> newWorkouts,
    required List<Routine> newRoutines,
    required List<BodyEntry> newBody,
  }) {
    workouts = newWorkouts;
    routines = newRoutines;
    body = newBody;
    _sort();
    _invalidate();
    _saveAll();
    notifyListeners();
  }

  void _saveAll() {
    _saveSettings();
    _saveCustom();
    _saveWorkouts();
    _saveRoutines();
    _saveBody();
  }
}
