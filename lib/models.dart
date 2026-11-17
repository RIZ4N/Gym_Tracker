import 'dart:math';

final _rand = Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${_rand.nextInt(1 << 20).toRadixString(36)}';

/// How an exercise is logged.
enum ExerciseKind { weighted, bodyweight, timed }

enum SetType { normal, warmup, drop, failure }

const muscleGroups = [
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Forearms',
  'Core',
  'Quads',
  'Hamstrings',
  'Glutes',
  'Calves',
  'Full Body',
  'Cardio',
];

const equipmentTypes = [
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Bodyweight',
  'Kettlebell',
  'Band',
  'Other',
];

/// Body measurements, stored in centimetres.
const measurementKeys = [
  'Neck',
  'Shoulders',
  'Chest',
  'Biceps',
  'Forearm',
  'Waist',
  'Hips',
  'Thigh',
  'Calf',
];

class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.equipment,
    this.kind = ExerciseKind.weighted,
    this.secondary = const [],
    this.custom = false,
  });

  final String id;
  String name;
  String muscle;
  String equipment;
  ExerciseKind kind;
  List<String> secondary;
  final bool custom;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'muscle': muscle,
    'equipment': equipment,
    'kind': kind.name,
    'secondary': secondary,
  };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as String,
    name: j['name'] as String,
    muscle: j['muscle'] as String,
    equipment: j['equipment'] as String,
    kind: ExerciseKind.values.byName(j['kind'] as String? ?? 'weighted'),
    secondary: (j['secondary'] as List? ?? const []).cast<String>(),
    custom: true,
  );
}

class SetEntry {
  SetEntry({
    this.weight,
    this.reps,
    this.seconds,
    this.type = SetType.normal,
    this.done = false,
  });

  /// Always stored in kilograms.
  double? weight;
  int? reps;
  int? seconds;
  SetType type;
  bool done;

  bool get isWarmup => type == SetType.warmup;

  /// Load moved by this set, in kg.
  double get volume => (weight ?? 0) * (reps ?? 0);

  /// Estimated one-rep max (Epley). Only meaningful for 1-12 reps.
  double get e1rm {
    final w = weight ?? 0, r = reps ?? 0;
    if (w <= 0 || r <= 0) return 0;
    if (r == 1) return w;
    return w * (1 + min(r, 12) / 30);
  }

  SetEntry copy({bool? done}) => SetEntry(
    weight: weight,
    reps: reps,
    seconds: seconds,
    type: type,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {
    if (weight != null) 'w': weight,
    if (reps != null) 'r': reps,
    if (seconds != null) 's': seconds,
    if (type != SetType.normal) 't': type.name,
    'd': done,
  };

  factory SetEntry.fromJson(Map<String, dynamic> j) => SetEntry(
    weight: (j['w'] as num?)?.toDouble(),
    reps: (j['r'] as num?)?.toInt(),
    seconds: (j['s'] as num?)?.toInt(),
    type: SetType.values.byName(j['t'] as String? ?? 'normal'),
    done: j['d'] as bool? ?? false,
  );
}

class WorkoutEntry {
  WorkoutEntry({
    required this.exerciseId,
    List<SetEntry>? sets,
    this.note = '',
    this.restSec,
    this.repMin,
    this.repMax,
  }) : sets = sets ?? [];

  final String exerciseId;
  List<SetEntry> sets;
  String note;

  /// Rest between sets; falls back to the default in settings when null.
  int? restSec;
  int? repMin;
  int? repMax;

  Iterable<SetEntry> get doneSets => sets.where((s) => s.done);
  Iterable<SetEntry> get workSets => doneSets.where((s) => !s.isWarmup);
  double get volume => doneSets.fold(0, (a, s) => a + s.volume);

  Map<String, dynamic> toJson() => {
    'ex': exerciseId,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (note.isNotEmpty) 'note': note,
    if (restSec != null) 'rest': restSec,
    if (repMin != null) 'min': repMin,
    if (repMax != null) 'max': repMax,
  };

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
    exerciseId: j['ex'] as String,
    sets: (j['sets'] as List)
        .map((s) => SetEntry.fromJson(s as Map<String, dynamic>))
        .toList(),
    note: j['note'] as String? ?? '',
    restSec: (j['rest'] as num?)?.toInt(),
    repMin: (j['min'] as num?)?.toInt(),
    repMax: (j['max'] as num?)?.toInt(),
  );
}

class Workout {
  Workout({
    required this.id,
    required this.name,
    required this.start,
    this.end,
    this.routineId,
    this.note = '',
    List<WorkoutEntry>? entries,
  }) : entries = entries ?? [];

  final String id;
  String name;
  DateTime start;
  DateTime? end;
  String? routineId;
  String note;
  List<WorkoutEntry> entries;

  Duration get duration => (end ?? DateTime.now()).difference(start);
  double get volume => entries.fold(0, (a, e) => a + e.volume);
  int get setCount => entries.fold(0, (a, e) => a + e.doneSets.length);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': start.toIso8601String(),
    if (end != null) 'end': end!.toIso8601String(),
    if (routineId != null) 'routine': routineId,
    if (note.isNotEmpty) 'note': note,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    id: j['id'] as String,
    name: j['name'] as String,
    start: DateTime.parse(j['start'] as String),
    end: j['end'] == null ? null : DateTime.parse(j['end'] as String),
    routineId: j['routine'] as String?,
    note: j['note'] as String? ?? '',
    entries: (j['entries'] as List)
        .map((e) => WorkoutEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class RoutineItem {
  RoutineItem({
    required this.exerciseId,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.restSec,
  });

  final String exerciseId;
  int sets;
  int repMin;
  int repMax;
  int? restSec;

  RoutineItem copy() => RoutineItem(
    exerciseId: exerciseId,
    sets: sets,
    repMin: repMin,
    repMax: repMax,
    restSec: restSec,
  );

  Map<String, dynamic> toJson() => {
    'ex': exerciseId,
    'sets': sets,
    'min': repMin,
    'max': repMax,
    if (restSec != null) 'rest': restSec,
  };

  factory RoutineItem.fromJson(Map<String, dynamic> j) => RoutineItem(
    exerciseId: j['ex'] as String,
    sets: (j['sets'] as num?)?.toInt() ?? 3,
    repMin: (j['min'] as num?)?.toInt() ?? 8,
    repMax: (j['max'] as num?)?.toInt() ?? 12,
    restSec: (j['rest'] as num?)?.toInt(),
  );
}

class Routine {
  Routine({
    required this.id,
    required this.name,
    this.note = '',
    List<RoutineItem>? items,
  }) : items = items ?? [];

  final String id;
  String name;
  String note;
  List<RoutineItem> items;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (note.isNotEmpty) 'note': note,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: j['id'] as String,
    name: j['name'] as String,
    note: j['note'] as String? ?? '',
    items: (j['items'] as List)
        .map((i) => RoutineItem.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}

class BodyEntry {
  BodyEntry({
    required this.id,
    required this.date,
    this.weight,
    this.bodyFat,
    Map<String, double>? measurements,
  }) : measurements = measurements ?? {};

  final String id;
  DateTime date;

  /// Kilograms.
  double? weight;

  /// Percent.
  double? bodyFat;

  /// Centimetres, keyed by [measurementKeys].
  Map<String, double> measurements;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    if (weight != null) 'weight': weight,
    if (bodyFat != null) 'fat': bodyFat,
    if (measurements.isNotEmpty) 'm': measurements,
  };

  factory BodyEntry.fromJson(Map<String, dynamic> j) => BodyEntry(
    id: j['id'] as String,
    date: DateTime.parse(j['date'] as String),
    weight: (j['weight'] as num?)?.toDouble(),
    bodyFat: (j['fat'] as num?)?.toDouble(),
    measurements: (j['m'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
  );
}

class Settings {
  String name = '';
  String unit = 'kg';
  int weeklyGoal = 4;
  int defaultRest = 90;
  bool autoRest = true;

  /// 'system', 'dark' or 'light'.
  String theme = 'dark';

  /// Kilograms.
  double barWeight = 20;

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'weeklyGoal': weeklyGoal,
    'defaultRest': defaultRest,
    'autoRest': autoRest,
    'theme': theme,
    'barWeight': barWeight,
  };

  static Settings fromJson(Map<String, dynamic> j) => Settings()
    ..name = j['name'] as String? ?? ''
    ..unit = j['unit'] as String? ?? 'kg'
    ..weeklyGoal = (j['weeklyGoal'] as num?)?.toInt() ?? 4
    ..defaultRest = (j['defaultRest'] as num?)?.toInt() ?? 90
    ..autoRest = j['autoRest'] as bool? ?? true
    ..theme = j['theme'] as String? ?? 'dark'
    ..barWeight = (j['barWeight'] as num?)?.toDouble() ?? 20;
}

/// A ready-made training plan made of several routines.
class Program {
  const Program({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.level,
    required this.daysPerWeek,
    required this.days,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String level;
  final int daysPerWeek;
  final List<ProgramDay> days;
}

class ProgramDay {
  const ProgramDay(this.name, this.items);
  final String name;

  /// (exerciseId, sets, repMin, repMax, restSec)
  final List<(String, int, int, int, int)> items;
}

/// Best lifts for one exercise.
class Records {
  double maxWeight = 0;
  int maxWeightReps = 0;
  DateTime? maxWeightDate;
  double bestE1rm = 0;
  DateTime? bestE1rmDate;
  double bestSessionVolume = 0;
  int maxReps = 0;
  int maxSeconds = 0;
  int sessions = 0;

  bool get isEmpty => sessions == 0;
}

/// A record broken during a workout.
class PrHit {
  PrHit(this.exerciseId, this.label, this.value);
  final String exerciseId;
  final String label;
  final String value;
}
