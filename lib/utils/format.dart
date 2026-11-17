import 'package:intl/intl.dart';

const kgPerLb = 0.45359237;
const cmPerIn = 2.54;

/// Trims trailing zeros: 60.0 -> "60", 62.5 -> "62.5".
String fmtNum(double v, {int decimals = 2}) {
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

double kgToUnit(double kg, String unit) => unit == 'lb' ? kg / kgPerLb : kg;
double unitToKg(double v, String unit) => unit == 'lb' ? v * kgPerLb : v;

/// Weight in the user's unit, without the unit suffix.
String fmtWeight(double kg, String unit) =>
    fmtNum(kgToUnit(kg, unit), decimals: unit == 'lb' ? 1 : 2);

/// Large totals: 12 480 kg -> "12.5k".
String fmtVolume(double kg, String unit) {
  final v = kgToUnit(kg, unit);
  if (v >= 1000000) return '${fmtNum(v / 1000000, decimals: 2)}M';
  if (v >= 10000) return '${fmtNum(v / 1000, decimals: 1)}k';
  return NumberFormat.decimalPattern().format(v.round());
}

String lengthUnit(String unit) => unit == 'lb' ? 'in' : 'cm';
double cmToUnit(double cm, String unit) => unit == 'lb' ? cm / cmPerIn : cm;
double unitToCm(double v, String unit) => unit == 'lb' ? v * cmPerIn : v;
String fmtLength(double cm, String unit) =>
    fmtNum(cmToUnit(cm, unit), decimals: 1);

/// 3725 s -> "1h 02m", 540 s -> "9m".
String fmtDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  return '${d.inMinutes}m';
}

/// Stopwatch style: "1:02:05" or "02:05".
String fmtClock(Duration d) {
  final neg = d.isNegative;
  d = d.abs();
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final out = h > 0 ? '$h:$m:$s' : '$m:$s';
  return neg ? '-$out' : out;
}

/// Seconds for a timed set: 90 -> "1:30".
String fmtSeconds(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday of the week containing [d].
DateTime weekStart(DateTime d) {
  final day = dayOf(d);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String fmtDate(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);
String fmtShortDate(DateTime d) => DateFormat('d MMM').format(d);
String fmtTime(DateTime d) => DateFormat('HH:mm').format(d);

/// "Today", "Yesterday", "Mon, 3 Nov" or "3 Nov 2025".
String fmtRelativeDay(DateTime d) {
  final today = dayOf(DateTime.now());
  final diff = today.difference(dayOf(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7 && diff > 0) return DateFormat('EEEE').format(d);
  if (d.year == today.year) return DateFormat('EEE, d MMM').format(d);
  return DateFormat('d MMM yyyy').format(d);
}
