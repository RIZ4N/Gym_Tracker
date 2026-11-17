import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../utils/format.dart';

const restOptions = [30, 45, 60, 75, 90, 120, 150, 180, 240, 300];

/// Bottom sheet for choosing a rest duration. Returns seconds, or null when
/// dismissed.
Future<int?> pickRest(BuildContext context, int current) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (ctx) {
      final p = ctx.p;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rest timer', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Starts automatically when you tick off a set.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in restOptions)
                    ChoiceChip(
                      label: Text(fmtSeconds(s)),
                      selected: s == current,
                      onSelected: (_) => Navigator.pop(ctx, s),
                      labelStyle: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: s == current ? p.onAccent : p.text,
                        fontFeatures: tabular,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Parses "90" or "1:30" into seconds.
int? parseSeconds(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.contains(':')) {
    final parts = t.split(':');
    final m = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    final s = int.tryParse(
      parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '0',
    );
    if (m == null || s == null) return null;
    return m * 60 + s;
  }
  return int.tryParse(t);
}

/// Parses a decimal number, accepting a comma as the decimal separator.
double? parseDecimal(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.'));
