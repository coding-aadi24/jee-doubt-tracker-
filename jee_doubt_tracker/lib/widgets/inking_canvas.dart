import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/drawing_engine.dart';

class InkingCanvas extends StatefulWidget {
  final DrawingEngine engine;
  final Widget? child;
  final bool isDrawMode;
  final Offset scrollOffset;

  const InkingCanvas({
    Key? key,
    required this.engine,
    required this.isDrawMode,
    this.scrollOffset = Offset.zero,
    this.child,
  }) : super(key: key);

  @override
  State<InkingCanvas> createState() => _InkingCanvasState();
}

class _InkingCanvasState extends State<InkingCanvas> {
  // We use standard gesture detection for pen/eraser/lasso
  void _onPanStart(DragStartDetails details) {
    widget.engine.startStroke(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    widget.engine.updateStroke(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    widget.engine.endStroke();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (widget.child != null) widget.child!,
            ListenableBuilder(
              listenable: widget.engine,
              builder: (context, _) {
                return IgnorePointer(
                  ignoring: !widget.isDrawMode || widget.engine.mode == DrawingMode.pan,
                  child: GestureDetector(
                    onPanStart: (details) {
                      if (!widget.isDrawMode || widget.engine.mode == DrawingMode.pan) return;
                      
                      // Convert screen point to virtual scroll coordinate
                      final virtualPoint = details.localPosition + widget.scrollOffset;
                      
                      widget.engine.startStroke(virtualPoint);
                    },
                    onPanUpdate: (details) {
                      if (!widget.isDrawMode || widget.engine.mode == DrawingMode.pan) return;
                      
                      final virtualPoint = details.localPosition + widget.scrollOffset;
                      
                      widget.engine.updateStroke(virtualPoint);
                    },
                    onPanEnd: _onPanEnd,
                    behavior: HitTestBehavior.translucent,
                    child: CustomPaint(
                      painter: BackgroundPainter(widget.engine, widget.scrollOffset),
                      foregroundPainter: ForegroundPainter(widget.engine, widget.scrollOffset),
                      size: Size.infinite,
                    ),
                  ),
                );
              }
            ),
          ],
        );
      }
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final DrawingEngine engine;
  final Offset scrollOffset;

  BackgroundPainter(this.engine, this.scrollOffset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // Translate the canvas to account for PDF scroll
    canvas.translate(-scrollOffset.dx, -scrollOffset.dy);

    // Draw all completed strokes
    for (final stroke in engine.completedStrokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(stroke.path, paint);

      // If stroke is selected, draw a bounding box around it
      if (engine.selectedStrokes.contains(stroke)) {
        final bounds = stroke.boundingBox;
        final selectedPaint = Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRect(bounds, selectedPaint);
      }
    }

    // Draw lasso selection box
    if (engine.selectionBounds != null) {
      final boxPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRect(engine.selectionBounds!, boxPaint);

      final fillPaint = Paint()
        ..color = Colors.blue.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(engine.selectionBounds!, fillPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => true; 
}

class ForegroundPainter extends CustomPainter {
  final DrawingEngine engine;
  final Offset scrollOffset;

  ForegroundPainter(this.engine, this.scrollOffset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-scrollOffset.dx, -scrollOffset.dy);

    // Draw active stroke (Pen mode)
    if (engine.mode == DrawingMode.pen && engine.activeStroke != null) {
      final paint = Paint()
        ..color = engine.activeStroke!.color
        ..strokeWidth = engine.activeStroke!.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(engine.activeStroke!.path, paint);
    }

    // Draw active lasso path
    if (engine.mode == DrawingMode.lasso && engine.lassoPath.isNotEmpty) {
      final paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
        
      final path = Path();
      path.moveTo(engine.lassoPath.first.x, engine.lassoPath.first.y);
      for (int i = 1; i < engine.lassoPath.length; i++) {
        path.lineTo(engine.lassoPath[i].x, engine.lassoPath[i].y);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ForegroundPainter oldDelegate) => true;
}
