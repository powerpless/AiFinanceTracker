import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DonutSegment {
  final double value;
  final Color color;

  const DonutSegment({required this.value, required this.color});
}

/// Donut chart with hairline gaps between segments and a center label/value.
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final double thickness;
  final String centerLabel;
  final String centerValue;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 168,
    this.thickness = 16,
    this.centerLabel = '',
    this.centerValue = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              segments: segments,
              thickness: thickness,
              trackColor: AppColors.bgSunken,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (centerLabel.isNotEmpty)
                Text(
                  centerLabel,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              if (centerValue.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    centerValue,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double thickness;
  final Color trackColor;

  _DonutPainter({
    required this.segments,
    required this.thickness,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (math.min(size.width, size.height) - thickness) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawCircle(Offset(cx, cy), r, trackPaint);

    final total = segments.fold<double>(0, (a, s) => a + s.value);
    if (total <= 0) return;

    const gap = 0.015; // radians gap between segments
    var start = -math.pi / 2 + gap / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * (2 * math.pi) - gap;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.trackColor != trackColor;
}
