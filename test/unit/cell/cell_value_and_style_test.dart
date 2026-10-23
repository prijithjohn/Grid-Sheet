import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';
import 'package:grid_sheet/domain/cell/cell_model.dart';
import 'package:grid_sheet/domain/cell/cell_style.dart';
import 'package:grid_sheet/domain/cell/cell_value.dart';

void main() {
  group('CellValue - Types and Display Strings', () {
    test('EmptyCellValue represents empty state', () {
      const empty = EmptyCellValue();
      expect(empty.isEmpty, true);
      expect(empty.displayString, '');
    });

    test('TextCellValue stores and displays text', () {
      const text = TextCellValue('Annual Budget');
      expect(text.isEmpty, false);
      expect(text.text, 'Annual Budget');
      expect(text.displayString, 'Annual Budget');
    });

    test(
      'NumberCellValue stores numeric values with integer formatting check',
      () {
        const intNum = NumberCellValue(42);
        expect(intNum.displayString, '42');

        const doubleNum = NumberCellValue(1234.56);
        expect(doubleNum.displayString, '1234.56');

        const floatEndingInZero = NumberCellValue(100.0);
        expect(floatEndingInZero.displayString, '100');
      },
    );

    test('BooleanCellValue displays TRUE / FALSE', () {
      const bTrue = BooleanCellValue(true);
      expect(bTrue.displayString, 'TRUE');

      const bFalse = BooleanCellValue(false);
      expect(bFalse.displayString, 'FALSE');
    });

    test('DateTimeCellValue displays formatted date', () {
      final dt = DateTimeCellValue(DateTime(2026, 10, 23));
      expect(dt.displayString, '2026-10-23');
    });

    test('ErrorCellValue represents all standard spreadsheet errors', () {
      for (final error in CellError.values) {
        final errVal = ErrorCellValue(error);
        expect(errVal.displayString, error.code);
        expect(error.code.startsWith('#'), isTrue);
      }
    });
  });

  group('Cell - Construction, Formulas and Input Parsing', () {
    test('creates empty cell', () {
      final cell = Cell.empty(const CellCoordinate(0, 0));
      expect(cell.isEmpty, isTrue);
      expect(cell.isFormula, isFalse);
      expect(cell.rawInput, '');
      expect(cell.computedValue, const EmptyCellValue());
    });

    test('fromInput automatically parses numbers and booleans', () {
      final numCell = Cell.fromInput(const CellCoordinate(0, 0), '1250');
      expect(numCell.computedValue, const NumberCellValue(1250));
      expect(numCell.isFormula, isFalse);

      final floatCell = Cell.fromInput(const CellCoordinate(0, 0), '99.95');
      expect(floatCell.computedValue, const NumberCellValue(99.95));

      final boolCell = Cell.fromInput(const CellCoordinate(0, 0), 'TRUE');
      expect(boolCell.computedValue, const BooleanCellValue(true));

      final textCell = Cell.fromInput(
        const CellCoordinate(0, 0),
        'Project Apollo',
      );
      expect(textCell.computedValue, const TextCellValue('Project Apollo'));
    });

    test('fromInput recognizes formula prefix (=)', () {
      final formulaCell = Cell.fromInput(
        const CellCoordinate(0, 0),
        '=SUM(A1:A10)',
      );
      expect(formulaCell.isFormula, isTrue);
      expect(formulaCell.formula, 'SUM(A1:A10)');
      // Initially empty until calculation engine evaluates it
      expect(formulaCell.computedValue, const EmptyCellValue());
    });

    test('formats numbers with thousand separators and currency symbol', () {
      const currencyStyle = CellStyle(
        numberFormat: CellNumberFormat(
          type: NumberFormatType.currency,
          decimalPlaces: 2,
          currencySymbol: '\$',
          useThousandsSeparator: true,
        ),
      );

      const cell = Cell(
        coordinate: CellCoordinate(0, 0),
        rawInput: '1420.5',
        computedValue: NumberCellValue(1420.5),
        style: currencyStyle,
      );

      expect(cell.formattedText, '\$1,420.50');
    });

    test('formats percentages correctly', () {
      const percentStyle = CellStyle(
        numberFormat: CellNumberFormat(
          type: NumberFormatType.percentage,
          decimalPlaces: 1,
        ),
      );

      const cell = Cell(
        coordinate: CellCoordinate(0, 0),
        rawInput: '0.125',
        computedValue: NumberCellValue(0.125),
        style: percentStyle,
      );

      expect(cell.formattedText, '12.5%');
    });
  });

  group('CellStyle - Immutability & CopyWith', () {
    test('defaultStyle has expected spreadsheet defaults', () {
      const style = CellStyle.defaultStyle;
      expect(style.fontSize, 11.0);
      expect(style.isBold, isFalse);
      expect(style.isItalic, isFalse);
      expect(style.fillColor, isNull);
      expect(style.textColor, 0xFF202124);
      expect(style.horizontalAlignment, CellHorizontalAlignment.general);
      expect(style.verticalAlignment, CellVerticalAlignment.bottom);
    });

    test('copyWith updates properties without mutating original', () {
      const original = CellStyle.defaultStyle;
      final boldAndFilled = original.copyWith(
        isBold: true,
        fillColor: 0xFFFFF2CC,
      );

      expect(original.isBold, isFalse);
      expect(original.fillColor, isNull);

      expect(boldAndFilled.isBold, isTrue);
      expect(boldAndFilled.fillColor, 0xFFFFF2CC);
      expect(boldAndFilled.fontSize, 11.0); // Preserved
    });
  });
}
