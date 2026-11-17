import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/demo.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context, AppState s) async {
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final name = 'gym-tracker-backup-$stamp.json';
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(s.exportJson()),
              mimeType: 'application/json',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          subject: 'Gym Tracker backup',
        ),
      );
    } catch (e) {
      if (context.mounted) toast(context, 'Could not export the backup');
    }
  }

  Future<void> _import(BuildContext context, AppState s) async {
    final String raw;
    try {
      final file = await FilePicker.pickFile();
      if (file == null) return;
      raw = utf8.decode(await file.readAsBytes());
    } catch (e) {
      if (context.mounted) toast(context, 'Could not read that file');
      return;
    }
    if (!context.mounted) return;
    final ok = await confirm(
      context,
      title: 'Restore backup?',
      message:
          'This replaces all workouts, routines and body data currently in '
          'the app with the contents of the backup.',
      confirmLabel: 'Restore',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      s.importJson(raw);
      toast(context, 'Backup restored');
    } on FormatException catch (e) {
      toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final st = s.settings;

    Widget group(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 22, 0, 8),
          child: Text(title.toUpperCase(), style: t.labelSmall),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: children),
        ),
      ],
    );

    Widget value(String text) => Text(
      text,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: p.accent,
        fontFeatures: tabular,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          group('Profile', [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Your name'),
              trailing: value(st.name.isEmpty ? 'Add' : st.name),
              onTap: () async {
                final name = await promptText(
                  context,
                  title: 'Your name',
                  initial: st.name,
                  hint: 'Shown on the home screen',
                );
                if (name != null) s.updateSettings((x) => x.name = name);
              },
            ),
          ]),
          group('Training', [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Weekly goal'),
              subtitle: const Text('Workouts per week, used for your streak'),
              trailing: Stepper2(
                value: st.weeklyGoal,
                min: 1,
                max: 7,
                onChanged: (v) => s.updateSettings((x) => x.weeklyGoal = v),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.scale_outlined),
              title: const Text('Units'),
              trailing: SegmentedButton<String>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: 'kg', label: Text('kg')),
                  ButtonSegment(value: 'lb', label: Text('lb')),
                ],
                selected: {st.unit},
                onSelectionChanged: (v) =>
                    s.updateSettings((x) => x.unit = v.first),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Default rest timer'),
              trailing: value(fmtSeconds(st.defaultRest)),
              onTap: () async {
                final r = await pickRest(context, st.defaultRest);
                if (r != null) s.updateSettings((x) => x.defaultRest = r);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.play_circle_outline_rounded),
              title: const Text('Start rest automatically'),
              subtitle: const Text('When you tick off a set'),
              value: st.autoRest,
              onChanged: (v) => s.updateSettings((x) => x.autoRest = v),
            ),
          ]),
          group('Appearance', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'dark',
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: 'light',
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: 'system',
                      icon: Icon(Icons.phone_android_rounded, size: 18),
                      label: Text('System'),
                    ),
                  ],
                  selected: {st.theme},
                  onSelectionChanged: (v) =>
                      s.updateSettings((x) => x.theme = v.first),
                ),
              ),
            ),
          ]),
          group('Your data', [
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Export backup'),
              subtitle: const Text('Save everything to a file you can keep'),
              onTap: () => _export(context, s),
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Restore from backup'),
              subtitle: const Text('Replace current data with a backup file'),
              onTap: () => _import(context, s),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Load demo data'),
              subtitle: const Text('Ten weeks of sample workouts to explore'),
              onTap: () async {
                final ok = await confirm(
                  context,
                  title: 'Load demo data?',
                  message:
                      'This replaces your current workouts, routines and body '
                      'log with sample data.',
                  confirmLabel: 'Load',
                  destructive: s.workouts.isNotEmpty,
                );
                if (!ok || !context.mounted) return;
                final d = buildDemoData();
                s.replaceData(
                  newWorkouts: d.workouts,
                  newRoutines: d.routines,
                  newBody: d.body,
                );
                toast(context, 'Demo data loaded');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: p.danger),
              title: Text('Delete all data', style: TextStyle(color: p.danger)),
              onTap: () async {
                final ok = await confirm(
                  context,
                  title: 'Delete all data?',
                  message:
                      'Every workout, routine, custom exercise and body entry '
                      'will be permanently deleted from this device.',
                  confirmLabel: 'Delete everything',
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                s.clearAll();
                toast(context, 'All data deleted');
              },
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Gym Tracker 1.0.0\nYour data stays on this device.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
