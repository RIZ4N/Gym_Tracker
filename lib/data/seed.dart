import '../models.dart';

Exercise _e(
  String id,
  String name,
  String muscle,
  String equipment, {
  ExerciseKind kind = ExerciseKind.weighted,
  List<String> sec = const [],
}) => Exercise(
  id: id,
  name: name,
  muscle: muscle,
  equipment: equipment,
  kind: kind,
  secondary: sec,
);

const _bw = ExerciseKind.bodyweight;
const _timed = ExerciseKind.timed;

/// Built-in exercise library.
final List<Exercise> seedExercises = [
  // Chest
  _e(
    'bench_press',
    'Bench Press',
    'Chest',
    'Barbell',
    sec: ['Triceps', 'Shoulders'],
  ),
  _e(
    'incline_bench_press',
    'Incline Bench Press',
    'Chest',
    'Barbell',
    sec: ['Shoulders', 'Triceps'],
  ),
  _e(
    'decline_bench_press',
    'Decline Bench Press',
    'Chest',
    'Barbell',
    sec: ['Triceps'],
  ),
  _e(
    'db_bench_press',
    'Dumbbell Bench Press',
    'Chest',
    'Dumbbell',
    sec: ['Triceps', 'Shoulders'],
  ),
  _e(
    'incline_db_press',
    'Incline Dumbbell Press',
    'Chest',
    'Dumbbell',
    sec: ['Shoulders', 'Triceps'],
  ),
  _e('db_fly', 'Dumbbell Fly', 'Chest', 'Dumbbell'),
  _e(
    'machine_chest_press',
    'Machine Chest Press',
    'Chest',
    'Machine',
    sec: ['Triceps'],
  ),
  _e('pec_deck', 'Pec Deck Fly', 'Chest', 'Machine'),
  _e('cable_crossover', 'Cable Crossover', 'Chest', 'Cable'),
  _e(
    'push_up',
    'Push-Up',
    'Chest',
    'Bodyweight',
    kind: _bw,
    sec: ['Triceps', 'Shoulders'],
  ),
  _e(
    'chest_dip',
    'Chest Dip',
    'Chest',
    'Bodyweight',
    kind: _bw,
    sec: ['Triceps'],
  ),

  // Back
  _e('deadlift', 'Deadlift', 'Back', 'Barbell', sec: ['Hamstrings', 'Glutes']),
  _e('barbell_row', 'Barbell Row', 'Back', 'Barbell', sec: ['Biceps']),
  _e('t_bar_row', 'T-Bar Row', 'Back', 'Barbell', sec: ['Biceps']),
  _e('db_row', 'Dumbbell Row', 'Back', 'Dumbbell', sec: ['Biceps']),
  _e('pull_up', 'Pull-Up', 'Back', 'Bodyweight', kind: _bw, sec: ['Biceps']),
  _e('chin_up', 'Chin-Up', 'Back', 'Bodyweight', kind: _bw, sec: ['Biceps']),
  _e('lat_pulldown', 'Lat Pulldown', 'Back', 'Cable', sec: ['Biceps']),
  _e('seated_cable_row', 'Seated Cable Row', 'Back', 'Cable', sec: ['Biceps']),
  _e('machine_row', 'Machine Row', 'Back', 'Machine', sec: ['Biceps']),
  _e('straight_arm_pulldown', 'Straight-Arm Pulldown', 'Back', 'Cable'),
  _e(
    'back_extension',
    'Back Extension',
    'Back',
    'Bodyweight',
    kind: _bw,
    sec: ['Glutes', 'Hamstrings'],
  ),
  _e('shrug', 'Barbell Shrug', 'Back', 'Barbell'),
  _e('db_shrug', 'Dumbbell Shrug', 'Back', 'Dumbbell'),

  // Shoulders
  _e(
    'overhead_press',
    'Overhead Press',
    'Shoulders',
    'Barbell',
    sec: ['Triceps'],
  ),
  _e(
    'db_shoulder_press',
    'Dumbbell Shoulder Press',
    'Shoulders',
    'Dumbbell',
    sec: ['Triceps'],
  ),
  _e('arnold_press', 'Arnold Press', 'Shoulders', 'Dumbbell', sec: ['Triceps']),
  _e(
    'machine_shoulder_press',
    'Machine Shoulder Press',
    'Shoulders',
    'Machine',
    sec: ['Triceps'],
  ),
  _e('lateral_raise', 'Lateral Raise', 'Shoulders', 'Dumbbell'),
  _e('cable_lateral_raise', 'Cable Lateral Raise', 'Shoulders', 'Cable'),
  _e('front_raise', 'Front Raise', 'Shoulders', 'Dumbbell'),
  _e('rear_delt_fly', 'Rear Delt Fly', 'Shoulders', 'Dumbbell', sec: ['Back']),
  _e(
    'reverse_pec_deck',
    'Reverse Pec Deck',
    'Shoulders',
    'Machine',
    sec: ['Back'],
  ),
  _e('face_pull', 'Face Pull', 'Shoulders', 'Cable', sec: ['Back']),
  _e('upright_row', 'Upright Row', 'Shoulders', 'Barbell'),

  // Biceps
  _e('barbell_curl', 'Barbell Curl', 'Biceps', 'Barbell'),
  _e('ez_bar_curl', 'EZ-Bar Curl', 'Biceps', 'Barbell'),
  _e('db_curl', 'Dumbbell Curl', 'Biceps', 'Dumbbell'),
  _e('hammer_curl', 'Hammer Curl', 'Biceps', 'Dumbbell', sec: ['Forearms']),
  _e('incline_db_curl', 'Incline Dumbbell Curl', 'Biceps', 'Dumbbell'),
  _e('preacher_curl', 'Preacher Curl', 'Biceps', 'Machine'),
  _e('cable_curl', 'Cable Curl', 'Biceps', 'Cable'),
  _e('concentration_curl', 'Concentration Curl', 'Biceps', 'Dumbbell'),

  // Triceps
  _e(
    'close_grip_bench',
    'Close-Grip Bench Press',
    'Triceps',
    'Barbell',
    sec: ['Chest'],
  ),
  _e('skull_crusher', 'Skull Crusher', 'Triceps', 'Barbell'),
  _e('triceps_pushdown', 'Triceps Pushdown', 'Triceps', 'Cable'),
  _e('rope_pushdown', 'Rope Pushdown', 'Triceps', 'Cable'),
  _e('overhead_triceps_ext', 'Overhead Triceps Extension', 'Triceps', 'Cable'),
  _e('db_triceps_ext', 'Dumbbell Triceps Extension', 'Triceps', 'Dumbbell'),
  _e(
    'triceps_dip',
    'Triceps Dip',
    'Triceps',
    'Bodyweight',
    kind: _bw,
    sec: ['Chest'],
  ),
  _e('bench_dip', 'Bench Dip', 'Triceps', 'Bodyweight', kind: _bw),

  // Forearms
  _e('wrist_curl', 'Wrist Curl', 'Forearms', 'Dumbbell'),
  _e('reverse_curl', 'Reverse Curl', 'Forearms', 'Barbell', sec: ['Biceps']),
  _e(
    'farmers_walk',
    "Farmer's Walk",
    'Forearms',
    'Dumbbell',
    kind: _timed,
    sec: ['Core'],
  ),
  _e('dead_hang', 'Dead Hang', 'Forearms', 'Bodyweight', kind: _timed),

  // Quads
  _e('squat', 'Back Squat', 'Quads', 'Barbell', sec: ['Glutes', 'Hamstrings']),
  _e('front_squat', 'Front Squat', 'Quads', 'Barbell', sec: ['Glutes', 'Core']),
  _e('goblet_squat', 'Goblet Squat', 'Quads', 'Dumbbell', sec: ['Glutes']),
  _e('leg_press', 'Leg Press', 'Quads', 'Machine', sec: ['Glutes']),
  _e('hack_squat', 'Hack Squat', 'Quads', 'Machine', sec: ['Glutes']),
  _e('leg_extension', 'Leg Extension', 'Quads', 'Machine'),
  _e(
    'bulgarian_split_squat',
    'Bulgarian Split Squat',
    'Quads',
    'Dumbbell',
    sec: ['Glutes'],
  ),
  _e('walking_lunge', 'Walking Lunge', 'Quads', 'Dumbbell', sec: ['Glutes']),
  _e(
    'bodyweight_squat',
    'Bodyweight Squat',
    'Quads',
    'Bodyweight',
    kind: _bw,
    sec: ['Glutes'],
  ),

  // Hamstrings
  _e(
    'romanian_deadlift',
    'Romanian Deadlift',
    'Hamstrings',
    'Barbell',
    sec: ['Glutes', 'Back'],
  ),
  _e(
    'db_romanian_deadlift',
    'Dumbbell Romanian Deadlift',
    'Hamstrings',
    'Dumbbell',
    sec: ['Glutes'],
  ),
  _e('lying_leg_curl', 'Lying Leg Curl', 'Hamstrings', 'Machine'),
  _e('seated_leg_curl', 'Seated Leg Curl', 'Hamstrings', 'Machine'),
  _e(
    'good_morning',
    'Good Morning',
    'Hamstrings',
    'Barbell',
    sec: ['Back', 'Glutes'],
  ),

  // Glutes
  _e('hip_thrust', 'Hip Thrust', 'Glutes', 'Barbell', sec: ['Hamstrings']),
  _e('glute_bridge', 'Glute Bridge', 'Glutes', 'Bodyweight', kind: _bw),
  _e('cable_kickback', 'Cable Kickback', 'Glutes', 'Cable'),
  _e('hip_abduction', 'Hip Abduction', 'Glutes', 'Machine'),
  _e(
    'sumo_deadlift',
    'Sumo Deadlift',
    'Glutes',
    'Barbell',
    sec: ['Hamstrings', 'Back'],
  ),

  // Calves
  _e('standing_calf_raise', 'Standing Calf Raise', 'Calves', 'Machine'),
  _e('seated_calf_raise', 'Seated Calf Raise', 'Calves', 'Machine'),
  _e('leg_press_calf_raise', 'Leg Press Calf Raise', 'Calves', 'Machine'),

  // Core
  _e('plank', 'Plank', 'Core', 'Bodyweight', kind: _timed),
  _e('side_plank', 'Side Plank', 'Core', 'Bodyweight', kind: _timed),
  _e('crunch', 'Crunch', 'Core', 'Bodyweight', kind: _bw),
  _e('hanging_leg_raise', 'Hanging Leg Raise', 'Core', 'Bodyweight', kind: _bw),
  _e('lying_leg_raise', 'Lying Leg Raise', 'Core', 'Bodyweight', kind: _bw),
  _e('cable_crunch', 'Cable Crunch', 'Core', 'Cable'),
  _e('ab_wheel', 'Ab Wheel Rollout', 'Core', 'Other', kind: _bw),
  _e('russian_twist', 'Russian Twist', 'Core', 'Bodyweight', kind: _bw),
  _e('mountain_climber', 'Mountain Climber', 'Core', 'Bodyweight', kind: _bw),

  // Full body
  _e('power_clean', 'Power Clean', 'Full Body', 'Barbell'),
  _e(
    'kettlebell_swing',
    'Kettlebell Swing',
    'Full Body',
    'Kettlebell',
    sec: ['Glutes', 'Hamstrings'],
  ),
  _e(
    'thruster',
    'Thruster',
    'Full Body',
    'Barbell',
    sec: ['Quads', 'Shoulders'],
  ),
  _e('burpee', 'Burpee', 'Full Body', 'Bodyweight', kind: _bw),

  // Cardio
  _e('treadmill', 'Treadmill', 'Cardio', 'Machine', kind: _timed),
  _e('stationary_bike', 'Stationary Bike', 'Cardio', 'Machine', kind: _timed),
  _e('rowing_machine', 'Rowing Machine', 'Cardio', 'Machine', kind: _timed),
  _e('elliptical', 'Elliptical', 'Cardio', 'Machine', kind: _timed),
  _e('stair_climber', 'Stair Climber', 'Cardio', 'Machine', kind: _timed),
  _e('jump_rope', 'Jump Rope', 'Cardio', 'Other', kind: _timed),
];

/// Ready-made programs. Adding one copies its days into the user's routines.
const List<Program> seedPrograms = [
  Program(
    id: 'full_body',
    name: 'Full Body',
    tagline: 'Hit everything, three times a week',
    description:
        'Two alternating full-body sessions built on big compound lifts. '
        'Train A / B / A one week and B / A / B the next, with a rest day '
        'between sessions. The best place to start if you are new to lifting.',
    level: 'Beginner',
    daysPerWeek: 3,
    days: [
      ProgramDay('Full Body A', [
        ('squat', 3, 6, 10, 150),
        ('bench_press', 3, 6, 10, 150),
        ('barbell_row', 3, 8, 12, 120),
        ('db_shoulder_press', 2, 8, 12, 90),
        ('db_curl', 2, 10, 15, 60),
        ('plank', 3, 0, 0, 60),
      ]),
      ProgramDay('Full Body B', [
        ('romanian_deadlift', 3, 6, 10, 150),
        ('overhead_press', 3, 6, 10, 150),
        ('lat_pulldown', 3, 8, 12, 120),
        ('leg_press', 3, 10, 15, 120),
        ('triceps_pushdown', 2, 10, 15, 60),
        ('hanging_leg_raise', 3, 8, 15, 60),
      ]),
    ],
  ),
  Program(
    id: 'upper_lower',
    name: 'Upper / Lower',
    tagline: 'Four days, balanced strength and size',
    description:
        'Each half of the body twice a week: one heavier day and one '
        'higher-rep day. A common schedule is Mon / Tue / Thu / Fri.',
    level: 'Intermediate',
    daysPerWeek: 4,
    days: [
      ProgramDay('Upper · Strength', [
        ('bench_press', 4, 4, 6, 180),
        ('barbell_row', 4, 4, 6, 180),
        ('overhead_press', 3, 6, 8, 150),
        ('pull_up', 3, 6, 10, 120),
        ('skull_crusher', 3, 8, 12, 90),
        ('barbell_curl', 3, 8, 12, 90),
      ]),
      ProgramDay('Lower · Strength', [
        ('squat', 4, 4, 6, 180),
        ('romanian_deadlift', 3, 6, 8, 180),
        ('leg_press', 3, 8, 10, 120),
        ('lying_leg_curl', 3, 8, 12, 90),
        ('standing_calf_raise', 4, 8, 12, 60),
      ]),
      ProgramDay('Upper · Volume', [
        ('incline_db_press', 3, 8, 12, 120),
        ('lat_pulldown', 3, 8, 12, 120),
        ('machine_chest_press', 3, 10, 15, 90),
        ('seated_cable_row', 3, 10, 15, 90),
        ('lateral_raise', 4, 12, 20, 60),
        ('rope_pushdown', 3, 12, 15, 60),
        ('hammer_curl', 3, 12, 15, 60),
      ]),
      ProgramDay('Lower · Volume', [
        ('hack_squat', 3, 8, 12, 150),
        ('hip_thrust', 3, 8, 12, 120),
        ('leg_extension', 3, 12, 15, 90),
        ('seated_leg_curl', 3, 12, 15, 90),
        ('seated_calf_raise', 4, 12, 20, 60),
        ('cable_crunch', 3, 12, 15, 60),
      ]),
    ],
  ),
  Program(
    id: 'ppl',
    name: 'Push / Pull / Legs',
    tagline: 'The classic split, three to six days',
    description:
        'Push covers chest, shoulders and triceps; pull covers back and '
        'biceps; legs covers the lower body. Run the three days once a week, '
        'or twice through for a six-day split.',
    level: 'Intermediate',
    daysPerWeek: 6,
    days: [
      ProgramDay('Push', [
        ('bench_press', 4, 6, 10, 150),
        ('db_shoulder_press', 3, 8, 12, 120),
        ('incline_db_press', 3, 8, 12, 120),
        ('lateral_raise', 4, 12, 20, 60),
        ('triceps_pushdown', 3, 10, 15, 60),
        ('overhead_triceps_ext', 3, 10, 15, 60),
      ]),
      ProgramDay('Pull', [
        ('deadlift', 3, 4, 6, 180),
        ('pull_up', 3, 6, 10, 120),
        ('seated_cable_row', 3, 8, 12, 120),
        ('face_pull', 3, 12, 20, 60),
        ('barbell_curl', 3, 8, 12, 90),
        ('hammer_curl', 3, 10, 15, 60),
      ]),
      ProgramDay('Legs', [
        ('squat', 4, 6, 10, 180),
        ('romanian_deadlift', 3, 8, 12, 150),
        ('leg_press', 3, 10, 15, 120),
        ('lying_leg_curl', 3, 10, 15, 90),
        ('standing_calf_raise', 4, 10, 15, 60),
        ('hanging_leg_raise', 3, 8, 15, 60),
      ]),
    ],
  ),
  Program(
    id: 'strength_5x5',
    name: 'Strength 5×5',
    tagline: 'Three days, heavy barbell basics',
    description:
        'Five sets of five on the main barbell lifts, alternating two '
        'workouts. Add a little weight every session you complete all your '
        'reps. Simple and effective for building raw strength.',
    level: 'Beginner',
    daysPerWeek: 3,
    days: [
      ProgramDay('5×5 · Workout A', [
        ('squat', 5, 5, 5, 180),
        ('bench_press', 5, 5, 5, 180),
        ('barbell_row', 5, 5, 5, 180),
      ]),
      ProgramDay('5×5 · Workout B', [
        ('squat', 5, 5, 5, 180),
        ('overhead_press', 5, 5, 5, 180),
        ('deadlift', 1, 5, 5, 180),
      ]),
    ],
  ),
  Program(
    id: 'home_bodyweight',
    name: 'Bodyweight at Home',
    tagline: 'Just you and a pull-up bar',
    description:
        'Three simple sessions you can do anywhere. Aim to add a rep or two '
        'each week; once the top of the rep range feels easy, slow the '
        'movement down or move to a harder variation.',
    level: 'Beginner',
    daysPerWeek: 3,
    days: [
      ProgramDay('Bodyweight · Upper', [
        ('push_up', 4, 8, 20, 90),
        ('pull_up', 4, 4, 10, 120),
        ('bench_dip', 3, 8, 15, 90),
        ('plank', 3, 0, 0, 60),
      ]),
      ProgramDay('Bodyweight · Lower', [
        ('bodyweight_squat', 4, 15, 25, 90),
        ('glute_bridge', 4, 12, 20, 60),
        ('lying_leg_raise', 3, 10, 15, 60),
        ('side_plank', 3, 0, 0, 60),
      ]),
      ProgramDay('Bodyweight · Full', [
        ('burpee', 4, 8, 15, 90),
        ('push_up', 3, 8, 20, 90),
        ('bodyweight_squat', 3, 15, 25, 90),
        ('mountain_climber', 3, 20, 30, 60),
      ]),
    ],
  ),
];
