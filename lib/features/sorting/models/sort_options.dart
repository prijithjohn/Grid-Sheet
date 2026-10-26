import '../../../domain/domain.dart';

/// Configuration options for a range sort operation.
class SortOptions {
  const SortOptions({
    required this.range,
    required this.sortColumn,
    this.ascending = true,
    this.hasHeader = false,
  });

  /// The rectangular boundary to sort.
  final CellRange range;

  /// 0-indexed column integer by which to sort rows.
  final int sortColumn;

  /// Whether to sort in ascending (A-Z, 0-9) order vs descending.
  final bool ascending;

  /// If `true`, the first row (`range.topRow`) is treated as a header and excluded from sorting.
  final bool hasHeader;

  SortOptions copyWith({
    CellRange? range,
    int? sortColumn,
    bool? ascending,
    bool? hasHeader,
  }) {
    return SortOptions(
      range: range ?? this.range,
      sortColumn: sortColumn ?? this.sortColumn,
      ascending: ascending ?? this.ascending,
      hasHeader: hasHeader ?? this.hasHeader,
    );
  }
}
