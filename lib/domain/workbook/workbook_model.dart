import '../cell/cell_range.dart';
import '../worksheet/worksheet_model.dart';

/// Pure Dart aggregate root representing a multi-sheet spreadsheet workbook.
///
/// Encapsulates ordered worksheets, active sheet state, named ranges,
/// and enforces structural invariants (e.g. workbook must always contain at least one sheet).
class Workbook {
  /// Unique stable identifier for this workbook instance.
  final String id;

  /// User-visible document title or filename.
  String title;

  /// Ordered list of worksheets within this workbook.
  final List<Worksheet> _sheets = [];

  /// 0-indexed index of the currently active worksheet.
  int _activeSheetIndex = 0;

  /// Named ranges defined in this workbook (e.g. `"TaxRates" -> "Sheet1!B2:B10"`).
  final Map<String, CellRange> _namedRanges = {};

  /// Creates a [Workbook].
  ///
  /// If no [initialSheets] are provided, automatically initializes with a single
  /// default worksheet named `"Sheet1"`.
  Workbook({
    required this.id,
    this.title = 'Untitled.gsheet',
    List<Worksheet>? initialSheets,
  }) {
    if (initialSheets != null && initialSheets.isNotEmpty) {
      for (final sheet in initialSheets) {
        addSheet(sheet);
      }
    } else {
      createSheet(name: 'Sheet1');
    }
  }

  /// Factory creating an untitled workbook with a default "Sheet1".
  factory Workbook.createDefault({String title = 'Untitled.gsheet'}) {
    return Workbook(
      id: 'wb_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
    );
  }

  /// Currently active worksheet tab.
  Worksheet get activeSheet => _sheets[_activeSheetIndex];

  /// 0-indexed index of the active worksheet tab.
  int get activeSheetIndex => _activeSheetIndex;

  /// Sets the active worksheet tab by index.
  set activeSheetIndex(int index) {
    if (index < 0 || index >= _sheets.length) {
      throw RangeError.range(index, 0, _sheets.length - 1, 'activeSheetIndex');
    }
    _activeSheetIndex = index;
  }

  /// Read-only unmodifiable view of all worksheets in tab order.
  List<Worksheet> get sheets => List.unmodifiable(_sheets);

  /// Total count of worksheets in this workbook.
  int get sheetCount => _sheets.length;

  /// Creates and appends a new worksheet to the workbook.
  ///
  /// If [name] is omitted, generates a unique default name (`"Sheet1"`, `"Sheet2"`, etc.).
  Worksheet createSheet({String? name}) {
    final sheetName = name ?? _generateDefaultSheetName();
    if (containsSheetName(sheetName)) {
      throw ArgumentError('Worksheet with name "$sheetName" already exists');
    }

    final newSheet = Worksheet(
      id: '${id}_sheet_${DateTime.now().millisecondsSinceEpoch}_${_sheets.length + 1}',
      name: sheetName,
    );
    _sheets.add(newSheet);
    return newSheet;
  }

  /// Appends an existing [sheet] to the workbook.
  ///
  /// Throws [ArgumentError] if a sheet with the same name already exists.
  void addSheet(Worksheet sheet) {
    if (containsSheetName(sheet.name)) {
      throw ArgumentError('Worksheet with name "${sheet.name}" already exists');
    }
    _sheets.add(sheet);
  }

  /// Inserts an existing [sheet] at [index] in the workbook.
  ///
  /// Throws [RangeError] if [index] is out of range.
  /// Throws [ArgumentError] if a sheet with the same name already exists.
  void insertSheet(int index, Worksheet sheet) {
    if (index < 0 || index > _sheets.length) {
      throw RangeError.range(index, 0, _sheets.length, 'index');
    }
    if (containsSheetName(sheet.name)) {
      throw ArgumentError('Worksheet with name "${sheet.name}" already exists');
    }
    _sheets.insert(index, sheet);
  }

  /// Removes [sheet] from the workbook by reference.
  ///
  /// Returns `true` if the sheet was found and removed.
  bool removeSheet(Worksheet sheet) {
    final idx = _sheets.indexOf(sheet);
    if (idx != -1) {
      removeSheetAt(idx);
      return true;
    }
    return false;
  }

  /// Renames the worksheet at [index] to [newName].
  ///
  /// Throws [ArgumentError] if [newName] collides with an existing worksheet.
  void renameSheet(int index, String newName) {
    if (index < 0 || index >= _sheets.length) {
      throw RangeError.range(index, 0, _sheets.length - 1, 'index');
    }
    final validated = Worksheet.validateName(newName);
    final current = _sheets[index];
    if (current.name.toLowerCase() != validated.toLowerCase() &&
        containsSheetName(validated)) {
      throw ArgumentError('Worksheet with name "$validated" already exists');
    }
    current.name = validated;
  }

  /// Removes the worksheet at [index].
  ///
  /// Throws [StateError] if attempting to delete the last remaining sheet
  /// (a workbook must always contain at least one worksheet).
  void removeSheetAt(int index) {
    if (_sheets.length <= 1) {
      throw StateError(
        'Cannot remove the last remaining worksheet in a workbook',
      );
    }
    if (index < 0 || index >= _sheets.length) {
      throw RangeError.range(index, 0, _sheets.length - 1, 'index');
    }

    _sheets.removeAt(index);

    // Adjust active sheet index if needed
    if (_activeSheetIndex >= _sheets.length) {
      _activeSheetIndex = _sheets.length - 1;
    } else if (_activeSheetIndex > index) {
      _activeSheetIndex--;
    }
  }

  /// Reorders a worksheet from [oldIndex] to [newIndex] (e.g. via drag-and-drop tab reordering).
  void reorderSheet(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _sheets.length) {
      throw RangeError.range(oldIndex, 0, _sheets.length - 1, 'oldIndex');
    }
    if (newIndex < 0 || newIndex >= _sheets.length) {
      throw RangeError.range(newIndex, 0, _sheets.length - 1, 'newIndex');
    }
    if (oldIndex == newIndex) return;

    final sheet = _sheets.removeAt(oldIndex);
    _sheets.insert(newIndex, sheet);

    // Track active sheet pointer during reorder
    if (_activeSheetIndex == oldIndex) {
      _activeSheetIndex = newIndex;
    } else if (oldIndex < _activeSheetIndex && newIndex >= _activeSheetIndex) {
      _activeSheetIndex--;
    } else if (oldIndex > _activeSheetIndex && newIndex <= _activeSheetIndex) {
      _activeSheetIndex++;
    }
  }

  /// Finds a worksheet by its case-insensitive name, or returns `null` if not found.
  Worksheet? getSheetByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final sheet in _sheets) {
      if (sheet.name.toLowerCase() == lower) {
        return sheet;
      }
    }
    return null;
  }

  /// Finds a worksheet by its unique ID, or returns `null` if not found.
  Worksheet? getSheetById(String id) {
    for (final sheet in _sheets) {
      if (sheet.id == id) {
        return sheet;
      }
    }
    return null;
  }

  /// Whether a sheet with [name] (case-insensitive) exists in this workbook.
  bool containsSheetName(String name) {
    return getSheetByName(name) != null;
  }

  /// Defines or updates a workbook-level named range.
  void setNamedRange(String name, CellRange range) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Named range cannot be empty');
    }
    _namedRanges[trimmed] = range;
  }

  /// Retrieves a named range by name, or `null` if undefined.
  CellRange? getNamedRange(String name) => _namedRanges[name.trim()];

  /// Generates a unique default sheet name (`"Sheet1"`, `"Sheet2"`, etc.).
  String _generateDefaultSheetName() {
    var counter = _sheets.length + 1;
    while (containsSheetName('Sheet$counter')) {
      counter++;
    }
    return 'Sheet$counter';
  }

  @override
  String toString() =>
      'Workbook(title: "$title", sheets: ${_sheets.length}, active: ${activeSheet.name})';
}
