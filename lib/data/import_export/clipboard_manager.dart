import 'package:flutter/services.dart';

import '../../app/state/workbook_state.dart';
import '../../domain/domain.dart';
import 'csv_engine.dart';
import 'csv_service.dart' show BatchImportCommand;

/// Manages system clipboard interactions for spreadsheet copy/cut/paste in TSV format.
///
/// Uses tab-delimited text (`\t` column separator, `\n` row separator) which is
/// the standard interchange format understood by Excel, Google Sheets, etc.
class ClipboardManager {
  const ClipboardManager({CsvEngine? engine})
      : _engine = engine ?? const CsvEngine();

  final CsvEngine _engine;

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  /// Copies the active selection range from [state] to the system clipboard
  /// as tab-separated values.
  ///
  /// Returns the number of cells placed on the clipboard.
  Future<int> copySelection(WorkbookState state) async {
    final range = state.selection.activeRange;
    final sheet = state.activeWorksheet;

    final rows = _rangeToRows(sheet, range);
    final tsv = _engine.writeString(
      rows,
      delimiter: CsvDelimiter.tab,
      lineEnding: '\n',
    );

    await Clipboard.setData(ClipboardData(text: tsv));
    return range.rowCount * range.colCount;
  }

  /// Cuts the active selection range: copies to clipboard and then clears the
  /// source cells. The clear is recorded as a separate undoable command so that
  /// the paste and the clear can be individually undone.
  Future<int> cutSelection(WorkbookState state) async {
    final count = await copySelection(state);
    state.clearSelection();
    return count;
  }

  // ---------------------------------------------------------------------------
  // Paste
  // ---------------------------------------------------------------------------

  /// Pastes the current system clipboard content (if text) into the active
  /// sheet starting at the active cell cursor.
  ///
  /// The content is parsed as TSV/CSV. A single [BatchImportCommand] records
  /// the entire paste so a single `Ctrl+Z` undoes it.
  ///
  /// Returns the number of cells written, or 0 if the clipboard is empty.
  Future<int> pasteAtCursor(WorkbookState state) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return 0;

    // Parse pasted TSV (fall back to comma if tab isn't the detected delimiter)
    final detection = _engine.detectDelimiter(text, maxLines: 5);
    final delimiter = detection.confidence > 0.3
        ? detection.delimiter
        : CsvDelimiter.tab;

    final rows = _engine.parseString(text, delimiter: delimiter);
    if (rows.isEmpty) return 0;

    final origin = state.selection.primaryCell;
    final cmd = BatchImportCommand(
      worksheet: state.activeWorksheet,
      rows: rows,
      origin: origin,
    );
    state.executeBatchImport(cmd);

    final maxCols = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return rows.length * maxCols;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  List<List<String>> _rangeToRows(Worksheet sheet, CellRange range) {
    final rows = <List<String>>[];
    for (var r = range.topRow; r <= range.bottomRow; r++) {
      final row = <String>[];
      for (var c = range.leftCol; c <= range.rightCol; c++) {
        final cell = sheet.getCell(CellCoordinate(r, c));
        row.add(cell?.formattedText ?? '');
      }
      rows.add(row);
    }
    return rows;
  }
}
