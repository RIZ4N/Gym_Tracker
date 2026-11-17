import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/seed.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'exercises_screen.dart';
import 'shell.dart';

String _repText(RoutineItem i) =>
    i.repMin == i.repMax ? '${i.repMin}' : '${i.repMin}–${i.repMax}';

/// Rough session length: working time plus rest for every set.
int estimateMinutes(Routine r, int defaultRest) {
  final secs = r.items.fold(
    0,
    (a, i) => a + i.sets * ((i.restSec ?? defaultRest) + 45),
  );
  return (secs / 60 / 5).ceil() * 5;
}

/// Workouts tab: quick start, the user's routines and ready-made programs.
class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  void _edit(BuildContext context, [Routine? r]) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => RoutineEditScreen(routine: r)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('Workouts', style: t.headlineMedium),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => startWorkout(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Start empty workout'),
        ),
        SectionHeader(
          'My routines',
          action: 'New routine',
          onAction: () => _edit(context),
        ),
        if (s.routines.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.list_alt_rounded,
              title: 'No routines yet',
              message:
                  'A routine is a saved list of exercises you can start with '
                  'one tap. Build your own or add a program below.',
              actionLabel: 'Create routine',
              onAction: () => _edit(context),
            ),
          ),
        for (final r in s.routines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RoutineCard(routine: r, onEdit: () => _edit(context, r)),
          ),
        const SectionHeader('Programs'),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Proven training plans. Adding one copies its workouts into your '
            'routines, where you can adjust them.',
            style: t.bodySmall,
          ),
        ),
        for (final pr in seedPrograms)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProgramDetailScreen(program: pr),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${pr.daysPerWeek}×',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pr.name, style: t.titleMedium),
                        const SizedBox(height: 2),
                        Text(pr.tagline, style: t.bodySmall),
                        const SizedBox(height: 6),
                        Pill(pr.level),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.onEdit});

  final Routine routine;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.read<AppState>();
    final r = routine;
    final last = s.lastUsed(r);
    final names = r.items.map((i) => s.exercise(i.exerciseId).name).toList();

    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: p.muted),
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'copy':
                      s.duplicateRoutine(r);
                    case 'delete':
                      final ok = await confirm(
                        context,
                        title: 'Delete routine?',
                        message:
                            '"${r.name}" will be removed. Workouts you already '
                            'logged with it are kept.',
                        confirmLabel: 'Delete',
                        destructive: true,
                      );
                      if (ok) s.deleteRoutine(r);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'copy', child: Text('Duplicate')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: p.danger)),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names.isEmpty ? 'No exercises yet' : names.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(color: p.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [
                          '${r.items.length} exercises',
                          if (r.items.isNotEmpty)
                            '~${estimateMinutes(r, s.settings.defaultRest)} min',
                          if (last != null) fmtRelativeDay(last),
                        ].join(' · '),
                        style: t.bodySmall,
                      ),
                    ),
                    FilledButton(
                      onPressed: r.items.isEmpty
                          ? null
                          : () => startWorkout(context, routine: r),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text('Start'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key, required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final pr = program;
    final added = pr.days.every((d) => s.routines.any((r) => r.name == d.name));

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pr.name, style: t.headlineMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    Pill(pr.level, color: p.accent),
                    Pill('${pr.daysPerWeek} days / week'),
                    Pill('${pr.days.length} workouts'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  pr.description,
                  style: t.bodyMedium?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final d in pr.days)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: t.titleMedium),
                    const SizedBox(height: 8),
                    for (final (id, sets, lo, hi, _) in d.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.exercise(id).name,
                                style: t.bodyMedium,
                              ),
                            ),
                            Text(
                              lo == 0
                                  ? '$sets sets'
                                  : lo == hi
                                  ? '$sets × $lo'
                                  : '$sets × $lo–$hi',
                              style: t.bodyMedium?.copyWith(
                                color: p.muted,
                                fontFeatures: tabular,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: added
                ? null
                : () {
                    final n = s.addProgram(pr);
                    toast(
                      context,
                      'Added $n ${n == 1 ? 'routine' : 'routines'} to My routines',
                    );
                  },
            icon: Icon(added ? Icons.check_rounded : Icons.add_rounded),
            label: Text(
              added ? 'Already in your routines' : 'Add to my routines',
            ),
          ),
        ),
      ),
    );
  }
}

class RoutineEditScreen extends StatefulWidget {
  const RoutineEditScreen({super.key, this.routine});

  final Routine? routine;

  @override
  State<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends State<RoutineEditScreen> {
  late final _name = TextEditingController(text: widget.routine?.name ?? '');
  late final List<RoutineItem> _items = [
    for (final i in widget.routine?.items ?? <RoutineItem>[]) i.copy(),
  ];
  bool _dirty = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      toast(context, 'Give your routine a name');
      return;
    }
    context.read<AppState>().saveRoutine(
      Routine(
        id: widget.routine?.id ?? newId(),
        name: name,
        note: widget.routine?.note ?? '',
        items: _items,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _add() async {
    final ids = await pickExercises(context);
    if (ids == null || ids.isEmpty || !mounted) return;
    final s = context.read<AppState>();
    setState(() {
      _dirty = true;
      for (final id in ids) {
        final timed = s.exercise(id).kind == ExerciseKind.timed;
        _items.add(
          RoutineItem(
            exerciseId: id,
            repMin: timed ? 0 : 8,
            repMax: timed ? 0 : 12,
          ),
        );
      }
    });
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    return confirm(
      context,
      title: 'Discard changes?',
      message: 'Your changes to this routine have not been saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.read<AppState>();

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.routine == null ? 'New routine' : 'Edit routine'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: ReorderableListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, _) =>
              Material(color: Colors.transparent, child: child),
          onReorderItem: (from, to) => setState(() {
            _dirty = true;
            _items.insert(to, _items.removeAt(from));
          }),
          header: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 14),
            child: TextField(
              controller: _name,
              autofocus: widget.routine == null,
              textCapitalization: TextCapitalization.words,
              style: t.titleMedium,
              decoration: const InputDecoration(
                labelText: 'Routine name',
                hintText: 'e.g. Push Day',
              ),
              onChanged: (_) => _dirty = true,
            ),
          ),
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_items.isEmpty)
                const EmptyState(
                  icon: Icons.playlist_add_rounded,
                  title: 'No exercises yet',
                  message:
                      'Add the exercises you want to do in this routine, then '
                      'set your target sets and reps.',
                ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add exercises'),
              ),
            ],
          ),
          children: [
            for (var i = 0; i < _items.length; i++)
              Padding(
                key: ObjectKey(_items[i]),
                padding: const EdgeInsets.only(bottom: 10),
                child: _itemCard(context, s, p, t, i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(
    BuildContext context,
    AppState s,
    Palette p,
    TextTheme t,
    int index,
  ) {
    final item = _items[index];
    final ex = s.exercise(item.exerciseId);
    final timed = ex.kind == ExerciseKind.timed;
    final rest = item.restSec ?? s.settings.defaultRest;

    Widget chip(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: p.cardHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: p.text,
                fontFeatures: tabular,
              ),
            ),
            Text(label, style: t.labelSmall),
          ],
        ),
      ),
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          builder: (_) => _ItemSheet(
            item: item,
            name: ex.name,
            timed: timed,
            defaultRest: s.settings.defaultRest,
          ),
        );
        setState(() => _dirty = true);
      },
      child: Column(
        children: [
          Row(
            children: [
              ExerciseAvatar(ex, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: t.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('${ex.muscle} · ${ex.equipment}', style: t.bodySmall),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: p.muted, size: 20),
                tooltip: 'Remove',
                onPressed: () => setState(() {
                  _dirty = true;
                  _items.removeAt(index);
                }),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.drag_indicator_rounded, color: p.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                chip('SETS', '${item.sets}'),
                const SizedBox(width: 8),
                chip(
                  timed ? 'LOGGED AS' : 'REPS',
                  timed ? 'Time' : _repText(item),
                ),
                const SizedBox(width: 8),
                chip('REST', fmtSeconds(rest)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet for editing one routine exercise's targets.
class _ItemSheet extends StatefulWidget {
  const _ItemSheet({
    required this.item,
    required this.name,
    required this.timed,
    required this.defaultRest,
  });

  final RoutineItem item;
  final String name;
  final bool timed;
  final int defaultRest;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = widget.item;
    final rest = item.restSec ?? widget.defaultRest;

    Widget row(String label, Widget control) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyLarge)),
          control,
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.name, style: t.titleLarge),
            const SizedBox(height: 10),
            row(
              'Sets',
              Stepper2(
                value: item.sets,
                min: 1,
                max: 12,
                onChanged: (v) => setState(() => item.sets = v),
              ),
            ),
            if (!widget.timed) ...[
              row(
                'Minimum reps',
                Stepper2(
                  value: item.repMin,
                  min: 1,
                  max: 50,
                  onChanged: (v) => setState(() {
                    item.repMin = v;
                    if (item.repMax < v) item.repMax = v;
                  }),
                ),
              ),
              row(
                'Maximum reps',
                Stepper2(
                  value: item.repMax,
                  min: 1,
                  max: 50,
                  onChanged: (v) => setState(() {
                    item.repMax = v;
                    if (item.repMin > v) item.repMin = v;
                  }),
                ),
              ),
            ],
            row(
              'Rest between sets',
              Stepper2(
                value: rest,
                min: 15,
                max: 600,
                step: 15,
                format: fmtSeconds,
                onChanged: (v) => setState(() => item.restSec = v),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
