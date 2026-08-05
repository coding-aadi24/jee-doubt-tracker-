import 'dart:ui';
import 'package:flutter/foundation.dart';

class VectorPoint {
  final double x;
  final double y;
  final int timestamp;
  final double pressure;

  VectorPoint({
    required this.x,
    required this.y,
    required this.timestamp,
    this.pressure = 1.0,
  });

  Offset get offset => Offset(x, y);

  VectorPoint copyWith({
    double? x,
    double? y,
    int? timestamp,
    double? pressure,
  }) {
    return VectorPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      timestamp: timestamp ?? this.timestamp,
      pressure: pressure ?? this.pressure,
    );
  }
}

class Stroke {
  final String id;
  final List<VectorPoint> points;
  final Color color;
  final double thickness;
  Rect? _cachedBounds;
  Offset offset;
  double scale;

  Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.thickness,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  Rect get boundingBox {
    if (_cachedBounds != null && offset == Offset.zero && scale == 1.0) {
      return _cachedBounds!;
    }
    
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    // Expand bounding box slightly based on thickness to ensure edges aren't clipped
    final inflation = thickness / 2;
    _cachedBounds = Rect.fromLTRB(minX, minY, maxX, maxY).inflate(inflation);

    if (offset != Offset.zero || scale != 1.0) {
      // Return transformed bounding box (without caching to allow dynamic updates)
      return Rect.fromLTRB(
        minX * scale + offset.dx, 
        minY * scale + offset.dy, 
        maxX * scale + offset.dx, 
        maxY * scale + offset.dy
      ).inflate(inflation * scale);
    }

    return _cachedBounds!;
  }

  Path get path {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(
      points[0].x * scale + offset.dx, 
      points[0].y * scale + offset.dy
    );

    if (points.length == 1) {
      path.addOval(Rect.fromCircle(
        center: Offset(points[0].x * scale + offset.dx, points[0].y * scale + offset.dy),
        radius: thickness / 2,
      ));
      return path;
    }

    // Apply basic smoothing for path generation
    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      
      final p0x = p0.x * scale + offset.dx;
      final p0y = p0.y * scale + offset.dy;
      final p1x = p1.x * scale + offset.dx;
      final p1y = p1.y * scale + offset.dy;

      path.quadraticBezierTo(
        p0x, p0y,
        (p0x + p1x) / 2,
        (p0y + p1y) / 2,
      );
    }
    
    final last = points.last;
    path.lineTo(last.x * scale + offset.dx, last.y * scale + offset.dy);

    return path;
  }
}

enum PageBackgroundType {
  pdf,
  blankDark,
  blankLight,
}

class DrawingPage {
  final int pageIndex;
  final PageBackgroundType backgroundType;
  final List<Stroke> strokes;
  final double width;
  final double height;

  DrawingPage({
    required this.pageIndex,
    this.backgroundType = PageBackgroundType.pdf,
    List<Stroke>? strokes,
    this.width = 800,
    this.height = 1131, // Standard A4 ratio
  }) : strokes = strokes ?? [];
}
