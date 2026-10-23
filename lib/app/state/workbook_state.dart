import 'package:flutter/foundation.dart';

import '../../core/commands/commands.dart';
import '../../domain/domain.dart';
import 'selection_state.dart';

/// Central reactive state controller managing the active [Workbook], active [Worksheet],
/// current [SelectionState], and the reversible [CommandStack].
///
/// Dispatches changes to UI listeners via [ChangeNotifier].
class WorkbookState extends ChangeNotifier {
  /// Creates a [WorkbookState] managing an optional [initialWorkbook].
  WorkbookState({
    Workbook? initialWorkbook,
    CommandStack? commandStack,
    SelectionState? initialSelection,
    String? filePath,
  }) : _workbook = initialWorkbook ?? Workbook.createDefault(),
       _commandStack = commandStack ?? CommandStack(),
       _selection = initialSelection ?? SelectionState.initial {
    _filePath = filePath;
  }

  Workbook _workbook;
  final CommandStack _commandStack;
  SelectionState _selection;
  String? _filePath;
  bool _isDirty = false;

  /// The active workbook aggregate.
  Workbook get workbook => _workbook;

  /// The currently active worksheet tab.
  Worksheet get activeWorksheet => _workbook.activeSheet;

  /// 0-indexed integer of the active worksheet tab.
  int get activeSheetIndex => _workbook.activeSheetIndex;

  /// Total count of worksheets in the workbook.
  int get sheetCount => _workbook.sheetCount;

  /// Ordered list of all worksheet tabs.
  List<Worksheet> get sheets => _workbook.sheets;

  /// The active selection state.
  SelectionState get selection => _selection;

  /// The command history manager.
  CommandStack get commandStack => _commandStack;

  /// Whether an undo operation can be performed.
  bool get canUndo => _commandStack.canUndo;

  /// Whether a redo operation can be performed.
  bool get canRedo => _commandStack.canRedo;

  /// Whether there are unsaved modifications since creation or last save.
  bool get isDirty => _isDirty;

  /// File path of the currently opened file, or `null` if untitled.
  String? get filePath => _filePath;

  /// The cell at the primary selection coordinate, or `null` if unpopulated.
  CellModel? get activeCell => activeWorksheet.getCell(_selection.primaryCell);

  /// The raw input string of the active cell, or empty string if empty.
  String get activeCellInput => activeCell?.rawInput ?? '';

  /// Formatted A1 address string of the active cell cursor (e.g. "B2").
  String get activeCellAddress => _selection.primaryCell.a1;

  /// Width in logical pixels of the column holding the primary active cell.
  double get activeColumnWidth =>
      activeWorksheet.getColumnWidth(_selection.primaryCell.col);

  /// Height in logical pixels of the row holding the primary active cell.
  double get activeRowHeight =>
      activeWorksheet.getRowHeight(_selection.primaryCell.row);

  // ---------------------------------------------------------------------------
  // Cell & Range Mutations (Routed through CommandStack)
  // ---------------------------------------------------------------------------

  /// Edits the text of the primary selected cell.
  void editActiveCell(String input) {
    editCellAt(_selection.primaryCell, input);
  }

  /// Edits the text of the cell at [coordinate].
  void editCellAt(CellCoordinate coordinate, String input) {
    final cmd = SetCellTextCommand(
      worksheet: activeWorksheet,
      coordinate: coordinate,
      newText: input,
    );
    _executeCommand(cmd);
  }

  /// Clears all cells within the current active selection range.
  void clearSelection() {
    final cmd = ClearRangeCommand(
      worksheet: activeWorksheet,
      range: _selection.activeRange,
    );
    _executeCommand(cmd);
  }

  /// Applies a [CellStyle] transformation across all cells in the active selection range.
  void applyStyleToSelection(
    CellStyle Function(CellStyle current) updater, {
    String? description,
  }) {
    final cmd = FormatRangeCommand(
      worksheet: activeWorksheet,
      range: _selection.activeRange,
      styleUpdater: updater,
      customDescription: description,
    );
    _executeCommand(cmd);
  }

  // ---------------------------------------------------------------------------
  // Worksheet Operations (Routed through CommandStack)
  // ---------------------------------------------------------------------------

  /// Adds a new worksheet tab to the workbook.
  void addWorksheet({String? name, int? index}) {
    final cmd = AddWorksheetCommand(
      workbook: _workbook,
      name: name,
      index: index,
    );
    _executeCommand(cmd);
  }

  /// Removes the worksheet at [index].
  void removeWorksheetAt(int index) {
    final cmd = RemoveWorksheetCommand(workbook: _workbook, index: index);
    _executeCommand(cmd);
  }

  /// Renames the worksheet at [index] to [newName].
  void renameWorksheet(int index, String newName) {
    final cmd = RenameWorksheetCommand(
      workbook: _workbook,
      index: index,
      newName: newName,
    );
    _executeCommand(cmd);
  }

  /// Reorders a worksheet tab from [oldIndex] to [newIndex].
  void reorderWorksheets(int oldIndex, int newIndex) {
    final cmd = ReorderWorksheetCommand(
      workbook: _workbook,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    _executeCommand(cmd);
  }

  /// Resizes column [colIndex] on the active worksheet.
  void resizeColumn(int colIndex, double width) {
    final cmd = ResizeColumnCommand(
      worksheet: activeWorksheet,
      colIndex: colIndex,
      newWidth: width,
    );
    _executeCommand(cmd);
  }

  /// Resizes row [rowIndex] on the active worksheet.
  void resizeRow(int rowIndex, double height) {
    final cmd = ResizeRowCommand(
      worksheet: activeWorksheet,
      rowIndex: rowIndex,
      newHeight: height,
    );
    _executeCommand(cmd);
  }

  // ---------------------------------------------------------------------------
  // Selection & Navigation
  // ---------------------------------------------------------------------------

  /// Switches the active worksheet to [index] and resets selection to A1.
  void setActiveSheetIndex(int index) {
    if (index == _workbook.activeSheetIndex) return;
    _workbook.activeSheetIndex = index;
    _selection = SelectionState.initial;
    notifyListeners();
  }

  /// Selects a single cell at [coordinate].
  void selectCell(CellCoordinate coordinate) {
    _selection = _selection.selectCell(coordinate);
    notifyListeners();
  }

  /// Selects a rectangular range from [range].
  void selectRange(CellRange range, {CellCoordinate? primaryCell}) {
    _selection = SelectionState.fromRange(range, primaryCell: primaryCell);
    notifyListeners();
  }

  /// Extends the active selection from the primary anchor to [toCoordinate].
  void extendSelection(CellCoordinate toCoordinate) {
    _selection = _selection.extendSelection(toCoordinate);
    notifyListeners();
  }

  /// Selects an entire row.
  void selectEntireRow(int row) {
    _selection = _selection.selectEntireRow(row);
    notifyListeners();
  }

  /// Selects an entire column.
  void selectEntireColumn(int col) {
    _selection = _selection.selectEntireColumn(col);
    notifyListeners();
  }

  /// Selects the entire worksheet.
  void selectAll() {
    _selection = _selection.selectAll();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Undo, Redo and Lifecycle
  // ---------------------------------------------------------------------------

  /// Undoes the most recent command.
  bool undo() {
    final undone = _commandStack.undo();
    if (undone != null) {
      _isDirty = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Redoes the most recently undone command.
  bool redo() {
    final redone = _commandStack.redo();
    if (redone != null) {
      _isDirty = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Replaces the current workbook with a new [workbook] instance (e.g. after file open).
  void loadWorkbook(Workbook workbook, {String? filePath}) {
    _workbook = workbook;
    _selection = SelectionState.initial;
    _filePath = filePath;
    _isDirty = false;
    _commandStack.clear();
    notifyListeners();
  }

  /// Resets dirty state, typically called after a successful file save.
  void markClean({String? savedFilePath}) {
    _isDirty = false;
    if (savedFilePath != null) {
      _filePath = savedFilePath;
    }
    notifyListeners();
  }

  /// Updates the associated local file path.
  void setFilePath(String? path) {
    _filePath = path;
    notifyListeners();
  }

  void _executeCommand(Command command) {
    _commandStack.execute(command);
    _isDirty = true;
    notifyListeners();
  }
}
