/// Pure Dart immutable representation of a spreadsheet cell coordinate.
///
/// Coordinates are 0-indexed internally:
/// - Row 0 corresponds to spreadsheet Row 1.
/// - Column 0 corresponds to spreadsheet Column A.
///
/// Coordinates support standard A1 notation parsing and formatting,
/// including absolute reference anchors (`$A$1`, `$A1`, `A$1`).
class CellCoordinate implements Comparable<CellCoordinate> {
  /// Internal 0-indexed row index (0 <= row < maxRows).
  final int row;

  /// Internal 0-indexed column index (0 <= col < maxCols).
  final int col;

  /// Whether the column reference is absolute (prefixed with `$`).
  final bool isColAbsolute;

  /// Whether the row reference is absolute (prefixed with `$`).
  final bool isRowAbsolute;

  /// Maximum supported row count in accordance with standard spreadsheet limits (1,048,576 rows).
  static const int maxRows = 1048576;

  /// Maximum supported column count in accordance with standard spreadsheet limits (16,384 columns: A to XFD).
  static const int maxCols = 16384;

  /// Creates a validated, immutable [CellCoordinate].
  ///
  /// Throws [RangeError] if [row] or [col] are out of valid spreadsheet bounds.
  const CellCoordinate(
    this.row,
    this.col, {
    this.isColAbsolute = false,
    this.isRowAbsolute = false,
  }) : assert(
         row >= 0 && row < maxRows,
         'Row $row out of bounds [0, $maxRows)',
       ),
       assert(
         col >= 0 && col < maxCols,
         'Col $col out of bounds [0, $maxCols)',
       );

  /// Creates a [CellCoordinate] with runtime boundary validation, throwing [RangeError] on invalid coordinates.
  factory CellCoordinate.validated(
    int row,
    int col, {
    bool isColAbsolute = false,
    bool isRowAbsolute = false,
  }) {
    if (row < 0 || row >= maxRows) {
      throw RangeError.range(
        row,
        0,
        maxRows - 1,
        'row',
        'Row index out of bounds',
      );
    }
    if (col < 0 || col >= maxCols) {
      throw RangeError.range(
        col,
        0,
        maxCols - 1,
        'col',
        'Column index out of bounds',
      );
    }
    return CellCoordinate(
      row,
      col,
      isColAbsolute: isColAbsolute,
      isRowAbsolute: isRowAbsolute,
    );
  }

  /// Parses a standard A1 alphanumeric address string into a [CellCoordinate].
  ///
  /// Examples:
  /// - `"A1"` -> row: 0, col: 0
  /// - `"$B$10"` -> row: 9, col: 1, isColAbsolute: true, isRowAbsolute: true
  /// - `"XFD1048576"` -> row: 1048575, col: 16383
  ///
  /// Throws [FormatException] if [address] has an invalid structure or is out of bounds.
  factory CellCoordinate.fromA1(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Cell address cannot be empty');
    }

    // Regular expression matching column letters (with optional $) and row numbers (with optional $)
    final match = RegExp(r'^(\$?)([A-Za-z]+)(\$?)([1-9]\d*)$')
        .firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Invalid cell address format: "$address"');
    }

    final colAnchor = match.group(1) == r'$';
    final colLetters = match.group(2)!.toUpperCase();
    final rowAnchor = match.group(3) == r'$';
    final rowStr = match.group(4)!;

    final colIndex = lettersToColumn(colLetters);
    final rowIndex = int.parse(rowStr) - 1;

    if (colIndex >= maxCols) {
      throw FormatException(
        'Column "$colLetters" exceeds max allowed ($maxCols)',
      );
    }
    if (rowIndex >= maxRows) {
      throw FormatException('Row "$rowStr" exceeds max allowed ($maxRows)');
    }

    return CellCoordinate(
      rowIndex,
      colIndex,
      isColAbsolute: colAnchor,
      isRowAbsolute: rowAnchor,
    );
  }

  /// Converts a 0-indexed column integer into standard Excel-style letters.
  ///
  /// Examples:
  /// - 0 -> `"A"`
  /// - 25 -> `"Z"`
  /// - 26 -> `"AA"`
  /// - 701 -> `"ZZ"`
  /// - 702 -> `"AAA"`
  /// - 16383 -> `"XFD"`
  static String columnToLetters(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= maxCols) {
      throw RangeError.range(columnIndex, 0, maxCols - 1, 'columnIndex');
    }

    var temp = columnIndex + 1;
    final buffer = StringBuffer();
    while (temp > 0) {
      final rem = (temp - 1) % 26;
      buffer.write(String.fromCharCode(65 + rem));
      temp = (temp - 1) ~/ 26;
    }
    return buffer.toString().split('').reversed.join();
  }

  /// Converts column letter characters (e.g. `"A"`, `"AA"`, `"XFD"`) into a 0-indexed integer.
  static int lettersToColumn(String letters) {
    if (letters.isEmpty) {
      throw const FormatException('Column letters cannot be empty');
    }
    var result = 0;
    final upper = letters.toUpperCase();
    for (var i = 0; i < upper.length; i++) {
      final code = upper.codeUnitAt(i);
      if (code < 65 || code > 90) {
        throw FormatException('Invalid column character "${upper[i]}"');
      }
      result = result * 26 + (code - 64);
    }
    return result - 1;
  }

  /// Formats this coordinate in standard A1 notation.
  ///
  /// If [includeAnchors] is true and [isColAbsolute] or [isRowAbsolute] are set,
  /// dollar signs are prepended to the column and/or row components (e.g., `"$A$1"`).
  String toA1({bool includeAnchors = true}) {
    final colPart =
        '${includeAnchors && isColAbsolute ? '\$' : ''}${columnToLetters(col)}';
    final rowPart = '${includeAnchors && isRowAbsolute ? '\$' : ''}${row + 1}';
    return '$colPart$rowPart';
  }

  /// Returns a new [CellCoordinate] shifted by [rowDelta] and [colDelta].
  ///
  /// Throws [RangeError] if the resulting coordinate falls outside [0, maxRows) or [0, maxCols).
  CellCoordinate offset({int rowDelta = 0, int colDelta = 0}) {
    final newRow = row + rowDelta;
    final newCol = col + colDelta;
    return CellCoordinate.validated(
      newRow,
      newCol,
      isColAbsolute: isColAbsolute,
      isRowAbsolute: isRowAbsolute,
    );
  }

  /// Creates a copy of this coordinate with optional property replacements.
  CellCoordinate copyWith({
    int? row,
    int? col,
    bool? isColAbsolute,
    bool? isRowAbsolute,
  }) {
    return CellCoordinate(
      row ?? this.row,
      col ?? this.col,
      isColAbsolute: isColAbsolute ?? this.isColAbsolute,
      isRowAbsolute: isRowAbsolute ?? this.isRowAbsolute,
    );
  }

  @override
  int compareTo(CellCoordinate other) {
    final rowComp = row.compareTo(other.row);
    if (rowComp != 0) return rowComp;
    return col.compareTo(other.col);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellCoordinate &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col &&
          isColAbsolute == other.isColAbsolute &&
          isRowAbsolute == other.isRowAbsolute;

  @override
  int get hashCode => Object.hash(row, col, isColAbsolute, isRowAbsolute);

  @override
  String toString() => toA1();
}
