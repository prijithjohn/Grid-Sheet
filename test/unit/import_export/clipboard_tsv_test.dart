import 'package:flutter_test/flutter_test.dart';

import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/data/import_export/csv_engine.dart';
import 'package:grid_sheet/data/import_export/csv_service.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  const engine = CsvEngine();

  // ---------------------------------------------------------------------------
  // BatchImportCommand direct tests
  // ---------------------------------------------------------------------------

  group('BatchImportCommand', () {
    late Worksheet sheet;

    setUp(() {
      sheet = Worksheet(id: 'ws1', name: 'Sheet1');
    });

    test('writes rows starting at origin', () {
      final rows = [
        ['A', 'B', 'C'],
        ['1', '2', '3'],
      ];
      final cmd = BatchImportCommand(
        worksheet: sheet,
        rows: rows,
        origin: const CellCoordinate(0, 0),
      );
      cmd.execute();

      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'A');
      expect(sheet.getCell(const CellCoordinate(0, 2))?.rawInput, 'C');
      expect(sheet.getCell(const CellCoordinate(1, 1))?.rawInput, '2');
    });

    test('writes rows at a non-zero origin offset', () {
      final rows = [
        ['X', 'Y'],
      ];
      final cmd = BatchImportCommand(
        worksheet: sheet,
        rows: rows,
        origin: const CellCoordinate(3, 2),
      );
      cmd.execute();

      expect(sheet.getCell(const CellCoordinate(3, 2))?.rawInput, 'X');
      expect(sheet.getCell(const CellCoordinate(3, 3))?.rawInput, 'Y');
      // Row 0 should be untouched
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNull);
    });

    test('undo restores previous cell state', () {
      // Pre-populate a cell
      sheet.setCell(
        CellModel.fromInput(const CellCoordinate(0, 0), 'OLD'),
      );

      final cmd = BatchImportCommand(
        worksheet: sheet,
        rows: [
          ['NEW'],
        ],
        origin: const CellCoordinate(0, 0),
      );
      cmd.execute();
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'NEW');

      cmd.undo();
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'OLD');
    });

    test('undo removes cells that were not previously present', () {
      final cmd = BatchImportCommand(
        worksheet: sheet,
        rows: [
          ['Fresh'],
        ],
        origin: const CellCoordinate(0, 0),
      );
      cmd.execute();
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNotNull);

      cmd.undo();
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNull);
    });

    test('undo is reversible (execute → undo → execute)', () {
      final cmd = BatchImportCommand(
        worksheet: sheet,
        rows: [
          ['A', 'B'],
        ],
        origin: const CellCoordinate(0, 0),
      );
      cmd.execute();
      cmd.undo();
      cmd.execute();

      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'A');
      expect(sheet.getCell(const CellCoordinate(0, 1))?.rawInput, 'B');
    });

    test('empty field does not create a cell', () {
      final cmd = BatchImportCommand(
        worksheet: sheet,
        rows: [
          ['', 'B', ''],
        ],
        origin: const CellCoordinate(0, 0),
      );
      cmd.execute();
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNull);
      expect(sheet.getCell(const CellCoordinate(0, 1))?.rawInput, 'B');
      expect(sheet.getCell(const CellCoordinate(0, 2)), isNull);
    });

    test('description is human-readable', () {
      final cmd = BatchImportCommand(
        worksheet: sheet,
        rows: [
          ['A'],
          ['B'],
        ],
        origin: const CellCoordinate(0, 0),
      );
      expect(cmd.description, contains('2'));
    });
  });

  // ---------------------------------------------------------------------------
  // WorkbookState.executeBatchImport integration
  // ---------------------------------------------------------------------------

  group('WorkbookState.executeBatchImport', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('import sets cells and marks dirty', () {
      final cmd = BatchImportCommand(
        worksheet: state.activeWorksheet,
        rows: [
          ['Hello', 'World'],
        ],
        origin: const CellCoordinate(0, 0),
      );
      state.executeBatchImport(cmd);

      expect(state.isDirty, isTrue);
      expect(
        state.activeWorksheet
            .getCell(const CellCoordinate(0, 0))
            ?.rawInput,
        'Hello',
      );
    });

    test('import is undoable via undo()', () {
      final cmd = BatchImportCommand(
        worksheet: state.activeWorksheet,
        rows: [
          ['Hello'],
        ],
        origin: const CellCoordinate(0, 0),
      );
      state.executeBatchImport(cmd);
      expect(state.canUndo, isTrue);

      state.undo();
      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0)),
        isNull,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Clipboard TSV copy-paste (unit, no system clipboard)
  // ---------------------------------------------------------------------------

  group('CsvEngine TSV round-trip for clipboard', () {
    test('range written as TSV parses back correctly', () {
      final rows = [
        ['Name', 'Value', 'Notes'],
        ['Alice', '100', 'No comma'],
        ['Bob', '200', 'Has,comma'],
      ];
      final tsv = engine.writeString(
        rows,
        delimiter: CsvDelimiter.tab,
        lineEnding: '\n',
      );
      final parsed = engine.parseString(tsv, delimiter: CsvDelimiter.tab);
      expect(parsed, rows);
    });

    test('3x3 range clipboard format matches Excel convention', () {
      final rows = [
        ['A1', 'B1', 'C1'],
        ['A2', 'B2', 'C2'],
        ['A3', 'B3', 'C3'],
      ];
      final tsv = engine.writeString(
        rows,
        delimiter: CsvDelimiter.tab,
        lineEnding: '\n',
      );
      // Verify structure: 2 newlines separate 3 rows
      expect(tsv.split('\n').length, 3);
      // Verify 2 tabs per row
      for (final line in tsv.split('\n')) {
        expect(line.split('\t').length, 3);
      }
    });

    test('single cell paste round-trip', () {
      final tsv = engine.writeString(
        [
          ['single_value'],
        ],
        delimiter: CsvDelimiter.tab,
        lineEnding: '\n',
      );
      final parsed = engine.parseString(tsv, delimiter: CsvDelimiter.tab);
      expect(parsed, [
        ['single_value'],
      ]);
    });

    test('handles cells with embedded tab in quoted field', () {
      // TSV: a cell with a tab is quoted; parser should recover it
      final rows = [
        ['contains\ttab'],
      ];
      final tsv = engine.writeString(rows, delimiter: CsvDelimiter.tab);
      final parsed = engine.parseString(tsv, delimiter: CsvDelimiter.tab);
      expect(parsed, rows);
    });
  });
}
