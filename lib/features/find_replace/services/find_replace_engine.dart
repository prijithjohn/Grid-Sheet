import '../../../domain/domain.dart';
import '../models/find_replace_options.dart';

/// Pure algorithmic engine for finding and calculating replacements in a workbook.
class FindReplaceEngine {
  const FindReplaceEngine();

  /// Scans populated cells according to [options] and returns all matching cell occurrences
  /// in natural reading order (row ascending, column ascending).
  List<FindReplaceMatch> findAll({
    required Workbook workbook,
    required int activeSheetIndex,
    required FindReplaceOptions options,
  }) {
    final query = options.query;
    if (query.isEmpty) return const [];

    final matches = <FindReplaceMatch>[];
    final sheetIndices = <int>[];

    if (options.searchWorkbook) {
      for (int i = 0; i < workbook.sheetCount; i++) {
        sheetIndices.add(i);
      }
    } else {
      if (activeSheetIndex >= 0 && activeSheetIndex < workbook.sheetCount) {
        sheetIndices.add(activeSheetIndex);
      }
    }

    final queryLower = options.matchCase ? query : query.toLowerCase();

    for (final sheetIdx in sheetIndices) {
      final sheet = workbook.sheets[sheetIdx];

      // Sort populated cells into standard reading order
      final cells = sheet.populatedCells.toList()
        ..sort((a, b) {
          final rowCmp = a.coordinate.row.compareTo(b.coordinate.row);
          if (rowCmp != 0) return rowCmp;
          return a.coordinate.col.compareTo(b.coordinate.col);
        });

      for (final cell in cells) {
        final isFormula = cell.isFormula;
        final targetText = options.searchFormulas
            ? cell.rawInput
            : cell.displayValue;

        if (targetText.isEmpty) continue;

        final compText = options.matchCase
            ? targetText
            : targetText.toLowerCase();

        bool isMatch = false;
        if (options.matchEntireCell) {
          isMatch = compText == queryLower;
        } else {
          isMatch = compText.contains(queryLower);
        }

        if (isMatch) {
          matches.add(
            FindReplaceMatch(
              worksheetIndex: sheetIdx,
              worksheetName: sheet.name,
              coordinate: cell.coordinate,
              matchedText: targetText,
              isFormula: isFormula,
            ),
          );
        }
      }
    }

    return matches;
  }

  /// Calculates the new cell text when replacing [query] with [replacement]
  /// in [targetText], respecting [options].
  static String computeReplacement(
    String targetText,
    FindReplaceOptions options,
  ) {
    if (options.matchEntireCell) {
      return options.replacement;
    }

    if (options.matchCase) {
      return targetText.replaceAll(options.query, options.replacement);
    } else {
      // Case-insensitive substring replacement preserving rest of text
      final pattern = RegExp(
        RegExp.escape(options.query),
        caseSensitive: false,
      );
      return targetText.replaceAll(pattern, options.replacement);
    }
  }
}
