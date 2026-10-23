import '../../domain/domain.dart';
import 'command.dart';

/// Reversible command that adds a new worksheet to a workbook.
class AddWorksheetCommand extends Command {
  /// Creates an [AddWorksheetCommand] targeting [workbook].
  AddWorksheetCommand({required this.workbook, this.name, this.index});

  /// The target workbook.
  final Workbook workbook;

  /// Optional name for the new worksheet.
  final String? name;

  /// Optional insertion index for the new worksheet.
  final int? index;

  Worksheet? _createdSheet;

  @override
  String get description => 'Add Sheet ${_createdSheet?.name ?? name ?? ""}';

  @override
  void execute() {
    if (_createdSheet == null) {
      if (index != null) {
        final generatedName = name ?? 'Sheet${workbook.sheetCount + 1}';
        final sheet = Worksheet(
          id: '${workbook.id}_sheet_${DateTime.now().microsecondsSinceEpoch}',
          name: generatedName,
        );
        workbook.insertSheet(index!, sheet);
        _createdSheet = sheet;
      } else {
        _createdSheet = workbook.createSheet(name: name);
      }
    } else {
      if (index != null && index! <= workbook.sheetCount) {
        workbook.insertSheet(index!, _createdSheet!);
      } else {
        workbook.addSheet(_createdSheet!);
      }
    }
  }

  @override
  void undo() {
    if (_createdSheet != null) {
      workbook.removeSheet(_createdSheet!);
    }
  }
}

/// Reversible command that removes a worksheet from a workbook.
class RemoveWorksheetCommand extends Command {
  /// Creates a [RemoveWorksheetCommand] targeting sheet at [index] in [workbook].
  RemoveWorksheetCommand({required this.workbook, required this.index});

  /// The target workbook.
  final Workbook workbook;

  /// The index of the sheet to remove.
  final int index;

  Worksheet? _removedSheet;
  int _previousIndex = -1;
  int _previousActiveIndex = -1;

  @override
  bool get canExecute => workbook.sheetCount > 1;

  @override
  String get description => 'Delete Sheet "${_removedSheet?.name ?? ""}"';

  @override
  void execute() {
    if (!canExecute) {
      throw StateError(
        'Cannot remove the last remaining worksheet in a workbook',
      );
    }
    _previousIndex = index;
    _previousActiveIndex = workbook.activeSheetIndex;
    _removedSheet = workbook.sheets[index];
    workbook.removeSheetAt(index);
  }

  @override
  void undo() {
    if (_removedSheet != null && _previousIndex >= 0) {
      workbook.insertSheet(_previousIndex, _removedSheet!);
      if (_previousActiveIndex >= 0 &&
          _previousActiveIndex < workbook.sheetCount) {
        workbook.activeSheetIndex = _previousActiveIndex;
      }
    }
  }
}

/// Reversible command that renames a worksheet.
class RenameWorksheetCommand extends Command {
  /// Creates a [RenameWorksheetCommand] renaming sheet at [index] to [newName].
  RenameWorksheetCommand({
    required this.workbook,
    required this.index,
    required this.newName,
  });

  /// The target workbook.
  final Workbook workbook;

  /// The index of the worksheet to rename.
  final int index;

  /// The new name for the worksheet.
  final String newName;

  String? _oldName;

  @override
  String get description => 'Rename Sheet to "$newName"';

  @override
  void execute() {
    _oldName ??= workbook.sheets[index].name;
    workbook.renameSheet(index, newName);
  }

  @override
  void undo() {
    if (_oldName != null) {
      workbook.renameSheet(index, _oldName!);
    }
  }
}

/// Reversible command that reorders a worksheet within the sheet tabs list.
class ReorderWorksheetCommand extends Command {
  /// Creates a [ReorderWorksheetCommand] moving sheet from [oldIndex] to [newIndex].
  ReorderWorksheetCommand({
    required this.workbook,
    required this.oldIndex,
    required this.newIndex,
  });

  /// The target workbook.
  final Workbook workbook;

  /// Original sheet index.
  final int oldIndex;

  /// New sheet index.
  final int newIndex;

  @override
  String get description => 'Reorder Sheet';

  @override
  void execute() {
    workbook.reorderSheet(oldIndex, newIndex);
  }

  @override
  void undo() {
    workbook.reorderSheet(newIndex, oldIndex);
  }
}

/// Reversible command that resizes a column width in a worksheet.
class ResizeColumnCommand extends Command {
  /// Creates a [ResizeColumnCommand] updating column [colIndex] to [newWidth].
  ResizeColumnCommand({
    required this.worksheet,
    required this.colIndex,
    required this.newWidth,
  });

  /// Target worksheet.
  final Worksheet worksheet;

  /// 0-indexed column integer.
  final int colIndex;

  /// New width in logical pixels.
  final double newWidth;

  double? _previousWidth;
  bool _executedOnce = false;

  @override
  String get description =>
      'Resize Column ${CellCoordinate.columnToLetters(colIndex)}';

  @override
  void execute() {
    if (!_executedOnce) {
      _previousWidth = worksheet.customColumnWidths[colIndex];
      _executedOnce = true;
    }
    worksheet.setColumnWidth(colIndex, newWidth);
  }

  @override
  void undo() {
    if (_previousWidth != null) {
      worksheet.setColumnWidth(colIndex, _previousWidth!);
    } else {
      worksheet.resetColumnWidth(colIndex);
    }
  }
}

/// Reversible command that resizes a row height in a worksheet.
class ResizeRowCommand extends Command {
  /// Creates a [ResizeRowCommand] updating row [rowIndex] to [newHeight].
  ResizeRowCommand({
    required this.worksheet,
    required this.rowIndex,
    required this.newHeight,
  });

  /// Target worksheet.
  final Worksheet worksheet;

  /// 0-indexed row integer.
  final int rowIndex;

  /// New height in logical pixels.
  final double newHeight;

  double? _previousHeight;
  bool _executedOnce = false;

  @override
  String get description => 'Resize Row ${rowIndex + 1}';

  @override
  void execute() {
    if (!_executedOnce) {
      _previousHeight = worksheet.customRowHeights[rowIndex];
      _executedOnce = true;
    }
    worksheet.setRowHeight(rowIndex, newHeight);
  }

  @override
  void undo() {
    if (_previousHeight != null) {
      worksheet.setRowHeight(rowIndex, _previousHeight!);
    } else {
      worksheet.resetRowHeight(rowIndex);
    }
  }
}
