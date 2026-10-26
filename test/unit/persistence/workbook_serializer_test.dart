import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/data/serialization/serialization.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('WorkbookSerializer Tests', () {
    const serializer = WorkbookSerializer();

    test('serializes and deserializes default blank workbook', () {
      final original = Workbook.createDefault(title: 'Blank Test.gsheet');
      final encoded = serializer.encode(original);

      expect(encoded, contains('"schemaVersion":1'));
      expect(encoded, contains('"title":"Blank Test.gsheet"'));

      final decoded = serializer.decode(encoded);
      expect(decoded.title, equals(original.title));
      expect(decoded.sheetCount, equals(original.sheetCount));
      expect(decoded.activeSheetIndex, equals(original.activeSheetIndex));
      expect(decoded.activeSheet.name, equals(original.activeSheet.name));
      expect(decoded.activeSheet.populatedCells, isEmpty);
    });

    test('preserves sparse cells and omits unpopulated cells', () {
      final wb = Workbook.createDefault();
      final sheet = wb.activeSheet;

      // Populate only 2 cells in a large 1000x26 grid
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Header A1'));
      sheet.setCell(
        Cell.fromInput(const CellCoordinate(99, 25), 'Deep Cell Z100'),
      );

      final encoded = serializer.encode(wb);
      final decoded = serializer.decode(encoded);
      final decSheet = decoded.activeSheet;

      expect(decSheet.populatedCells.length, equals(2));
      expect(
        decSheet.getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Header A1'),
      );
      expect(
        decSheet.getCell(const CellCoordinate(99, 25))?.rawInput,
        equals('Deep Cell Z100'),
      );
      expect(decSheet.getCell(const CellCoordinate(1, 1)), isNull);
    });

    test('preserves formulas and computed values across number, text, bool, datetime, error', () {
      final wb = Workbook.createDefault();
      final sheet = wb.activeSheet;

      sheet.setCell(
        const Cell(
          coordinate: CellCoordinate(0, 0),
          rawInput: '=SUM(1, 2, 3)',
          computedValue: NumberCellValue(6),
        ),
      );

      sheet.setCell(
        const Cell(
          coordinate: CellCoordinate(1, 0),
          rawInput: '=CONCAT("Hello", " World")',
          computedValue: TextCellValue('Hello World'),
        ),
      );

      sheet.setCell(
        const Cell(
          coordinate: CellCoordinate(2, 0),
          rawInput: '=TRUE()',
          computedValue: BooleanCellValue(true),
        ),
      );

      sheet.setCell(
        const Cell(
          coordinate: CellCoordinate(3, 0),
          rawInput: '=1/0',
          computedValue: ErrorCellValue(CellError.divZero),
        ),
      );

      final dt = DateTime(2026, 10, 26, 12, 0);
      sheet.setCell(
        Cell(
          coordinate: const CellCoordinate(4, 0),
          rawInput: '2026-10-26T12:00:00.000',
          computedValue: DateTimeCellValue(dt),
        ),
      );

      final encoded = serializer.encode(wb);
      final decoded = serializer.decode(encoded);
      final decSheet = decoded.activeSheet;

      final c0 = decSheet.getCell(const CellCoordinate(0, 0))!;
      expect(c0.rawInput, equals('=SUM(1, 2, 3)'));
      expect(c0.isFormula, isTrue);
      expect((c0.computedValue as NumberCellValue).value, equals(6));

      final c1 = decSheet.getCell(const CellCoordinate(1, 0))!;
      expect(c1.rawInput, equals('=CONCAT("Hello", " World")'));
      expect((c1.computedValue as TextCellValue).text, equals('Hello World'));

      final c2 = decSheet.getCell(const CellCoordinate(2, 0))!;
      expect((c2.computedValue as BooleanCellValue).value, isTrue);

      final c3 = decSheet.getCell(const CellCoordinate(3, 0))!;
      expect(
        (c3.computedValue as ErrorCellValue).error,
        equals(CellError.divZero),
      );

      final c4 = decSheet.getCell(const CellCoordinate(4, 0))!;
      expect((c4.computedValue as DateTimeCellValue).dateTime, equals(dt));
    });

    test('preserves comprehensive CellStyle formatting tokens', () {
      final wb = Workbook.createDefault();
      final sheet = wb.activeSheet;

      const customStyle = CellStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0,
        isBold: true,
        isItalic: true,
        isUnderline: true,
        isStrikethrough: true,
        textColor: 0xFF123456,
        fillColor: 0xFFAABBCC,
        horizontalAlignment: CellHorizontalAlignment.center,
        verticalAlignment: CellVerticalAlignment.middle,
        isWrapped: true,
        numberFormat: CellNumberFormat(
          type: NumberFormatType.currency,
          decimalPlaces: 2,
          currencySymbol: '€',
          useThousandsSeparator: true,
        ),
        borders: CellBorders(
          top: CellBorderSide(style: CellBorderStyle.thin, color: 0xFF000000),
          bottom: CellBorderSide(
            style: CellBorderStyle.doubleBorder,
            color: 0xFFFF0000,
          ),
          left: CellBorderSide(
            style: CellBorderStyle.dashed,
            color: 0xFF00FF00,
          ),
          right: CellBorderSide(
            style: CellBorderStyle.medium,
            color: 0xFF0000FF,
          ),
        ),
      );

      sheet.setCell(
        Cell.fromInput(
          const CellCoordinate(2, 3),
          'Styled Cell',
          style: customStyle,
        ),
      );

      final encoded = serializer.encode(wb);
      final decoded = serializer.decode(encoded);
      final cell = decoded.activeSheet.getCell(const CellCoordinate(2, 3))!;
      final s = cell.style;

      expect(s.fontFamily, equals('Roboto'));
      expect(s.fontSize, equals(16.0));
      expect(s.isBold, isTrue);
      expect(s.isItalic, isTrue);
      expect(s.isUnderline, isTrue);
      expect(s.isStrikethrough, isTrue);
      expect(s.textColor, equals(0xFF123456));
      expect(s.fillColor, equals(0xFFAABBCC));
      expect(s.horizontalAlignment, equals(CellHorizontalAlignment.center));
      expect(s.verticalAlignment, equals(CellVerticalAlignment.middle));
      expect(s.isWrapped, isTrue);

      expect(s.numberFormat.type, equals(NumberFormatType.currency));
      expect(s.numberFormat.decimalPlaces, equals(2));
      expect(s.numberFormat.currencySymbol, equals('€'));
      expect(s.numberFormat.useThousandsSeparator, isTrue);

      expect(s.borders.top.style, equals(CellBorderStyle.thin));
      expect(s.borders.bottom.style, equals(CellBorderStyle.doubleBorder));
      expect(s.borders.bottom.color, equals(0xFFFF0000));
      expect(s.borders.left.style, equals(CellBorderStyle.dashed));
      expect(s.borders.right.style, equals(CellBorderStyle.medium));
    });

    test('preserves custom column widths and row heights', () {
      final wb = Workbook.createDefault();
      final sheet = wb.activeSheet;

      sheet.setColumnWidth(0, 180.0);
      sheet.setColumnWidth(4, 250.0);
      sheet.setRowHeight(1, 40.0);
      sheet.setRowHeight(5, 55.0);

      final encoded = serializer.encode(wb);
      final decoded = serializer.decode(encoded);
      final decSheet = decoded.activeSheet;

      expect(decSheet.getColumnWidth(0), equals(180.0));
      expect(decSheet.getColumnWidth(4), equals(250.0));
      expect(decSheet.getColumnWidth(1), equals(Worksheet.defaultColumnWidth));

      expect(decSheet.getRowHeight(1), equals(40.0));
      expect(decSheet.getRowHeight(5), equals(55.0));
      expect(decSheet.getRowHeight(0), equals(Worksheet.defaultRowHeight));
    });

    test('preserves multi-sheet workbooks and active sheet index', () {
      final wb = Workbook.createDefault(title: 'MultiSheet.gsheet');
      final sheet1 = wb.activeSheet;
      sheet1.name = 'Summary';

      final sheet2 = wb.createSheet(name: 'Q1 Data');
      final sheet3 = wb.createSheet(name: 'Q2 Data');

      sheet1.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Summary A1'));
      sheet2.setCell(Cell.fromInput(const CellCoordinate(1, 1), 'Q1 B2'));
      sheet3.setCell(Cell.fromInput(const CellCoordinate(2, 2), 'Q2 C3'));

      wb.activeSheetIndex = 1; // Q1 Data is active

      final encoded = serializer.encode(wb);
      final decoded = serializer.decode(encoded);

      expect(decoded.sheetCount, equals(3));
      expect(decoded.activeSheetIndex, equals(1));
      expect(decoded.sheets[0].name, equals('Summary'));
      expect(decoded.sheets[1].name, equals('Q1 Data'));
      expect(decoded.sheets[2].name, equals('Q2 Data'));

      expect(
        decoded.sheets[0].getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Summary A1'),
      );
      expect(
        decoded.sheets[1].getCell(const CellCoordinate(1, 1))?.rawInput,
        equals('Q1 B2'),
      );
      expect(
        decoded.sheets[2].getCell(const CellCoordinate(2, 2))?.rawInput,
        equals('Q2 C3'),
      );
    });
  });
}
