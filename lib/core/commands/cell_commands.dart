import '../../domain/domain.dart';
import 'command.dart';

/// Reversible command that edits the raw text and calculated value of a single cell.
class SetCellTextCommand extends Command {
  /// Creates a [SetCellTextCommand] targeting [coordinate] on [worksheet].
  SetCellTextCommand({
    required this.worksheet,
    required this.coordinate,
    required this.newText,
  });

  /// The worksheet containing the target cell.
  final Worksheet worksheet;

  /// The coordinate of the cell to update.
  final CellCoordinate coordinate;

  /// The new raw text string to assign.
  final String newText;

  CellModel? _oldCell;
  bool _executedOnce = false;

  @override
  String get description => 'Edit Cell ${coordinate.a1}';

  @override
  void execute() {
    if (!_executedOnce) {
      _oldCell = worksheet.getCell(coordinate);
      _executedOnce = true;
    }

    if (newText.trim().isEmpty) {
      worksheet.removeCell(coordinate);
    } else {
      final style = _oldCell?.style ?? CellStyle.defaultStyle;
      final newCell = CellModel.fromInput(coordinate, newText, style: style);
      worksheet.setCell(newCell);
    }
  }

  @override
  void undo() {
    if (_oldCell == null) {
      worksheet.removeCell(coordinate);
    } else {
      worksheet.setCell(_oldCell!);
    }
  }
}

/// Reversible command that clears all cells within a bounding [CellRange].
class ClearRangeCommand extends Command {
  /// Creates a [ClearRangeCommand] targeting [range] on [worksheet].
  ClearRangeCommand({required this.worksheet, required this.range});

  /// The worksheet containing the range.
  final Worksheet worksheet;

  /// The bounding rectangular range to clear.
  final CellRange range;

  final Map<CellCoordinate, CellModel> _previousCells = {};
  bool _executedOnce = false;

  @override
  String get description => 'Clear Range ${range.a1}';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final coord in range.coordinates) {
        final cell = worksheet.getCell(coord);
        if (cell != null) {
          _previousCells[coord] = cell;
        }
      }
      _executedOnce = true;
    }

    worksheet.clearRange(range);
  }

  @override
  void undo() {
    for (final entry in _previousCells.entries) {
      worksheet.setCell(entry.value);
    }
  }
}

/// Reversible command that applies formatting updates across a [CellRange].
class FormatRangeCommand extends Command {
  /// Creates a [FormatRangeCommand] updating styles in [range] using [styleUpdater].
  FormatRangeCommand({
    required this.worksheet,
    required this.range,
    required this.styleUpdater,
    this.customDescription,
  });

  /// The worksheet containing the range.
  final Worksheet worksheet;

  /// The bounding rectangular range to format.
  final CellRange range;

  /// Function that transforms an existing [CellStyle] into a new [CellStyle].
  final CellStyle Function(CellStyle current) styleUpdater;

  /// Optional specific description (e.g. "Bold Range A1:B5", "Align Center").
  final String? customDescription;

  final Map<CellCoordinate, CellModel?> _previousCells = {};
  bool _executedOnce = false;

  @override
  String get description => customDescription ?? 'Format Range ${range.a1}';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final coord in range.coordinates) {
        _previousCells[coord] = worksheet.getCell(coord);
      }
      _executedOnce = true;
    }

    for (final coord in range.coordinates) {
      final existing = worksheet.getCell(coord);
      final currentStyle = existing?.style ?? CellStyle.defaultStyle;
      final newStyle = styleUpdater(currentStyle);

      if (existing != null) {
        worksheet.setCell(existing.copyWith(style: newStyle));
      } else {
        worksheet.setCell(CellModel.empty(coord, style: newStyle));
      }
    }
  }

  @override
  void undo() {
    for (final coord in range.coordinates) {
      final prev = _previousCells[coord];
      if (prev == null) {
        worksheet.removeCell(coord);
      } else {
        worksheet.setCell(prev);
      }
    }
  }
}
