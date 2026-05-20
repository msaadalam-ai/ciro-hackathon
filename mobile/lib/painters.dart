import 'dart:math';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// Custom Painters — Maps, Routes, Decorative Elements
// ═══════════════════════════════════════════════════════════════

class CrisisMapPainter extends CustomPainter {
  final Color zoneColor;
  final String label;
  final List<String> sectorLabels;

  CrisisMapPainter({
    required this.zoneColor,
    required this.label,
    this.sectorLabels = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark map background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF070D1A),
    );

    // Grid roads
    final roadPaint = Paint()
      ..color = const Color(0xFF152035)
      ..strokeWidth = 0.8;

    for (double f in [0.2, 0.4, 0.6, 0.8]) {
      canvas.drawLine(Offset(0, size.height * f), Offset(size.width, size.height * f), roadPaint);
      canvas.drawLine(Offset(size.width * f, 0), Offset(size.width * f, size.height), roadPaint);
    }

    // Diagonal roads
    final diagPaint = Paint()
      ..color = const Color(0xFF152035)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), diagPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), diagPaint);

    // Highlighted zone
    final zonePath = Path();
    final cx = size.width * 0.5;
    final cy = size.height * 0.48;
    final zw = size.width * 0.35;
    final zh = size.height * 0.32;
    zonePath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: zw, height: zh),
      const Radius.circular(4),
    ));

    canvas.drawPath(zonePath, Paint()..color = zoneColor.withOpacity(0.2));
    canvas.drawPath(
      zonePath,
      Paint()
        ..color = zoneColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Zone label
    _drawText(canvas, label, Offset(cx - 12, cy - 6), zoneColor, 10, FontWeight.bold);

    // Sector labels
    if (sectorLabels.length >= 4) {
      _drawText(canvas, sectorLabels[0], Offset(8, 8), Colors.grey.shade600, 8, FontWeight.normal);
      _drawText(canvas, sectorLabels[1], Offset(size.width - 24, 8), Colors.grey.shade600, 8, FontWeight.normal);
      _drawText(canvas, sectorLabels[2], Offset(8, size.height - 18), Colors.grey.shade600, 8, FontWeight.normal);
      _drawText(canvas, sectorLabels[3], Offset(size.width - 24, size.height - 18), Colors.grey.shade600, 8, FontWeight.normal);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouteMapPainter extends CustomPainter {
  final Color routeColor;
  final bool isDashed;

  RouteMapPainter({required this.routeColor, this.isDashed = false});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF070D1A),
    );

    // Subtle grid
    final gridPaint = Paint()
      ..color = const Color(0xFF112030)
      ..strokeWidth = 0.5;
    for (double f in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, size.height * f), Offset(size.width, size.height * f), gridPaint);
      canvas.drawLine(Offset(size.width * f, 0), Offset(size.width * f, size.height), gridPaint);
    }

    // Route path
    final routePaint = Paint()
      ..color = routeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.5,
      size.width * 0.55, size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.4,
      size.width * 0.85, size.height * 0.2,
    );

    if (isDashed) {
      _drawDashedPath(canvas, path, routePaint);
    } else {
      // Glow
      canvas.drawPath(path, Paint()
        ..color = routeColor.withOpacity(0.2)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawPath(path, routePaint);
    }

    // Origin dot
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      4,
      Paint()..color = routeColor,
    );

    // Destination dot
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      5,
      Paint()..color = routeColor,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      8,
      Paint()
        ..color = routeColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0, metric.length).toDouble();
        final extractPath = metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AlertMapPainter extends CustomPainter {
  final Color color;
  final bool showSun;

  AlertMapPainter({required this.color, this.showSun = false});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF070D1A),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF112030)
      ..strokeWidth = 0.5;
    for (double f in [0.3, 0.5, 0.7]) {
      canvas.drawLine(Offset(0, size.height * f), Offset(size.width, size.height * f), gridPaint);
      canvas.drawLine(Offset(size.width * f, 0), Offset(size.width * f, size.height), gridPaint);
    }

    if (showSun) {
      final cx = size.width * 0.55;
      final cy = size.height * 0.4;
      // Sun rays
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        canvas.drawLine(
          Offset(cx + cos(angle) * 12, cy + sin(angle) * 12),
          Offset(cx + cos(angle) * 22, cy + sin(angle) * 22),
          Paint()..color = kOrangeForPainter.withOpacity(0.5)..strokeWidth = 2..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawCircle(Offset(cx, cy), 10, Paint()..color = kOrangeForPainter);
      _drawText(canvas, 'SADDAR', Offset(size.width * 0.3, size.height * 0.65), Colors.grey, 9, FontWeight.bold);
    } else {
      // Pulsing zone indicator
      final cx = size.width * 0.6;
      final cy = size.height * 0.45;
      canvas.drawCircle(Offset(cx, cy), 18, Paint()..color = color.withOpacity(0.15));
      canvas.drawCircle(Offset(cx, cy), 12, Paint()..color = color.withOpacity(0.25));
      canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = color.withOpacity(0.6));
      _drawText(canvas, 'G-10', Offset(cx - 12, cy + 22), Colors.grey, 9, FontWeight.bold);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper constant for painter (avoid importing constants.dart circular)
const kOrangeForPainter = Color(0xFFF97316);
