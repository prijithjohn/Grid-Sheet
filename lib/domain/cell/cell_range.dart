import 'dart:math' as math;

import 'cell_coordinate.dart';

/// Pure Dart representation of a rectangular range of cells.
///
/// Bounded by a [start] and [end] coordinate. The bounds are normalized
/// such that [topRow] <= [bottomRow] and [leftCol] <= [rightCol].
class CellRange {
  /// The anchor coordinate where selection started.
  final CellCoordinate start;

  /// The active coordinate where selection ended.
  final CellCoordinate end;

  /// Normalized top-most 0-indexed row index.
  final int topRow;

  /// Normalized bottom-most 0-indexed row index.
  final int bottomRow;

  /// Normalized left-most 0-indexed column index.
  final int leftCol;

  /// Normalized right-most 0-indexed column index.
  final int rightCol;

  /// Creates a [CellRange] defined by [start] and [end] coordinates.
  ///
  /// Normalizes bounds automatically so that [topRow] <= [bottomRow] and [leftCol] <= [rightCol].
  CellRange(this.start, this.end)
    : topRow = math.min(start.row, end.row),
      bottomRow = math.max(start.row, end.row),
      leftCol = math.min(start.col, end.col),
      rightCol = math.max(start.col, end.col);

  /// Creates a [CellRange] with explicit, pre-normalized bounds.
  ///
  /// Use this const-compatible constructor when bounds are known at compile-time
  /// and are already in normalized form (topRow <= bottomRow, leftCol <= rightCol).
  const CellRange.normalized({
    required this.start,
    required this.end,
    required this.topRow,
    required this.bottomRow,
    required this.leftCol,
    required this.rightCol,
  }) : assert(topRow <= bottomRow),
       assert(leftCol <= rightCol);

  /// Creates a 1x1 [CellRange] covering a single [coordinate].
  CellRange.single(CellCoordinate coordinate)
    : start = coordinate,
      end = coordinate,
      topRow = coordinate.row,
      bottomRow = coordinate.row,
      leftCol = coordinate.col,
      rightCol = coordinate.col;

  /// Creates a [CellRange] from explicit normalized bounding coordinates.
  factory CellRange.fromBounds({
    required int topRow,
    required int bottomRow,
    required int leftCol,
    required int rightCol,
  }) {
    if (topRow > bottomRow) {
      throw ArgumentError(
        'topRow ($topRow) cannot be greater than bottomRow ($bottomRow)',
      );
    }
    if (leftCol > rightCol) {
      throw ArgumentError(
        'leftCol ($leftCol) cannot be greater than rightCol ($rightCol)',
      );
    }
    return CellRange(
      CellCoordinate.validated(topRow, leftCol),
      CellCoordinate.validated(bottomRow, rightCol),
    );
  }

  /// Parses an A1 range string (e.g. `"A1:B10"`, `"$C$5:$F$20"`, or single `"A1"`).
  ///
  /// Throws [FormatException] if the range syntax is invalid.
  factory CellRange.fromA1(String rangeA1) {
    final trimmed = rangeA1.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Cell range string cannot be empty');
    }

    final parts = trimmed.split(':');
    if (parts.length == 1) {
      final singleCoord = CellCoordinate.fromA1(parts[0]);
      return CellRange.single(singleCoord);
    } else if (parts.length == 2) {
      final startCoord = CellCoordinate.fromA1(parts[0]);
      final endCoord = CellCoordinate.fromA1(parts[1]);
      return CellRange(startCoord, endCoord);
    } else {
      throw FormatException('Invalid range format: "$rangeA1"');
    }
  }

  /// Total number of rows spanning this range.
  int get rowCount => bottomRow - topRow + 1;

  /// Total number of columns spanning this range.
  int get colCount => rightCol - leftCol + 1;

  /// Total count of cells enclosed by this range.
  int get cellCount => rowCount * colCount;

  /// Whether this range contains exactly one cell.
  bool get isSingleCell => rowCount == 1 && colCount == 1;

  /// Formats this range in standard A1 range notation (e.g. `"A1:B10"`).
  ///
  /// If the range is a single cell, returns the single cell coordinate (e.g. `"A1"`).
  /// Note: this uses [start] and [end] directly; for normalized output use the
  /// normalized fields [topRow], [bottomRow], [leftCol], [rightCol] instead.
  String toA1({bool includeAnchors = true}) {
    if (isSingleCell) {
      return start.toA1(includeAnchors: includeAnchors);
    }
    return '${start.toA1(includeAnchors: includeAnchors)}:${end.toA1(includeAnchors: includeAnchors)}';
  }

  /// Shorthand getter returning standard A1 range notation without anchors.
  String get a1 => toA1(includeAnchors: false);

  /// Returns true if this range encloses the given [coordinate].
  bool contains(CellCoordinate coordinate) {
    return coordinate.row >= topRow &&
        coordinate.row <= bottomRow &&
        coordinate.col >= leftCol &&
        coordinate.col <= rightCol;
  }

  /// Returns true if this range completely encloses [other].
  bool containsRange(CellRange other) {
    return other.topRow >= topRow &&
        other.bottomRow <= bottomRow &&
        other.leftCol >= leftCol &&
        other.rightCol <= rightCol;
  }

  /// Returns true if this range intersects or overlaps with [other].
  bool intersects(CellRange other) {
    return !(other.leftCol > rightCol ||
        other.rightCol < leftCol ||
        other.topRow > bottomRow ||
        other.bottomRow < topRow);
  }

  /// Returns the rectangular intersection with [other], or null if they do not intersect.
  CellRange? intersection(CellRange other) {
    if (!intersects(other)) return null;

    final intersectTop = math.max(topRow, other.topRow);
    final intersectBottom = math.min(bottomRow, other.bottomRow);
    final intersectLeft = math.max(leftCol, other.leftCol);
    final intersectRight = math.min(rightCol, other.rightCol);

    return CellRange(
      CellCoordinate(intersectTop, intersectLeft),
      CellCoordinate(intersectBottom, intersectRight),
    );
  }

  /// Returns the smallest bounding box enclosing both this range and [other].
  CellRange boundingBox(CellRange other) {
    final bTop = math.min(topRow, other.topRow);
    final bBottom = math.max(bottomRow, other.bottomRow);
    final bLeft = math.min(leftCol, other.leftCol);
    final bRight = math.max(rightCol, other.rightCol);

    return CellRange(
      CellCoordinate(bTop, bLeft),
      CellCoordinate(bBottom, bRight),
    );
  }

  /// Lazily yields all [CellCoordinate]s within this range in row-major order.
  Iterable<CellCoordinate> get coordinates sync* {
    for (var r = topRow; r <= bottomRow; r++) {
      for (var c = leftCol; c <= rightCol; c++) {
        yield CellCoordinate(r, c);
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellRange &&
          runtimeType == other.runtimeType &&
          topRow == other.topRow &&
          bottomRow == other.bottomRow &&
          leftCol == other.leftCol &&
          rightCol == other.rightCol;

  @override
  int get hashCode => Object.hash(topRow, bottomRow, leftCol, rightCol);

  @override
  String toString() => toA1();
}
