import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/drawing_models.dart';
import 'package:uuid/uuid.dart';

enum DrawingMode { pen, eraser, lasso, pan }

class DrawingEngine extends ChangeNotifier {
  DrawingMode _mode = DrawingMode.pen;
  DrawingMode get mode => _mode;

  Color _activeColor = const Color(0xFFFACC15); // Default yellow
  Color get activeColor => _activeColor;

  double _activeThickness = 4.0;
  double get activeThickness => _activeThickness;

  Stroke? _activeStroke;
  Stroke? get activeStroke => _activeStroke;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  final Map<int, List<Stroke>> _strokesByPage = {};
  List<Stroke> get completedStrokes => _strokesByPage[_currentPage] ?? [];

  void setPage(int page) {
    _currentPage = page;
    clearSelection();
    notifyListeners();
  }

  // Lasso selection state
  List<VectorPoint> _lassoPath = [];
  List<VectorPoint> get lassoPath => _lassoPath;
  List<Stroke> _selectedStrokes = [];
  List<Stroke> get selectedStrokes => _selectedStrokes;
  Rect? _selectionBounds;
  Rect? get selectionBounds => _selectionBounds;
  Offset? _lastDragPosition;

  final _uuid = const Uuid();

  void setMode(DrawingMode mode) {
    if (mode == DrawingMode.eraser && _selectedStrokes.isNotEmpty) {
      deleteSelectedStrokes();
      _mode = DrawingMode.lasso; // Stay in lasso mode after quick delete
      notifyListeners();
      return;
    }
    _mode = mode;
    clearSelection();
    notifyListeners();
  }

  void deleteSelectedStrokes() {
    if (_selectedStrokes.isEmpty) return;
    final currentStrokes = _strokesByPage[_currentPage] ?? [];
    currentStrokes.removeWhere((s) => _selectedStrokes.contains(s));
    _strokesByPage[_currentPage] = currentStrokes;
    clearSelection();
    notifyListeners();
  }

  void setPenConfig(Color color, double thickness) {
    _activeColor = color;
    _activeThickness = thickness;
    notifyListeners();
  }

  // Handle Pan Start
  void startStroke(Offset position) {
    if (_mode == DrawingMode.pen) {
      _activeStroke = Stroke(
        id: _uuid.v4(),
        points: [VectorPoint(x: position.dx, y: position.dy, timestamp: DateTime.now().millisecondsSinceEpoch)],
        color: _activeColor,
        thickness: _activeThickness,
      );
      notifyListeners();
    } else if (_mode == DrawingMode.eraser) {
      _eraseAtPoint(position);
    } else if (_mode == DrawingMode.lasso) {
      // Check if clicking inside an existing selection
      if (_selectionBounds != null && _selectionBounds!.contains(position)) {
        // Prepare to move selection
        _lastDragPosition = position;
      } else {
        clearSelection();
        _lassoPath = [VectorPoint(x: position.dx, y: position.dy, timestamp: DateTime.now().millisecondsSinceEpoch)];
      }
      notifyListeners();
    }
  }

  // Handle Pan Update
  void updateStroke(Offset position) {
    if (_mode == DrawingMode.pen && _activeStroke != null) {
      _activeStroke!.points.add(
        VectorPoint(x: position.dx, y: position.dy, timestamp: DateTime.now().millisecondsSinceEpoch),
      );
      notifyListeners(); // Will update foreground canvas
    } else if (_mode == DrawingMode.eraser) {
      _eraseAtPoint(position);
    } else if (_mode == DrawingMode.lasso) {
      if (_selectedStrokes.isNotEmpty && _lastDragPosition != null) {
        final delta = position - _lastDragPosition!;
        applyTransformToSelection(delta);
        _lastDragPosition = position;
      } else if (_lassoPath.isNotEmpty) {
        // Drawing lasso loop
        _lassoPath.add(VectorPoint(x: position.dx, y: position.dy, timestamp: DateTime.now().millisecondsSinceEpoch));
        notifyListeners();
      }
    }
  }

  // Handle Pan End
  void endStroke() {
    if (_mode == DrawingMode.pen && _activeStroke != null) {
      if (_activeStroke!.points.length > 1) {
        _strokesByPage.putIfAbsent(_currentPage, () => []).add(_activeStroke!);
      }
      _activeStroke = null;
      notifyListeners();
    } else if (_mode == DrawingMode.lasso) {
      if (_lastDragPosition != null) {
        _lastDragPosition = null; // Finished dragging
      } else if (_lassoPath.isNotEmpty && _selectedStrokes.isEmpty) {
        _processLassoSelection();
        notifyListeners();
      }
    }
  }

  void _eraseAtPoint(Offset point) {
    final eraserRadius = 15.0; // Eraser radius
    final eraserRect = Rect.fromCircle(center: point, radius: eraserRadius);

    bool strokesChanged = false;
    final List<Stroke> strokesToAdd = [];
    final List<Stroke> strokesToRemove = [];

    final currentStrokes = _strokesByPage[_currentPage] ?? [];

    for (var stroke in currentStrokes) {
      // Bounding box pre-filter check
      if (stroke.boundingBox.overlaps(eraserRect)) {
        // Detailed point check (Pixel Eraser)
        List<VectorPoint> currentSubStroke = [];
        bool strokeModified = false;

        for (var p in stroke.points) {
          // Check collision
          final pointX = p.x * stroke.scale + stroke.offset.dx;
          final pointY = p.y * stroke.scale + stroke.offset.dy;
          
          final dx = pointX - point.dx;
          final dy = pointY - point.dy;
          final distSq = (dx * dx) + (dy * dy);

          if (distSq <= (eraserRadius * eraserRadius)) {
            // Point is erased, split stroke here
            if (currentSubStroke.isNotEmpty) {
              strokesToAdd.add(Stroke(
                id: _uuid.v4(),
                points: List.from(currentSubStroke),
                color: stroke.color,
                thickness: stroke.thickness,
                offset: stroke.offset,
                scale: stroke.scale,
              ));
              currentSubStroke.clear();
              strokeModified = true;
            }
          } else {
            currentSubStroke.add(p);
          }
        }

        if (strokeModified) {
          if (currentSubStroke.isNotEmpty) {
             strokesToAdd.add(Stroke(
                id: _uuid.v4(),
                points: List.from(currentSubStroke),
                color: stroke.color,
                thickness: stroke.thickness,
                offset: stroke.offset,
                scale: stroke.scale,
              ));
          }
          strokesToRemove.add(stroke);
          strokesChanged = true;
        } else if (currentSubStroke.isEmpty && stroke.points.isNotEmpty) {
          // Erased the whole stroke
          strokesToRemove.add(stroke);
          strokesChanged = true;
        }
      }
    }

    if (strokesChanged) {
      currentStrokes.removeWhere((s) => strokesToRemove.contains(s));
      currentStrokes.addAll(strokesToAdd);
      _strokesByPage[_currentPage] = currentStrokes;
      notifyListeners();
    }
  }

  void _processLassoSelection() {
    if (_lassoPath.length < 3) {
      _lassoPath.clear();
      return;
    }

    // Ray-Casting algorithm to find strokes inside the lasso polygon
    final polyX = _lassoPath.map((p) => p.x).toList();
    final polyY = _lassoPath.map((p) => p.y).toList();
    final polyCorners = polyX.length;

    bool isPointInPolygon(double x, double y) {
      int i, j = polyCorners - 1;
      bool oddNodes = false;

      for (i = 0; i < polyCorners; i++) {
        if ((polyY[i] < y && polyY[j] >= y || polyY[j] < y && polyY[i] >= y) && (polyX[i] <= x || polyX[j] <= x)) {
          if (polyX[i] + (y - polyY[i]) / (polyY[j] - polyY[i]) * (polyX[j] - polyX[i]) < x) {
            oddNodes = !oddNodes;
          }
        }
        j = i;
      }
      return oddNodes;
    }

    _selectedStrokes.clear();
    double minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;

    final currentStrokes = _strokesByPage[_currentPage] ?? [];

    for (var stroke in currentStrokes) {
      // Check if at least one point of the stroke is inside the polygon
      bool isInside = false;
      for (var p in stroke.points) {
        final transformedX = p.x * stroke.scale + stroke.offset.dx;
        final transformedY = p.y * stroke.scale + stroke.offset.dy;
        if (isPointInPolygon(transformedX, transformedY)) {
          isInside = true;
          break;
        }
      }

      if (isInside) {
        _selectedStrokes.add(stroke);
        final bounds = stroke.boundingBox;
        if (bounds.left < minX) minX = bounds.left;
        if (bounds.top < minY) minY = bounds.top;
        if (bounds.right > maxX) maxX = bounds.right;
        if (bounds.bottom > maxY) maxY = bounds.bottom;
      }
    }

    if (_selectedStrokes.isNotEmpty) {
      _selectionBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    }
    _lassoPath.clear(); // Clear the drawn path, leave only the selection box
  }

  void clearSelection() {
    _selectedStrokes.clear();
    _selectionBounds = null;
    _lassoPath.clear();
  }

  // Called when moving a lasso selection
  void applyTransformToSelection(Offset delta) {
    if (_selectionBounds == null) return;
    _selectionBounds = _selectionBounds!.shift(delta);
    
    for (var stroke in _selectedStrokes) {
      stroke.offset += delta;
    }
    notifyListeners();
  }
}
