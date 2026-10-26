import '../../../domain/domain.dart';

/// Configuration options for Find and Replace operations.
class FindReplaceOptions {
  const FindReplaceOptions({
    required this.query,
    this.replacement = '',
    this.matchCase = false,
    this.matchEntireCell = false,
    this.searchWorkbook = false,
    this.searchFormulas = false,
  });

  /// The text string to search for.
  final String query;

  /// The replacement string when replacing.
  final String replacement;

  /// Whether the search should be case-sensitive.
  final bool matchCase;

  /// Whether the query must match the entire cell text rather than a substring.
  final bool matchEntireCell;

  /// If `true`, searches all worksheets in the workbook; otherwise only the active sheet.
  final bool searchWorkbook;

  /// If `true`, searches the raw formula/input text; otherwise searches displayed text.
  final bool searchFormulas;

  FindReplaceOptions copyWith({
    String? query,
    String? replacement,
    bool? matchCase,
    bool? matchEntireCell,
    bool? searchWorkbook,
    bool? searchFormulas,
  }) {
    return FindReplaceOptions(
      query: query ?? this.query,
      replacement: replacement ?? this.replacement,
      matchCase: matchCase ?? this.matchCase,
      matchEntireCell: matchEntireCell ?? this.matchEntireCell,
      searchWorkbook: searchWorkbook ?? this.searchWorkbook,
      searchFormulas: searchFormulas ?? this.searchFormulas,
    );
  }
}

/// Represents a single match found during a search.
class FindReplaceMatch {
  const FindReplaceMatch({
    required this.worksheetIndex,
    required this.worksheetName,
    required this.coordinate,
    required this.matchedText,
    required this.isFormula,
  });

  /// Index of the worksheet containing the match.
  final int worksheetIndex;

  /// Name of the worksheet tab.
  final String worksheetName;

  /// Coordinate of the cell containing the match.
  final CellCoordinate coordinate;

  /// The original text value matched in the cell.
  final String matchedText;

  /// Whether the matched cell contains a formula.
  final bool isFormula;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FindReplaceMatch &&
          runtimeType == other.runtimeType &&
          worksheetIndex == other.worksheetIndex &&
          coordinate == other.coordinate;

  @override
  int get hashCode => worksheetIndex.hashCode ^ coordinate.hashCode;

  @override
  String toString() =>
      'FindReplaceMatch($worksheetName!${coordinate.a1}: "$matchedText")';
}
