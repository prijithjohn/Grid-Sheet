import 'cell_coordinate.dart';
import 'cell_style.dart';
import 'cell_value.dart';

/// Pure Dart entity representing a spreadsheet cell.
///
/// Contains the cell's [coordinate], raw user input string ([rawInput]),
/// computed evaluated value ([computedValue]), and visual styling ([style]).
class Cell {
  /// The 0-indexed coordinate location of this cell.
  final CellCoordinate coordinate;

  /// The raw string input entered by the user (e.g. `"=SUM(A1:A5)"` or `"1250.50"`).
  final String rawInput;

  /// The evaluated result of the cell (distinct from [rawInput]).
  final CellValue computedValue;

  /// Visual formatting and styling tokens applied to this cell.
  final CellStyle style;

  const Cell({
    required this.coordinate,
    this.rawInput = '',
    this.computedValue = const EmptyCellValue(),
    this.style = CellStyle.defaultStyle,
  });

  /// Creates an empty cell at the given [coordinate].
  factory Cell.empty(CellCoordinate coordinate) {
    return Cell(
      coordinate: coordinate,
      rawInput: '',
      computedValue: const EmptyCellValue(),
      style: CellStyle.defaultStyle,
    );
  }

  /// Creates a cell initialized with user text input.
  ///
  /// If [rawInput] is not a formula, parses numeric or boolean types automatically
  /// for initial representation until the formula engine recalculates.
  factory Cell.fromInput(
    CellCoordinate coordinate,
    String rawInput, {
    CellStyle style = CellStyle.defaultStyle,
    CellValue? computedValue,
  }) {
    final trimmed = rawInput.trim();
    CellValue initialValue;

    if (computedValue != null) {
      initialValue = computedValue;
    } else if (trimmed.isEmpty) {
      initialValue = const EmptyCellValue();
    } else if (trimmed.startsWith('=')) {
      // Formulas are evaluated separately by the calculation engine
      initialValue = const EmptyCellValue();
    } else if (trimmed.toUpperCase() == 'TRUE') {
      initialValue = const BooleanCellValue(true);
    } else if (trimmed.toUpperCase() == 'FALSE') {
      initialValue = const BooleanCellValue(false);
    } else {
      final parsedNum = num.tryParse(trimmed);
      if (parsedNum != null) {
        initialValue = NumberCellValue(parsedNum);
      } else {
        initialValue = TextCellValue(rawInput);
      }
    }

    return Cell(
      coordinate: coordinate,
      rawInput: rawInput,
      computedValue: initialValue,
      style: style,
    );
  }

  /// Whether the raw input represents a spreadsheet formula (starts with `=`).
  bool get isFormula => rawInput.trimLeft().startsWith('=');

  /// Returns the formula body without the leading `=` symbol, or empty string if not a formula.
  String get formula =>
      isFormula ? rawInput.trimLeft().substring(1).trim() : '';

  /// Whether the cell has no content and no evaluated value.
  bool get isEmpty => rawInput.isEmpty && computedValue.isEmpty;

  /// Returns the text to display in the cell grid, applying [style.numberFormat].
  String get formattedText {
    if (computedValue is EmptyCellValue) {
      return '';
    }

    if (computedValue is ErrorCellValue) {
      return (computedValue as ErrorCellValue).error.code;
    }

    if (computedValue is BooleanCellValue) {
      return (computedValue as BooleanCellValue).displayString;
    }

    if (computedValue is NumberCellValue) {
      final numVal = (computedValue as NumberCellValue).value;
      return _formatNumber(numVal, style.numberFormat);
    }

    return computedValue.displayString;
  }

  /// Helper to format numeric values based on [CellNumberFormat].
  static String _formatNumber(num value, CellNumberFormat format) {
    switch (format.type) {
      case NumberFormatType.general:
        if (value is int || value == value.truncateToDouble()) {
          return value.toInt().toString();
        }
        return value.toString();

      case NumberFormatType.number:
        final fixed = value.toDouble().toStringAsFixed(format.decimalPlaces);
        if (format.useThousandsSeparator) {
          return _addThousandsSeparators(fixed);
        }
        return fixed;

      case NumberFormatType.currency:
        final fixed = value.toDouble().toStringAsFixed(format.decimalPlaces);
        final withCommas = format.useThousandsSeparator
            ? _addThousandsSeparators(fixed)
            : fixed;
        return '${format.currencySymbol}$withCommas';

      case NumberFormatType.percentage:
        final percentVal = value * 100;
        final fixed = percentVal.toDouble().toStringAsFixed(
          format.decimalPlaces,
        );
        return '$fixed%';

      case NumberFormatType.accounting:
        final fixed = value.toDouble().abs().toStringAsFixed(
          format.decimalPlaces,
        );
        final withCommas = format.useThousandsSeparator
            ? _addThousandsSeparators(fixed)
            : fixed;
        if (value < 0) {
          return '(${format.currencySymbol}$withCommas)';
        }
        return '${format.currencySymbol} $withCommas';

      case NumberFormatType.dateShort:
      case NumberFormatType.text:
        return value.toString();
    }
  }

  static String _addThousandsSeparators(String numericString) {
    final parts = numericString.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final isNegative = integerPart.startsWith('-');
    final cleanInt = isNegative ? integerPart.substring(1) : integerPart;

    final buffer = StringBuffer();
    final len = cleanInt.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(cleanInt[i]);
    }

    return '${isNegative ? '-' : ''}${buffer.toString()}$decimalPart';
  }

  /// Creates a copy of this cell with optional replacements.
  Cell copyWith({
    CellCoordinate? coordinate,
    String? rawInput,
    CellValue? computedValue,
    CellStyle? style,
  }) {
    return Cell(
      coordinate: coordinate ?? this.coordinate,
      rawInput: rawInput ?? this.rawInput,
      computedValue: computedValue ?? this.computedValue,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          coordinate == other.coordinate &&
          rawInput == other.rawInput &&
          computedValue == other.computedValue &&
          style == other.style;

  @override
  int get hashCode => Object.hash(coordinate, rawInput, computedValue, style);

  @override
  String toString() =>
      'Cell(${coordinate.toA1()}: "$rawInput" => $computedValue)';
}
