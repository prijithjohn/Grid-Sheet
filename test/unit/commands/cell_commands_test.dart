import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/core/commands/commands.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('SetCellTextCommand - Cell Editing & Reversibility', () {
    late Worksheet sheet;

    setUp(() {
      sheet = Worksheet(id: 'sheet_1', name: 'Sheet1');
    });

    test('sets text on previously empty cell and reverses cleanly on undo', () {
      const coord = CellCoordinate(0, 0); // A1
      final cmd = SetCellTextCommand(
        worksheet: sheet,
        coordinate: coord,
        newText: 'Hello World',
      );

      expect(cmd.description, equals('Edit Cell A1'));
      expect(sheet.getCell(coord), isNull);

      cmd.execute();
      expect(sheet.getCell(coord)?.rawInput, equals('Hello World'));
      expect(sheet.getCell(coord)?.value.displayString, equals('Hello World'));

      cmd.undo();
      expect(sheet.getCell(coord), isNull);

      cmd.execute();
      expect(sheet.getCell(coord)?.rawInput, equals('Hello World'));
    });

    test(
      'overwrites existing cell and restores original value and style on undo',
      () {
        const coord = CellCoordinate(1, 1); // B2
        const initialStyle = CellStyle(isBold: true, fontSize: 16);
        sheet.setCell(CellModel.fromInput(coord, '42', style: initialStyle));

        final cmd = SetCellTextCommand(
          worksheet: sheet,
          coordinate: coord,
          newText: '100',
        );

        cmd.execute();
        expect(sheet.getCell(coord)?.rawInput, equals('100'));
        expect(sheet.getCell(coord)?.value, isA<NumberCellValue>());
        // Preserves existing cell style when text is edited
        expect(sheet.getCell(coord)?.style.isBold, isTrue);
        expect(sheet.getCell(coord)?.style.fontSize, equals(16));

        cmd.undo();
        expect(sheet.getCell(coord)?.rawInput, equals('42'));
        expect(sheet.getCell(coord)?.style.isBold, isTrue);

        cmd.execute();
        expect(sheet.getCell(coord)?.rawInput, equals('100'));
      },
    );

    test(
      'setting empty or whitespace string removes cell and restores on undo',
      () {
        const coord = CellCoordinate(2, 2); // C3
        sheet.setCell(CellModel.fromInput(coord, 'Data'));

        final cmd = SetCellTextCommand(
          worksheet: sheet,
          coordinate: coord,
          newText: '   ',
        );

        cmd.execute();
        expect(sheet.getCell(coord), isNull);

        cmd.undo();
        expect(sheet.getCell(coord)?.rawInput, equals('Data'));
      },
    );

    test('recognizes formula prefix when setting text', () {
      const coord = CellCoordinate(3, 0); // A4
      final cmd = SetCellTextCommand(
        worksheet: sheet,
        coordinate: coord,
        newText: '=SUM(A1:A3)',
      );

      cmd.execute();
      expect(sheet.getCell(coord)?.isFormula, isTrue);
      expect(sheet.getCell(coord)?.formula, equals('SUM(A1:A3)'));

      cmd.undo();
      expect(sheet.getCell(coord), isNull);
    });
  });

  group('ClearRangeCommand - Spatial Range Clearing & Restoration', () {
    late Worksheet sheet;

    setUp(() {
      sheet = Worksheet(id: 'sheet_1', name: 'Sheet1');
      // Populate A1, B2, C3, and D4
      sheet.setCell(CellModel.fromInput(const CellCoordinate(0, 0), 'A1'));
      sheet.setCell(CellModel.fromInput(const CellCoordinate(1, 1), 'B2'));
      sheet.setCell(CellModel.fromInput(const CellCoordinate(2, 2), 'C3'));
      sheet.setCell(CellModel.fromInput(const CellCoordinate(3, 3), 'D4'));
    });

    test('clears cells within range while leaving cells outside untouched', () {
      // Range A1:B2 (0,0 to 1,1)
      final range = CellRange.fromA1('A1:B2');
      final cmd = ClearRangeCommand(worksheet: sheet, range: range);

      expect(cmd.description, equals('Clear Range A1:B2'));

      cmd.execute();
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNull);
      expect(sheet.getCell(const CellCoordinate(1, 1)), isNull);
      // C3 and D4 must remain
      expect(sheet.getCell(const CellCoordinate(2, 2))?.rawInput, equals('C3'));
      expect(sheet.getCell(const CellCoordinate(3, 3))?.rawInput, equals('D4'));

      cmd.undo();
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, equals('A1'));
      expect(sheet.getCell(const CellCoordinate(1, 1))?.rawInput, equals('B2'));
      expect(sheet.getCell(const CellCoordinate(2, 2))?.rawInput, equals('C3'));
      expect(sheet.getCell(const CellCoordinate(3, 3))?.rawInput, equals('D4'));

      cmd.execute();
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNull);
      expect(sheet.getCell(const CellCoordinate(1, 1)), isNull);
    });

    test('clearing empty range executes safely without exceptions', () {
      final range = CellRange.fromA1('E10:G15');
      final cmd = ClearRangeCommand(worksheet: sheet, range: range);

      cmd.execute();
      expect(sheet.populatedCellCount, equals(4));

      cmd.undo();
      expect(sheet.populatedCellCount, equals(4));
    });
  });

  group('FormatRangeCommand - Bulk Styling Reversibility', () {
    late Worksheet sheet;

    setUp(() {
      sheet = Worksheet(id: 'sheet_1', name: 'Sheet1');
      sheet.setCell(
        CellModel.fromInput(
          const CellCoordinate(0, 0),
          'Header',
          style: const CellStyle(fontSize: 14),
        ),
      );
    });

    test(
      'updates styles across range and restores exact previous state on undo',
      () {
        final range = CellRange.fromA1('A1:B2');
        final cmd = FormatRangeCommand(
          worksheet: sheet,
          range: range,
          styleUpdater: (current) =>
              current.copyWith(isBold: true, isItalic: true),
          customDescription: 'Bold & Italic A1:B2',
        );

        expect(cmd.description, equals('Bold & Italic A1:B2'));

        cmd.execute();
        // A1 was populated: updated to bold, italic, preserving 14pt
        final a1 = sheet.getCell(const CellCoordinate(0, 0))!;
        expect(a1.rawInput, equals('Header'));
        expect(a1.style.isBold, isTrue);
        expect(a1.style.isItalic, isTrue);
        expect(a1.style.fontSize, equals(14));

        // B2 was empty: styled placeholder created
        final b2 = sheet.getCell(const CellCoordinate(1, 1))!;
        expect(b2.rawInput, isEmpty);
        expect(b2.style.isBold, isTrue);
        expect(b2.style.isItalic, isTrue);

        cmd.undo();
        // A1 restored to original
        final a1Restored = sheet.getCell(const CellCoordinate(0, 0))!;
        expect(a1Restored.style.isBold, isFalse);
        expect(a1Restored.style.isItalic, isFalse);
        expect(a1Restored.style.fontSize, equals(14));

        // B2 was previously unpopulated: removed on undo
        expect(sheet.getCell(const CellCoordinate(1, 1)), isNull);
      },
    );
  });
}
