import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';

/// Body weight, body fat and tape measurements over time.
class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  void _edit(BuildContext context, [BodyEntry? entry]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BodySheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final unit = s.unit;
    final lu = lengthUnit(unit);
    final weights = [
      for (final b in s.body.reversed)
        if (b.weight != null) ChartPoint(b.date, kgToUnit(b.weight!, unit)),
    ];
    final change = weights.length < 2
        ? null
        : weights.last.value - weights.first.value;
    final measured = [
      for (final k in measurementKeys)
        if (s.latestMeasurement(k).$1 != null) (k, s.latestMeasurement(k)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Body tracking')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log entry'),
      ),
      body: s.body.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.monitor_weight_outlined,
                title: 'Nothing logged yet',
                message:
                    'Log your weight, body fat and measurements. Weigh in at '
                    'the same time of day for the most consistent trend.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                if (weights.isNotEmpty)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Weight', style: t.titleMedium),
                            ),
                            if (change != null)
                              Pill(
                                '${change >= 0 ? '+' : '−'}'
                                '${fmtNum(change.abs(), decimals: 1)} $unit overall',
                                color: p.blue,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LineChartView(
                          points: weights,
                          color: p.blue,
                          format: (v) => '${fmtNum(v, decimals: 1)} $unit',
                        ),
                      ],
                    ),
                  ),
                if (measured.isNotEmpty) ...[
                  const SectionHeader('Measurements'),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      for (final (k, (latest, before)) in measured)
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(k, style: t.labelMedium),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${fmtLength(latest!, unit)} $lu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: p.text,
                                    fontFeatures: tabular,
                                  ),
                                ),
                              ),
                              if (before != null)
                                Text(
                                  _delta(cmToUnit(latest - before, unit)),
                                  style: t.bodySmall?.copyWith(
                                    fontFeatures: tabular,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                const SectionHeader('Log'),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final b in s.body)
                        ListTile(
                          onTap: () => _edit(context, b),
                          title: Text(
                            [
                              if (b.weight != null)
                                '${fmtNum(kgToUnit(b.weight!, unit), decimals: 1)} $unit',
                              if (b.bodyFat != null)
                                '${fmtNum(b.bodyFat!, decimals: 1)}% fat',
                              if (b.weight == null && b.bodyFat == null)
                                'Measurements',
                            ].join(' · '),
                          ),
                          subtitle: Text(
                            [
                              fmtDate(b.date),
                              if (b.measurements.isNotEmpty)
                                '${b.measurements.length} measurements',
                            ].join(' · '),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                            tooltip: 'Delete',
                            onPressed: () async {
                              final ok = await confirm(
                                context,
                                title: 'Delete entry?',
                                message:
                                    'The entry from ${fmtDate(b.date)} will be '
                                    'removed.',
                                confirmLabel: 'Delete',
                                destructive: true,
                              );
                              if (ok) s.deleteBodyEntry(b);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _delta(double v) {
    if (v.abs() < 0.05) return 'No change';
    return '${v > 0 ? '+' : '−'}${fmtNum(v.abs(), decimals: 1)}';
  }
}

class _BodySheet extends StatefulWidget {
  const _BodySheet({this.entry});
  final BodyEntry? entry;

  @override
  State<_BodySheet> createState() => _BodySheetState();
}

class _BodySheetState extends State<_BodySheet> {
  late DateTime _date = widget.entry?.date ?? DateTime.now();
  final _weight = TextEditingController();
  final _fat = TextEditingController();
  final Map<String, TextEditingController> _m = {
    for (final k in measurementKeys) k: TextEditingController(),
  };
  late bool _showMeasurements = widget.entry?.measurements.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final unit = context.read<AppState>().unit;
    if (e == null) return;
    if (e.weight != null) _weight.text = fmtWeight(e.weight!, unit);
    if (e.bodyFat != null) _fat.text = fmtNum(e.bodyFat!, decimals: 1);
    e.measurements.forEach((k, v) => _m[k]?.text = fmtLength(v, unit));
  }

  @override
  void dispose() {
    _weight.dispose();
    _fat.dispose();
    for (final c in _m.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final s = context.read<AppState>();
    final unit = s.unit;
    final w = parseDecimal(_weight.text);
    final fat = parseDecimal(_fat.text);
    final ms = <String, double>{};
    _m.forEach((k, c) {
      final v = parseDecimal(c.text);
      if (v != null && v > 0) ms[k] = unitToCm(v, unit);
    });
    if ((w == null || w <= 0) && fat == null && ms.isEmpty) {
      toast(context, 'Enter at least one value');
      return;
    }
    s.saveBodyEntry(
      BodyEntry(
        id: widget.entry?.id ?? newId(),
        date: _date,
        weight: w != null && w > 0 ? unitToKg(w, unit) : null,
        bodyFat: fat,
        measurements: ms,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final unit = context.read<AppState>().unit;
    final lu = lengthUnit(unit);
    final decimal = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      LengthLimitingTextInputFormatter(6),
    ];
    const keyboard = TextInputType.numberWithOptions(decimal: true);

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.entry == null ? 'Log entry' : 'Edit entry',
                    style: t.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(fmtRelativeDay(_date)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    autofocus: widget.entry == null,
                    keyboardType: keyboard,
                    inputFormatters: decimal,
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: unit,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _fat,
                    keyboardType: keyboard,
                    inputFormatters: decimal,
                    decoration: const InputDecoration(
                      labelText: 'Body fat',
                      suffixText: '%',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_showMeasurements)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showMeasurements = true),
                  icon: const Icon(Icons.straighten_rounded, size: 18),
                  label: const Text('Add measurements'),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              Text('MEASUREMENTS ($lu)', style: t.labelSmall),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  for (final k in measurementKeys)
                    TextField(
                      controller: _m[k],
                      keyboardType: keyboard,
                      inputFormatters: decimal,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                      decoration: InputDecoration(
                        labelText: k,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
