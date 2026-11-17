import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';

final _decimalInput = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  LengthLimitingTextInputFormatter(7),
];

/// Estimates a one-rep max from a weight and rep count.
class OneRmScreen extends StatefulWidget {
  const OneRmScreen({super.key});

  @override
  State<OneRmScreen> createState() => _OneRmScreenState();
}

class _OneRmScreenState extends State<OneRmScreen> {
  final _weight = TextEditingController();
  final _reps = TextEditingController();

  static const _table = [
    (100, 1),
    (95, 2),
    (90, 4),
    (85, 6),
    (80, 8),
    (75, 10),
    (70, 12),
    (65, 15),
    (60, 18),
  ];

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final unit = context.watch<AppState>().unit;
    final w = parseDecimal(_weight.text) ?? 0;
    final r = int.tryParse(_reps.text) ?? 0;
    final valid = w > 0 && r > 0;
    // Epley for the estimate, the same formula used for records in the app.
    final oneRm = !valid
        ? 0.0
        : r == 1
        ? w
        : w * (1 + min(r, 12) / 30);

    return Scaffold(
      appBar: AppBar(title: const Text('1RM calculator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            'Enter a set you completed with good form. Estimates are most '
            'accurate for sets of 10 reps or fewer.',
            style: t.bodyMedium?.copyWith(color: p.muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weight,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _decimalInput,
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    suffixText: unit,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'Reps'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            color: p.accent,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'ESTIMATED ONE-REP MAX',
                  style: t.labelSmall?.copyWith(
                    color: p.onAccent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valid ? '${fmtNum(oneRm, decimals: 1)} $unit' : '—',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: p.onAccent,
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ),
          ),
          if (valid) ...[
            const SectionHeader('Training loads'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  for (final (pct, reps) in _table)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Text(
                              '$pct%',
                              style: t.bodyMedium?.copyWith(
                                color: p.muted,
                                fontFeatures: tabular,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${fmtNum(oneRm * pct / 100, decimals: 1)} $unit',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: p.text,
                                fontFeatures: tabular,
                              ),
                            ),
                          ),
                          Text(
                            '~$reps ${reps == 1 ? 'rep' : 'reps'}',
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
          ],
        ],
      ),
    );
  }
}

/// Works out which plates to load on each side of the bar.
class PlateCalcScreen extends StatefulWidget {
  const PlateCalcScreen({super.key});

  @override
  State<PlateCalcScreen> createState() => _PlateCalcScreenState();
}

class _PlateCalcScreenState extends State<PlateCalcScreen> {
  final _target = TextEditingController();
  double? _bar;

  static const _kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  static const _lbPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];
  static const _kgBars = [20.0, 15.0, 10.0];
  static const _lbBars = [45.0, 35.0, 15.0];

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final t = Theme.of(context).textTheme;
    final s = context.watch<AppState>();
    final unit = s.unit;
    final lb = unit == 'lb';
    final plates = lb ? _lbPlates : _kgPlates;
    final bars = lb ? _lbBars : _kgBars;
    final bar = _bar != null && bars.contains(_bar)
        ? _bar!
        : (lb
              ? 45.0
              : (bars.contains(s.settings.barWeight)
                    ? s.settings.barWeight
                    : 20.0));
    final target = parseDecimal(_target.text) ?? 0;

    final perSide = <double>[];
    var remaining = (target - bar) / 2;
    if (remaining > 0) {
      for (final pl in plates) {
        while (remaining >= pl - 1e-9) {
          perSide.add(pl);
          remaining -= pl;
        }
      }
    }
    final loaded = bar + perSide.fold(0.0, (a, b) => a + b) * 2;
    final exact = target > 0 && (loaded - target).abs() < 1e-6;
    final counts = <double, int>{};
    for (final pl in perSide) {
      counts[pl] = (counts[pl] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Plate calculator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          TextField(
            controller: _target,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _decimalInput,
            decoration: InputDecoration(
              labelText: 'Target weight',
              suffixText: unit,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Text('BAR WEIGHT', style: t.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final b in bars)
                ChoiceChip(
                  label: Text('${fmtNum(b)} $unit'),
                  selected: bar == b,
                  onSelected: (_) => setState(() => _bar = b),
                  labelStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: bar == b ? p.onAccent : p.text,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BarbellPainter(
                      plates: perSide,
                      largest: plates.first,
                      bar: p.muted,
                      plate: p.accent,
                      text: p.onAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  target <= 0
                      ? 'Enter a target weight'
                      : target < bar
                      ? 'That is lighter than the bar'
                      : perSide.isEmpty
                      ? 'Just the empty bar'
                      : 'Each side',
                  style: t.labelMedium,
                ),
                if (perSide.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in counts.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: p.cardHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${e.value} × ${fmtNum(e.key)} $unit',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: p.text,
                              fontFeatures: tabular,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (target >= bar && !exact) ...[
            const SizedBox(height: 10),
            AppCard(
              border: p.gold.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: p.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Standard plates cannot make exactly '
                      '${fmtNum(target)} $unit. The closest load below it is '
                      '${fmtNum(loaded)} $unit.',
                      style: t.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarbellPainter extends CustomPainter {
  _BarbellPainter({
    required this.plates,
    required this.largest,
    required this.bar,
    required this.plate,
    required this.text,
  });

  final List<double> plates;
  final double largest;
  final Color bar;
  final Color plate;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final barPaint = Paint()..color = bar;
    // Shaft, collar and sleeve of one end of the bar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - 4, size.width * 0.22, 8),
        const Radius.circular(4),
      ),
      barPaint,
    );
    final collarX = size.width * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(collarX, cy - 13, 10, 26),
        const Radius.circular(3),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(collarX + 10, cy - 7, size.width - collarX - 10, 14),
        const Radius.circular(4),
      ),
      barPaint..color = bar.withValues(alpha: 0.55),
    );

    var x = collarX + 14;
    final avail = size.width - x - 8;
    final w = plates.isEmpty
        ? 0.0
        : min(30.0, (avail - plates.length * 3) / plates.length);
    for (final pl in plates) {
      final h = size.height * (0.38 + 0.62 * sqrt(pl / largest));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, cy - h / 2, w, h),
          const Radius.circular(5),
        ),
        Paint()..color = plate.withValues(alpha: 0.55 + 0.45 * (pl / largest)),
      );
      if (w >= 20) {
        final tp = TextPainter(
          text: TextSpan(
            text: fmtNum(pl),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + (w - tp.width) / 2, cy - tp.height / 2));
      }
      x += w + 3;
    }
  }

  @override
  bool shouldRepaint(_BarbellPainter old) =>
      old.plates.length != plates.length ||
      old.plates.join() != plates.join() ||
      old.plate != plate;
}
