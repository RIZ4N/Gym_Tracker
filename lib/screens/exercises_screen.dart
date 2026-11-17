import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';

/// Exercises tab: the full library.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExerciseBrowser(
        title: 'Exercises',
        onTap: (e) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exerciseId: e.id),
          ),
        ),
      ),
    );
  }
}

/// Opens the library as a picker. Returns the chosen exercise ids, or null
/// when cancelled.
Future<List<String>?> pickExercises(
  BuildContext context, {
  bool single = false,
}) {
  return Navigator.of(context, rootNavigator: true).push<List<String>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PickerScreen(single: single),
    ),
  );
}

class _PickerScreen extends StatefulWidget {
  const _PickerScreen({required this.single});
  final bool single;

  @override
  State<_PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<_PickerScreen> {
  final List<String> _picked = [];

  @override
  Widget build(BuildContext context) {
    final n = _picked.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.single ? 'Choose exercise' : 'Add exercises'),
      ),
      body: ExerciseBrowser(
        selected: _picked,
        onTap: (e) {
          if (widget.single) {
            Navigator.pop(context, [e.id]);
            return;
          }
          setState(() {
            _picked.contains(e.id) ? _picked.remove(e.id) : _picked.add(e.id);
          });
        },
        onCreated: (e) => setState(() => _picked.add(e.id)),
      ),
      bottomNavigationBar: widget.single
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: n == 0
                      ? null
                      : () => Navigator.pop(context, _picked),
                  child: Text(
                    n == 0
                        ? 'Select exercises'
                        : 'Add $n ${n == 1 ? 'exercise' : 'exercises'}',
                  ),
                ),
              ),
            ),
    );
  }
}

/// Searchable, filterable exercise list shared by the tab and the picker.
class ExerciseBrowser extends StatefulWidget {
  const ExerciseBrowser({
    super.key,
    required this.onTap,
    this.title,
    this.selected,
    this.onCreated,
  });

  final String? title;
  final ValueChanged<Exercise> onTap;

  /// When set, rows show a check mark for these ids.
  final List<String>? selected;
  final ValueChanged<Exercise>? onCreated;

  @override
  State<ExerciseBrowser> createState() => _ExerciseBrowserState();
}

class _ExerciseBrowserState extends State<ExerciseBrowser> {
  String _query = '';
  String? _muscle;

  Future<void> _create() async {
    final e = await showExerciseEditor(context);
    if (e != null) widget.onCreated?.call(e);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final q = _query.toLowerCase();
    final list = s.exercises.where((e) {
      if (_muscle != null && e.muscle != _muscle) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          e.muscle.toLowerCase().contains(q) ||
          e.equipment.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
            child: Row(
              children: [
                Expanded(child: Text(widget.title!, style: t.headlineMedium)),
                TextButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search ${s.exercises.length} exercises',
              prefixIcon: Icon(Icons.search_rounded, color: p.muted),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              for (final m in [null, ...muscleGroups])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m ?? 'All'),
                    selected: _muscle == m,
                    onSelected: (_) => setState(() => _muscle = m),
                    labelStyle: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _muscle == m ? p.onAccent : p.text,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? SingleChildScrollView(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No exercises found',
                    message:
                        'Nothing matches your search. You can add it as a '
                        'custom exercise.',
                    actionLabel: 'Create exercise',
                    onAction: _create,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  itemCount: list.length + (widget.title == null ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == list.length) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                        child: OutlinedButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create custom exercise'),
                        ),
                      );
                    }
                    final e = list[i];
                    final picked = widget.selected?.contains(e.id) ?? false;
                    final sessions = s.historyFor(e.id).length;
                    return ListTile(
                      onTap: () => widget.onTap(e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      leading: ExerciseAvatar(e),
                      title: Text(e.name),
                      subtitle: Text(
                        [
                          e.muscle,
                          e.equipment,
                          if (e.custom) 'Custom',
                          if (sessions > 0)
                            '$sessions ${sessions == 1 ? 'session' : 'sessions'}',
                        ].join(' · '),
                      ),
                      trailing: widget.selected == null
                          ? Icon(Icons.chevron_right_rounded, color: p.muted)
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: picked ? p.accent : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: picked ? p.accent : p.line,
                                  width: 2,
                                ),
                              ),
                              child: picked
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: p.onAccent,
                                    )
                                  : null,
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Bottom sheet to create a custom exercise, or edit [existing].
Future<Exercise?> showExerciseEditor(
  BuildContext context, {
  Exercise? existing,
}) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => _ExerciseEditor(existing: existing),
  );
}

class _ExerciseEditor extends StatefulWidget {
  const _ExerciseEditor({this.existing});
  final Exercise? existing;

  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _muscle = widget.existing?.muscle ?? 'Chest';
  late String _equipment = widget.existing?.equipment ?? 'Barbell';
  late ExerciseKind _kind = widget.existing?.kind ?? ExerciseKind.weighted;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final s = context.read<AppState>();
    final ex = widget.existing;
    if (ex != null) {
      s.updateCustomExercise(
        ex,
        name: name,
        muscle: _muscle,
        equipment: _equipment,
      );
      Navigator.pop(context, ex);
    } else {
      Navigator.pop(
        context,
        s.addCustomExercise(
          name: name,
          muscle: _muscle,
          equipment: _equipment,
          kind: _kind,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Edit exercise' : 'New exercise',
              style: t.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _muscle,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Muscle group',
                    ),
                    items: [
                      for (final m in muscleGroups)
                        DropdownMenuItem(value: m, child: Text(m)),
                    ],
                    onChanged: (v) => setState(() => _muscle = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _equipment,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Equipment'),
                    items: [
                      for (final m in equipmentTypes)
                        DropdownMenuItem(value: m, child: Text(m)),
                    ],
                    onChanged: (v) => setState(() => _equipment = v!),
                  ),
                ),
              ],
            ),
            if (!editing) ...[
              const SizedBox(height: 16),
              Text('LOGGED AS', style: t.labelSmall),
              const SizedBox(height: 8),
              SegmentedButton<ExerciseKind>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ExerciseKind.weighted,
                    label: Text('Weight × reps'),
                  ),
                  ButtonSegment(
                    value: ExerciseKind.bodyweight,
                    label: Text('Reps'),
                  ),
                  ButtonSegment(value: ExerciseKind.timed, label: Text('Time')),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _name.text.trim().isEmpty ? null : _save,
              child: Text(editing ? 'Save changes' : 'Create exercise'),
            ),
          ],
        ),
      ),
    );
  }
}
