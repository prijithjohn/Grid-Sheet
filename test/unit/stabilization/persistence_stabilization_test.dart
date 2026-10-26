import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/data/import_export/csv_engine.dart';
import 'package:grid_sheet/data/persistence/workbook_persistence.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Phase 09: Persistence & Import/Export Stabilization Tests', () {
    late Directory tempDir;
    late WorkbookPersistence persistence;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gsheet_phase09_');
      persistence = WorkbookPersistence();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Repeated save/open cycles preserve full workbook state, formatting and freeze panes', () async {
      final savePath = p.join(tempDir.path, 'lifecycle.gsheet');

      // 1. Create rich workbook
      final wb = Workbook(id: 'wb_life', title: 'Lifecycle');
      final sheet1 = wb.sheets[0];
      sheet1.name = 'DataSheet';
      sheet1.setColumnWidth(0, 140.0);
      sheet1.setRowHeight(0, 36.0);
      sheet1.freezePanes(rows: 1, cols: 1);

      sheet1.setCell(
        const Cell(
          coordinate: CellCoordinate(0, 0),
          rawInput: 'Item Name',
          style: CellStyle(isBold: true, isItalic: true),
        ),
      );
      sheet1.setCell(
        const Cell(
          coordinate: CellCoordinate(1, 0),
          rawInput: '=SUM(10, 20)',
          computedValue: NumberCellValue(30),
        ),
      );

      final sheet2 = wb.createSheet(name: 'Summary');
      sheet2.setCell(
        const Cell(
          coordinate: CellCoordinate(0, 0),
          rawInput: '=DataSheet!A2*2',
        ),
      );

      // Cycle 1: Save & Load
      final res1 = await persistence.save(wb, savePath);
      expect(res1.success, isTrue);

      final loadRes1 = await persistence.load(savePath);
      expect(loadRes1.isSuccess, isTrue);
      final loaded1 = loadRes1.workbook!;

      expect(loaded1.sheets.length, equals(2));
      expect(loaded1.sheets[0].name, equals('DataSheet'));
      expect(loaded1.sheets[0].getColumnWidth(0), equals(140.0));
      expect(loaded1.sheets[0].getRowHeight(0), equals(36.0));
      expect(loaded1.sheets[0].frozenRows, equals(1));
      expect(loaded1.sheets[0].frozenCols, equals(1));
      expect(
        loaded1.sheets[0].getCell(const CellCoordinate(0, 0))?.style.isBold,
        isTrue,
      );
      expect(
        loaded1.sheets[0].getCell(const CellCoordinate(0, 0))?.style.isItalic,
        isTrue,
      );
      expect(
        loaded1.sheets[0].getCell(const CellCoordinate(1, 0))?.rawInput,
        equals('=SUM(10, 20)'),
      );
      expect(loaded1.sheets[1].name, equals('Summary'));

      // Cycle 2: Overwrite existing file on disk and re-load
      final res2 = await persistence.save(loaded1, savePath);
      expect(res2.success, isTrue);

      final loadRes2 = await persistence.load(savePath);
      expect(loadRes2.isSuccess, isTrue);
      final loaded2 = loadRes2.workbook!;

      expect(loaded2.sheets.length, equals(2));
      expect(loaded2.sheets[0].frozenRows, equals(1));
      expect(loaded2.sheets[0].frozenCols, equals(1));
      expect(loaded2.sheets[0].getColumnWidth(0), equals(140.0));
      expect(loaded2.sheets[0].getRowHeight(0), equals(36.0));
      expect(
        loaded2.sheets[0].getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Item Name'),
      );
    });

    test(
      'Failed load on corrupt file returns failure and does not crash',
      () async {
        final corruptPath = p.join(tempDir.path, 'bad.gsheet');
        await File(corruptPath)
            .writeAsString('{"invalid_json": true, incomplete...');

        final result = await persistence.load(corruptPath);
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(result.workbook, isNull);
      },
    );

    test('CSV/TSV Engine parses quotes, embedded newlines, and Unicode correctly', () {
      const csvEngine = CsvEngine();
      // CSV string with embedded comma, quotes inside quotes, newline in quotes, and Unicode
      const input =
          '"Product, Name","""Special"" Edition","Line 1\nLine 2","日本語 / Español €"';

      final rows = csvEngine.parseString(input, delimiter: CsvDelimiter.comma);
      expect(rows.length, equals(1));
      expect(rows[0].length, equals(4));

      expect(rows[0][0], equals('Product, Name'));
      expect(rows[0][1], equals('"Special" Edition'));
      expect(rows[0][2], equals('Line 1\nLine 2'));
      expect(rows[0][3], equals('日本語 / Español €'));

      // Round-trip export back to CSV
      final exported = csvEngine.writeString(
        rows,
        delimiter: CsvDelimiter.comma,
      );
      final reParsed = csvEngine.parseString(
        exported,
        delimiter: CsvDelimiter.comma,
      );

      expect(reParsed[0][0], equals('Product, Name'));
      expect(reParsed[0][1], equals('"Special" Edition'));
      expect(reParsed[0][2], equals('Line 1\nLine 2'));
      expect(reParsed[0][3], equals('日本語 / Español €'));
    });

    test('Delimiter auto-detection accurately distinguishes comma, tab, and semicolon', () {
      const csvEngine = CsvEngine();

      const commaSample = 'Name,Age,City\nAlice,30,NYC\nBob,25,LA';
      expect(
        csvEngine.detectDelimiter(commaSample).delimiter,
        equals(CsvDelimiter.comma),
      );

      const tabSample = 'Name\tAge\tCity\nAlice\t30\tNYC\nBob\t25\tLA';
      expect(
        csvEngine.detectDelimiter(tabSample).delimiter,
        equals(CsvDelimiter.tab),
      );

      const semiSample = 'Name;Age;City\nAlice;30;NYC\nBob;25;LA';
      expect(
        csvEngine.detectDelimiter(semiSample).delimiter,
        equals(CsvDelimiter.semicolon),
      );
    });
  });
}
