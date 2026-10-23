/// Represents the standard spreadsheet calculation errors.
enum CellError {
  /// Division by zero error (`#DIV/0!`).
  divZero('#DIV/0!', 'Division by zero occurred in formula evaluation'),

  /// Incorrect argument or operand type (`#VALUE!`).
  value('#VALUE!', 'A value used in the formula is of the wrong data type'),

  /// Invalid cell reference (`#REF!`).
  ref(
    '#REF!',
    'A cell reference is invalid, deleted, or outside worksheet bounds',
  ),

  /// Unrecognized function or range name (`#NAME?`).
  name('#NAME?', 'The formula contains an unrecognized function name or token'),

  /// Invalid numerical value (`#NUM!`).
  num('#NUM!', 'A formula or function contains an invalid numeric argument'),

  /// Value not available (`#N/A`).
  na('#N/A!', 'A value is not available to a function or formula'),

  /// Circular dependency detected in formula calculation (`#CIRCULAR!`).
  circular(
    '#CIRCULAR!',
    'Circular dependency detected between dependent cells',
  ),

  /// Intersection of two ranges that do not intersect (`#NULL!`).
  nullError('#NULL!', 'Range intersection produced an empty set');

  final String code;
  final String description;

  const CellError(this.code, this.description);

  @override
  String toString() => code;
}

/// Sealed hierarchy representing the evaluated runtime value of a spreadsheet cell.
///
/// Distinct from raw user input (e.g. `rawInput: "=1+1"` produces `NumberCellValue(2)`).
sealed class CellValue {
  const CellValue();

  /// Whether this cell has no value or evaluated to empty.
  bool get isEmpty => this is EmptyCellValue;

  /// Returns the user-visible display string for this value before custom number formatting.
  String get displayString;
}

/// Represents an empty cell with no data.
class EmptyCellValue extends CellValue {
  const EmptyCellValue();

  @override
  String get displayString => '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmptyCellValue;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'EmptyCellValue()';
}

/// Represents a textual string cell value.
class TextCellValue extends CellValue {
  final String text;

  const TextCellValue(this.text);

  @override
  String get displayString => text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextCellValue &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextCellValue("$text")';
}

/// Represents a numeric cell value (integer or floating point).
class NumberCellValue extends CellValue {
  final num value;

  const NumberCellValue(this.value);

  @override
  String get displayString {
    // Cleanly display integers without decimal trailing zeros
    if (value is int || value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberCellValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NumberCellValue($value)';
}

/// Represents a boolean (`TRUE` / `FALSE`) cell value.
class BooleanCellValue extends CellValue {
  final bool value;

  const BooleanCellValue(this.value);

  @override
  String get displayString => value ? 'TRUE' : 'FALSE';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BooleanCellValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BooleanCellValue($value)';
}

/// Represents a date/time cell value.
class DateTimeCellValue extends CellValue {
  final DateTime dateTime;

  const DateTimeCellValue(this.dateTime);

  @override
  String get displayString =>
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeCellValue &&
          runtimeType == other.runtimeType &&
          dateTime == other.dateTime;

  @override
  int get hashCode => dateTime.hashCode;

  @override
  String toString() => 'DateTimeCellValue($dateTime)';
}

/// Represents a spreadsheet evaluation or syntax error (`#DIV/0!`, `#REF!`, etc.).
class ErrorCellValue extends CellValue {
  final CellError error;

  const ErrorCellValue(this.error);

  @override
  String get displayString => error.code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorCellValue &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'ErrorCellValue(${error.code})';
}
