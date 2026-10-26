import '../cell/cell_coordinate.dart';
import 'lexer.dart';
import 'token.dart';

/// Utility class for adjusting cell references within formula expressions
/// during fill operations, row/column insertions, and row/column deletions.
class FormulaReferenceAdjuster {
  const FormulaReferenceAdjuster();

  /// Adjusts relative and absolute references in [formulaSource] based on the
  /// given delta or structural transformation.
  ///
  /// - [deltaRows]: added to row when [isRowAbsolute] is false.
  /// - [deltaCols]: added to col when [isColAbsolute] is false.
  /// - [insertedRowAt] & [insertedRowCount]: rows at or below this index shift down.
  /// - [deletedRowAt] & [deletedRowCount]: rows in this range become `#REF!`; rows below shift up.
  /// - [insertedColAt] & [insertedColCount]: columns at or right of this index shift right.
  /// - [deletedColAt] & [deletedColCount]: columns in this range become `#REF!`; columns to the right shift left.
  static String adjustReferences(
    String formulaSource, {
    int deltaRows = 0,
    int deltaCols = 0,
    int? insertedRowAt,
    int insertedRowCount = 1,
    int? deletedRowAt,
    int deletedRowCount = 1,
    int? insertedColAt,
    int insertedColCount = 1,
    int? deletedColAt,
    int deletedColCount = 1,
  }) {
    final trimmed = formulaSource.trim();
    if (!trimmed.startsWith('=')) {
      return formulaSource;
    }

    // Tokenize expression (excluding leading '=')
    final lexer = FormulaLexer(formulaSource);
    final tokens = lexer.tokenize();

    // Find all cellReference tokens
    final refTokens = tokens
        .where((t) => t.type == TokenType.cellReference)
        .toList();

    if (refTokens.isEmpty) {
      return formulaSource;
    }

    // Work on the source text after '='
    final body = formulaSource.startsWith('=')
        ? formulaSource.substring(1)
        : formulaSource;

    var result = body;

    // Process tokens in reverse order so character offsets in `body` remain valid
    refTokens.sort((a, b) => b.position.compareTo(a.position));

    for (final token in refTokens) {
      final adjustedRef = _adjustSingleReference(
        token.lexeme,
        deltaRows: deltaRows,
        deltaCols: deltaCols,
        insertedRowAt: insertedRowAt,
        insertedRowCount: insertedRowCount,
        deletedRowAt: deletedRowAt,
        deletedRowCount: deletedRowCount,
        insertedColAt: insertedColAt,
        insertedColCount: insertedColCount,
        deletedColAt: deletedColAt,
        deletedColCount: deletedColCount,
      );

      result =
          result.substring(0, token.position) +
          adjustedRef +
          result.substring(token.position + token.lexeme.length);
    }

    return '=$result';
  }

  static String _adjustSingleReference(
    String raw, {
    required int deltaRows,
    required int deltaCols,
    int? insertedRowAt,
    int insertedRowCount = 1,
    int? deletedRowAt,
    int deletedRowCount = 1,
    int? insertedColAt,
    int insertedColCount = 1,
    int? deletedColAt,
    int deletedColCount = 1,
  }) {
    String? sheetPrefix;
    String coordPart = raw;

    final bangIndex = raw.indexOf('!');
    if (bangIndex != -1) {
      sheetPrefix = raw.substring(0, bangIndex + 1);
      coordPart = raw.substring(bangIndex + 1);
    }

    bool isColAbs = false;
    bool isRowAbs = false;
    var s = coordPart;

    if (s.startsWith(r'$')) {
      isColAbs = true;
      s = s.substring(1);
    }

    final letters = StringBuffer();
    final digits = StringBuffer();
    bool hitRowDollar = false;

    for (int i = 0; i < s.length; i++) {
      final char = s[i];
      if (char == r'$') {
        hitRowDollar = true;
        isRowAbs = true;
      } else if (!hitRowDollar && _isAlpha(char)) {
        letters.write(char.toUpperCase());
      } else if (_isDigit(char)) {
        digits.write(char);
      }
    }

    final colStr = letters.toString();
    final rowStr = digits.toString();

    if (colStr.isEmpty || rowStr.isEmpty) {
      return raw;
    }

    try {
      var col = CellCoordinate.lettersToColumn(colStr);
      var row = int.parse(rowStr) - 1; // 0-indexed

      // 1. Structural column insertion/deletion
      if (insertedColAt != null) {
        if (col >= insertedColAt) {
          col += insertedColCount;
        }
      } else if (deletedColAt != null) {
        if (col >= deletedColAt && col < deletedColAt + deletedColCount) {
          return '#REF!';
        } else if (col >= deletedColAt + deletedColCount) {
          col -= deletedColCount;
        }
      }

      // 2. Structural row insertion/deletion
      if (insertedRowAt != null) {
        if (row >= insertedRowAt) {
          row += insertedRowCount;
        }
      } else if (deletedRowAt != null) {
        if (row >= deletedRowAt && row < deletedRowAt + deletedRowCount) {
          return '#REF!';
        } else if (row >= deletedRowAt + deletedRowCount) {
          row -= deletedRowCount;
        }
      }

      // 3. Delta shifts (e.g. fill down, fill right) for relative coordinates
      if (!isColAbs) {
        col += deltaCols;
      }
      if (!isRowAbs) {
        row += deltaRows;
      }

      // Boundary check
      if (col < 0 ||
          col >= CellCoordinate.maxCols ||
          row < 0 ||
          row >= CellCoordinate.maxRows) {
        return '#REF!';
      }

      final newLetters = CellCoordinate.columnToLetters(col);
      final newRow = row + 1; // 1-indexed

      final buffer = StringBuffer();
      if (sheetPrefix != null) buffer.write(sheetPrefix);
      if (isColAbs) buffer.write(r'$');
      buffer.write(newLetters);
      if (isRowAbs) buffer.write(r'$');
      buffer.write(newRow);

      return buffer.toString();
    } catch (_) {
      return raw;
    }
  }

  static bool _isAlpha(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  static bool _isDigit(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}
