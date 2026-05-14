import 'package:flutter/material.dart';

/// Compact filled-area sparkline. Renders a 1.5px polyline of [points]
/// scaled to the widget's box, fills the area underneath with a vertical
/// gradient (line color → transparent), and marks the last sample with a
/// glow dot.
class SparklineChart extends StatelessWidget {
  final List<double> points;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  const SparklineChart({
    super.key,
    required this.points,
    required this.lineColor,
    required this.fillColor,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SparklinePainter(
        points: points,
        lineColor: lineColor,
        fillColor: fillColor,
        strokeWidth: strokeWidth,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final minV = points.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final stepX = w / (points.length - 1);

    Offset pt(int i) {
      final y = h - ((points[i] - minV) / range) * (h - 6) - 3;
      return Offset(i * stepX, y);
    }

    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      final p = pt(i);
      if (i == 0) {
        linePath.moveTo(p.dx, p.dy);
      } else {
        linePath.lineTo(p.dx, p.dy);
      }
    }

    final areaPath = Path.from(linePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.45),
          fillColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(areaPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final lastPoint = pt(points.length - 1);
    canvas.drawCircle(
      lastPoint,
      6,
      Paint()..color = lineColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(lastPoint, 3, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points ||
      old.lineColor != lineColor ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth;
}
