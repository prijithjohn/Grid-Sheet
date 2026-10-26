import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../app/state/workbook_state.dart';
import '../../core/commands/commands.dart';
import '../../domain/domain.dart';
import 'csv_engine.dart';

/// Configuration options for a CSV import operation.
class CsvImportOptions {
  const CsvImportOptions({
    this.delimiter = CsvDelimiter.comma,
    this.encoding = CsvEncoding.utf8,
    this.firstRowIsHeader = false,
    this.destination = CsvImportDestination.activeCell,
  });

  /// Delimiter used when parsing.
  final CsvDelimiter delimiter;

  /// Text encoding used when reading the file bytes.
  final CsvEncoding encoding;

  /// Whether the first row of data is treated as a header row (skipped
  /// during import but may influence column width hints in future versions).
  final bool firstRowIsHeader;

  /// Where the imported data should be placed.
  final CsvImportDestination destination;

  CsvImportOptions copyWith({
    CsvDelimiter? delimiter,
    CsvEncoding? encoding,
    bool? firstRowIsHeader,
    CsvImportDestination? destination,
  }) {
    return CsvImportOptions(
      delimiter: delimiter ?? this.delimiter,
      encoding: encoding ?? this.encoding,
      firstRowIsHeader: firstRowIsHeader ?? this.firstRowIsHeader,
      destination: destination ?? this.destination,
    );
  }
}

/// Determines where imported rows are placed within the workbook.
enum CsvImportDestination {
  /// Starts at the active cell cursor position.
  activeCell('At Active Cell'),

  /// Replaces all data in the current sheet.
  replaceActiveSheet('Replace Active Sheet'),

  /// Creates a brand-new worksheet tab.
  newWorksheet('New Worksheet');

  const CsvImportDestination(this.label);

  final String label;
}

/// Result of a CSV service operation.
class CsvOperationResult {
  const CsvOperationResult({
    required this.success,
    this.rowsAffected = 0,
    this.columnsAffected = 0,
    this.errorMessage,
    this.filePath,
  });

  final bool success;
  final int rowsAffected;
  final int columnsAffected;
  final String? errorMessage;
  final String? filePath;

  static const CsvOperationResult cancelled = CsvOperationResult(
    success: false,
    errorMessage: 'Operation cancelled by user.',
  );
}

/// High-level service orchestrating CSV/TSV import and export workflows.
///
/// Integrates [CsvEngine] with [WorkbookState], file-picker, and the
/// command stack to ensure all mutations are undoable in a single step.
class CsvService {
  const CsvService({CsvEngine? engine}) : _engine = engine ?? const CsvEngine();

  final CsvEngine _engine;

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Opens a native file picker for `.csv` / `.tsv` files and returns the raw
  /// rows and a detected delimiter suggestion for use in a preview dialog.
  ///
  /// Returns `null` if the user cancels the picker.
  Future<({File file, List<List<String>> preview, CsvDelimiter suggested})?>
  pickAndPreview() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'txt'],
        dialogTitle: 'Open CSV / TSV File',
      );
      if (result.isEmpty || result.first.path == null) return null;
      final path = result.first.path!;

      final file = File(path);
      final bytes = await file.readAsBytes();
      // Strip BOM if present for detection
      final sample = _stripBom(
        String.fromCharCodes(
          bytes.length > 8192 ? bytes.sublist(0, 8192) : bytes,
        ),
      );

      final detection = _engine.detectDelimiter(sample, maxLines: 20);
      final suggested = detection.delimiter;

      // Parse up to 20 preview rows
      final allRows = _engine.parseString(sample, delimiter: suggested);
      final preview = allRows.take(20).toList();

      return (file: file, preview: preview, suggested: suggested);
    } catch (_) {
      return null;
    }
  }

  /// Imports [file] into [state] using [options].
  ///
  /// All cell mutations are wrapped in a single compound [BatchImportCommand]
  /// so a single `Ctrl+Z` undoes the entire import.
  Future<CsvOperationResult> importFile(
    File file,
    WorkbookState state, {
    required CsvImportOptions options,
  }) async {
    try {
      final rows = await _engine.parseFile(
        file,
        delimiter: options.delimiter,
        encoding: options.encoding,
      );

      if (rows.isEmpty) {
        return const CsvOperationResult(
          success: true,
          errorMessage: 'File is empty — no data was imported.',
        );
      }

      final dataRows = options.firstRowIsHeader && rows.length > 1
          ? rows.sublist(1)
          : rows;

      final origin = _resolveOrigin(state, options.destination);

      if (options.destination == CsvImportDestination.newWorksheet) {
        state.addWorksheet(name: _baseName(file.path));
        // Execute on the newly added (now active) worksheet
        final newCmd = BatchImportCommand(
          worksheet: state.activeWorksheet,
          rows: dataRows,
          origin: const CellCoordinate(0, 0),
        );
        state.executeBatchImport(newCmd);
      } else if (options.destination ==
          CsvImportDestination.replaceActiveSheet) {
        final cmd = BatchImportCommand(
          worksheet: state.activeWorksheet,
          rows: dataRows,
          origin: const CellCoordinate(0, 0),
        );
        state.clearAndImport(cmd);
      } else {
        final cmd = BatchImportCommand(
          worksheet: state.activeWorksheet,
          rows: dataRows,
          origin: origin,
        );
        state.executeBatchImport(cmd);
      }

      final maxCols = dataRows.fold<int>(
        0,
        (m, r) => r.length > m ? r.length : m,
      );
      return CsvOperationResult(
        success: true,
        rowsAffected: dataRows.length,
        columnsAffected: maxCols,
        filePath: file.path,
      );
    } catch (e) {
      return CsvOperationResult(
        success: false,
        errorMessage: 'Import failed: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Exports the active sheet of [state] to a user-selected file location.
  Future<CsvOperationResult> exportActiveSheet(
    WorkbookState state, {
    CsvDelimiter delimiter = CsvDelimiter.comma,
  }) async {
    final sheet = state.activeWorksheet;
    final rows = _sheetToRows(sheet);

    final ext = delimiter == CsvDelimiter.tab ? 'tsv' : 'csv';
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Export as ${ext.toUpperCase()}',
        fileName: '${sheet.name}.$ext',
        bytes: Uint8List(0),
      );
      if (uri == null) return CsvOperationResult.cancelled;

      // FilePicker.saveFile returns a Uri — convert to file path
      final filePath = uri.toFilePath();
      final file = File(filePath);
      await _engine.writeFile(file, rows, delimiter: delimiter);
      return CsvOperationResult(
        success: true,
        rowsAffected: rows.length,
        columnsAffected: rows.fold<int>(
          0,
          (m, r) => r.length > m ? r.length : m,
        ),
        filePath: filePath,
      );
    } catch (_) {
      return CsvOperationResult.cancelled;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CellCoordinate _resolveOrigin(
    WorkbookState state,
    CsvImportDestination dest,
  ) {
    return dest == CsvImportDestination.activeCell
        ? state.selection.primaryCell
        : const CellCoordinate(0, 0);
  }

  List<List<String>> _sheetToRows(Worksheet sheet) {
    final maxRow = sheet.maxPopulatedRow;
    final maxCol = sheet.maxPopulatedCol;
    if (maxRow < 0 || maxCol < 0) return [];

    final rows = <List<String>>[];
    for (var r = 0; r <= maxRow; r++) {
      final row = <String>[];
      for (var c = 0; c <= maxCol; c++) {
        final cell = sheet.getCell(CellCoordinate(r, c));
        row.add(cell?.formattedText ?? '');
      }
      rows.add(row);
    }
    return rows;
  }

  String _stripBom(String s) => s.startsWith('\uFEFF') ? s.substring(1) : s;

  String _baseName(String path) {
    final base = path.replaceAll('\\', '/').split('/').last;
    final dot = base.lastIndexOf('.');
    return dot == -1 ? base : base.substring(0, dot);
  }
}

/// A compound undoable command that writes a 2D array of [rows] into
/// [worksheet] starting from [origin], saving previous cell state for undo.
class BatchImportCommand extends Command {
  BatchImportCommand({
    required this.worksheet,
    required this.rows,
    required this.origin,
  });

  final Worksheet worksheet;
  final List<List<String>> rows;
  final CellCoordinate origin;

  final Map<CellCoordinate, CellModel?> _previousCells = {};
  bool _executedOnce = false;

  @override
  String get description => 'Import ${rows.length} row(s) from CSV/TSV';

  @override
  void execute() {
    if (!_executedOnce) {
      // Snapshot existing cells in the target region for undo
      for (var r = 0; r < rows.length; r++) {
        for (var c = 0; c < rows[r].length; c++) {
          final coord = CellCoordinate(
            (origin.row + r).clamp(0, CellCoordinate.maxRows - 1),
            (origin.col + c).clamp(0, CellCoordinate.maxCols - 1),
          );
          _previousCells[coord] = worksheet.getCell(coord);
        }
      }
      _executedOnce = true;
    }

    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final coord = CellCoordinate(
          (origin.row + r).clamp(0, CellCoordinate.maxRows - 1),
          (origin.col + c).clamp(0, CellCoordinate.maxCols - 1),
        );
        final text = rows[r][c];
        if (text.isEmpty) {
          worksheet.removeCell(coord);
        } else {
          worksheet.setCell(CellModel.fromInput(coord, text));
        }
      }
    }
  }

  @override
  void undo() {
    // Restore the snapshotted cells exactly
    for (final entry in _previousCells.entries) {
      final prev = entry.value;
      if (prev == null) {
        worksheet.removeCell(entry.key);
      } else {
        worksheet.setCell(prev);
      }
    }
    // Clear any cells that were written beyond the snapshot region
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final coord = CellCoordinate(
          (origin.row + r).clamp(0, CellCoordinate.maxRows - 1),
          (origin.col + c).clamp(0, CellCoordinate.maxCols - 1),
        );
        if (!_previousCells.containsKey(coord)) {
          worksheet.removeCell(coord);
        }
      }
    }
  }
}
