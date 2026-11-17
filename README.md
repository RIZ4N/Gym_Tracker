# Gym Tracker

A workout tracker for Android and iOS, built with Flutter. Everything is stored
on the device: no account, no server, works offline.

## Features

- **Log workouts** – weight, reps or time per set, with warm-up / drop / failure
  set types, notes, and the values from your last session shown next to each set.
- **Rest timer** – starts automatically when you tick off a set; adjustable per
  exercise.
- **Routines** – build your own, or add a ready-made program (Full Body,
  Upper / Lower, Push / Pull / Legs, Strength 5×5, Bodyweight at Home).
- **Exercise library** – 96 built-in exercises with search and muscle filters,
  plus your own custom exercises.
- **Personal records** – detected live while you train and summarised when you
  finish; per-exercise charts for estimated 1RM, top weight and volume.
- **Progressive overload hints** – suggests more weight or more reps based on
  your last session.
- **Consistency** – weekly goal, week streak and a calendar of training days.
- **Progress** – totals, workouts per week, sets per muscle group.
- **Body tracking** – weight, body fat and tape measurements with a trend chart.
- **Tools** – 1RM calculator and plate calculator.
- **Settings** – kg / lb, dark / light theme, backup export and restore.

## Run it

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.50 or newer).

```bash
flutter pub get
```

```bash
flutter run
```

Build an installable Android APK:

```bash
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The
GitHub Actions workflow in `.github/workflows/build.yml` also builds it on every
push and attaches it to the run as the `gym-tracker-apk` artifact.

Run the checks:

```bash
flutter analyze
```

```bash
flutter test
```

To explore the app with data in it, open **Settings → Load demo data**.

## Project layout

```
lib/
  main.dart            app entry point
  theme.dart           colours, typography, component themes
  models.dart          data classes and JSON (de)serialisation
  state/app_state.dart app state, persistence, records, streaks, backup
  data/                exercise library, programs, demo data
  screens/             one file per screen
  widgets/             shared cards, charts, pickers
test/                  unit tests for the app logic
```
