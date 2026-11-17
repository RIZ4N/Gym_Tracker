import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../utils/format.dart';

class ChartPoint {
  const ChartPoint(this.date, this.value);
  final DateTime date;
  final double value;
}

/// Line chart over time. Drag across it to read individual values.
class LineChartView extends StatefulWidget {
  const LineChartView({
    super.key,
    required this.points,
    required this.format,
    this.height = 180,
    this.color,
  });

  /// Oldest first.
  final List<ChartPoint> points;
  final String Function(double) format;
  final double height;
  final Color? color;

  @override
  State<LineChartView> createState() => _LineChartViewState();
}

class _LineChartViewState extends State<LineChartView> {
  int? _selected;

  void _pick(Offset local, double width) {
    final n = widget.points.length;
    if (n == 0) return;
    const left = _LinePainter.padLeft, right = _LinePainter.padRight;
    final w = width - left - right;
    final t = n == 1 ? 0.0 : ((local.dx - left) / w).clamp(0.0, 1.0);
    final i = (t * (n - 1)).round();
    if (i != _selected) setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final pts = widget.points;
    final color = widget.color ?? p.accent;
    final sel = _selected != null && _selected! < pts.length
        ? pts[_selected!]
        : (pts.isEmpty ? null : pts.last);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sel != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.format(sel.value),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: p.text,
                  fontFeatures: tabular,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  fmtRelativeDay(sel.date),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _pick(d.localPosition, c.maxWidth),
            onHorizontalDragUpdate: (d) => _pick(d.localPosition, c.maxWidth),
            onHorizontalDragEnd: (_) => setState(() => _selected = null),
            onTapUp: (_) => Future.delayed(
              const Duration(seconds: 2),
              () => mounted ? setState(() => _selected = null) : null,
            ),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(
                painter: _LinePainter(
                  points: pts,
                  color: color,
                  grid: p.line,
                  label: p.muted,
                  bg: p.card,
                  selected: _selected,
                  format: widget.format,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.color,
    required this.grid,
    required this.label,
    required this.bg,
    required this.selected,
    required this.format,
  });

  static const padLeft = 8.0, padRight = 44.0, padTop = 8.0, padBottom = 22.0;

  final List<ChartPoint> points;
  final Color color;
  final Color grid;
  final Color label;
  final Color bg;
  final int? selected;
  final String Function(double) format;

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: label,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - padLeft - padRight;
    final h = size.height - padTop - padBottom;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    if (points.isEmpty) return;
    var lo = points.map((p) => p.value).reduce(min);
    var hi = points.map((p) => p.value).reduce(max);
    if (hi - lo < 1e-9) {
      lo -= max(1, lo.abs() * 0.05);
      hi += max(1, hi.abs() * 0.05);
    } else {
      final pad = (hi - lo) * 0.15;
      lo -= pad;
      hi += pad;
    }

    for (var i = 0; i <= 3; i++) {
      final y = padTop + h * i / 3;
      canvas.drawLine(Offset(padLeft, y), Offset(padLeft + w, y), gridPaint);
      final v = hi - (hi - lo) * i / 3;
      _text(canvas, format(v), Offset(padLeft + w + 6, y));
    }

    Offset at(int i) {
      final x = points.length == 1
          ? padLeft + w / 2
          : padLeft + w * i / (points.length - 1);
      final y = padTop + h * (1 - (points[i].value - lo) / (hi - lo));
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(i);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        final prev = at(i - 1);
        final mid = (prev.dx + o.dx) / 2;
        path.cubicTo(mid, prev.dy, mid, o.dy, o.dx, o.dy);
      }
    }

    if (points.length > 1) {
      final fill = Path.from(path)
        ..lineTo(at(points.length - 1).dx, padTop + h)
        ..lineTo(at(0).dx, padTop + h)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, padTop, size.width, h)),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotAt = selected ?? points.length - 1;
    if (selected != null) {
      canvas.drawLine(
        Offset(at(dotAt).dx, padTop),
        Offset(at(dotAt).dx, padTop + h),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
    }
    if (points.length <= 24) {
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(at(i), 2.5, Paint()..color = color);
      }
    }
    canvas.drawCircle(at(dotAt), 6.5, Paint()..color = bg);
    canvas.drawCircle(at(dotAt), 4.5, Paint()..color = color);

    final y = padTop + h + 13;
    _text(canvas, fmtShortDate(points.first.date), Offset(padLeft, y));
    if (points.length > 1) {
      _text(
        canvas,
        fmtShortDate(points.last.date),
        Offset(padLeft + w, y),
        align: TextAlign.right,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.selected != selected || old.color != color;
}

/// Simple vertical bars with a label under each and an optional goal line.
class BarChartView extends StatelessWidget {
  const BarChartView({
    super.key,
    required this.values,
    required this.labels,
    this.goal,
    this.height = 150,
  });

  final List<double> values;
  final List<String> labels;
  final double? goal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          values: values,
          labels: labels,
          goal: goal,
          color: p.accent,
          dim: p.cardHigh,
          label: p.muted,
          text: p.text,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.labels,
    required this.goal,
    required this.color,
    required this.dim,
    required this.label,
    required this.text,
  });

  final List<double> values;
  final List<String> labels;
  final double? goal;
  final Color color;
  final Color dim;
  final Color label;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const top = 18.0, bottom = 20.0;
    final h = size.height - top - bottom;
    final hi = max(values.reduce(max), goal ?? 0).clamp(1, double.infinity);
    final slot = size.width / values.length;
    final barW = min(slot * 0.56, 30.0);

    TextPainter tp(String s, Color c, {double size = 10.5}) => TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (goal != null && goal! > 0) {
      final y = top + h * (1 - goal! / hi);
      final paint = Paint()
        ..color = label.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
      }
    }

    for (var i = 0; i < values.length; i++) {
      final cx = slot * i + slot / 2;
      final v = values[i];
      final bh = max(h * v / hi, v > 0 ? 6.0 : 4.0);
      final met = goal == null || v >= goal!;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - barW / 2, top + h - bh, barW, bh),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = v <= 0
              ? dim
              : met
              ? color
              : color.withValues(alpha: 0.4),
      );
      if (v > 0) {
        final t = tp(fmtNum(v, decimals: 0), text);
        t.paint(canvas, Offset(cx - t.width / 2, top + h - bh - t.height - 3));
      }
      if (i < labels.length && labels[i].isNotEmpty) {
        final t = tp(labels[i], label, size: 10);
        t.paint(canvas, Offset(cx - t.width / 2, size.height - t.height));
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.values != values || old.goal != goal || old.color != color;
}

/// Circular progress with content in the middle.
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.progress,
    required this.child,
    this.size = 96,
    this.stroke = 9,
    this.color,
  });

  final double progress;
  final Widget child;
  final double size;
  final double stroke;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, color ?? p.accent, p.cardHigh, stroke),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color, this.track, this.stroke);

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * pi, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        r,
        -pi / 2,
        2 * pi * progress,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
