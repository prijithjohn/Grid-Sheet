import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/formula/evaluator.dart';
import 'package:grid_sheet/domain/formula/parser.dart';
import 'package:grid_sheet/domain/formula/context.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';
import 'package:grid_sheet/domain/cell/cell_model.dart';
import 'package:grid_sheet/domain/cell/cell_value.dart';
import 'package:grid_sheet/domain/worksheet/worksheet_model.dart';

void main() {
  group('FormulaEvaluator', () {
    late FormulaEvaluator evaluator;
    late Worksheet sheet;
    late WorksheetEvaluationContext ctx;

    setUp(() {
      evaluator = FormulaEvaluator();
      sheet = Worksheet(id: 'ws1', name: 'Sheet1');
      ctx = WorksheetEvaluationContext(activeWorksheet: sheet);
    });

    CellValue eval(String formula) {
      final node = FormulaParser.fromString(formula).parse();
      return evaluator.evaluate(node, ctx);
    }

    void setCell(String a1, CellValue value) {
      final coord = CellCoordinate.fromA1(a1);
      final cell = Cell(
        coordinate: coord,
        rawInput: value.displayString,
        computedValue: value,
      );
      sheet.setCell(cell);
    }

    // -------------------------------------------------------------------------
    // Literals
    // -------------------------------------------------------------------------
    group('literal evaluation', () {
      test('number literal', () {
        expect(eval('=42'), const NumberCellValue(42));
      });

      test('decimal number literal', () {
        expect(eval('=3.14'), const NumberCellValue(3.14));
      });

      test('string literal', () {
        expect(eval('="hello"'), const TextCellValue('hello'));
      });

      test('TRUE literal', () {
        expect(eval('=TRUE'), const BooleanCellValue(true));
      });

      test('FALSE literal', () {
        expect(eval('=FALSE'), const BooleanCellValue(false));
      });
    });

    // -------------------------------------------------------------------------
    // Arithmetic
    // -------------------------------------------------------------------------
    group('arithmetic operations', () {
      test('addition', () {
        expect(eval('=1+2'), const NumberCellValue(3));
      });

      test('subtraction', () {
        expect(eval('=10-3'), const NumberCellValue(7));
      });

      test('multiplication', () {
        expect(eval('=4*5'), const NumberCellValue(20));
      });

      test('division', () {
        expect(eval('=10/4'), const NumberCellValue(2.5));
      });

      test('division by zero returns #DIV/0!', () {
        expect(eval('=1/0'), const ErrorCellValue(CellError.divZero));
      });

      test('power: 2^10', () {
        expect(eval('=2^10'), const NumberCellValue(1024));
      });

      test('unary minus', () {
        expect(eval('=-5'), const NumberCellValue(-5));
      });

      test('unary minus on cell reference', () {
        setCell('A1', const NumberCellValue(10));
        expect(eval('=-A1'), const NumberCellValue(-10));
      });

      test('operator precedence: 2+3*4=14', () {
        expect(eval('=2+3*4'), const NumberCellValue(14));
      });

      test('parentheses override precedence: (2+3)*4=20', () {
        expect(eval('=(2+3)*4'), const NumberCellValue(20));
      });

      test('complex nested arithmetic', () {
        expect(eval('=(10-2)*(3+1)/2^2'), const NumberCellValue(8));
      });
    });

    // -------------------------------------------------------------------------
    // Comparison operators
    // -------------------------------------------------------------------------
    group('comparison operators', () {
      test('equal: 1=1 is TRUE', () {
        expect(eval('=1=1'), const BooleanCellValue(true));
      });

      test('equal: 1=2 is FALSE', () {
        expect(eval('=1=2'), const BooleanCellValue(false));
      });

      test('not equal: 1<>2 is TRUE', () {
        expect(eval('=1<>2'), const BooleanCellValue(true));
      });

      test('less than: 1<2 is TRUE', () {
        expect(eval('=1<2'), const BooleanCellValue(true));
      });

      test('less than or equal: 2<=2 is TRUE', () {
        expect(eval('=2<=2'), const BooleanCellValue(true));
      });

      test('greater than: 3>2 is TRUE', () {
        expect(eval('=3>2'), const BooleanCellValue(true));
      });

      test('greater than or equal: 3>=4 is FALSE', () {
        expect(eval('=3>=4'), const BooleanCellValue(false));
      });

      test('text comparison (case-insensitive): "abc"="ABC" is TRUE', () {
        expect(eval('="abc"="ABC"'), const BooleanCellValue(true));
      });
    });

    // -------------------------------------------------------------------------
    // Cell references
    // -------------------------------------------------------------------------
    group('cell references', () {
      test('empty cell returns EmptyCellValue', () {
        expect(eval('=Z99'), const EmptyCellValue());
      });

      test('reads numeric cell value', () {
        setCell('A1', const NumberCellValue(7));
        expect(eval('=A1'), const NumberCellValue(7));
      });

      test('reads text cell value', () {
        setCell('B2', const TextCellValue('world'));
        expect(eval('=B2'), const TextCellValue('world'));
      });

      test('arithmetic on cell value', () {
        setCell('A1', const NumberCellValue(5));
        setCell('B1', const NumberCellValue(3));
        expect(eval('=A1+B1'), const NumberCellValue(8));
      });

      test('empty cell coerces to 0 in arithmetic', () {
        // Z99 is empty, should be treated as 0
        expect(eval('=Z99+10'), const NumberCellValue(10));
      });
    });

    // -------------------------------------------------------------------------
    // Type coercion
    // -------------------------------------------------------------------------
    group('type coercion', () {
      test('TRUE coerces to 1 in arithmetic', () {
        expect(eval('=TRUE+1'), const NumberCellValue(2));
      });

      test('FALSE coerces to 0 in arithmetic', () {
        expect(eval('=FALSE+5'), const NumberCellValue(5));
      });

      test('numeric string cell coerces to number in arithmetic', () {
        setCell('A1', const TextCellValue('10'));
        expect(eval('=A1*2'), const NumberCellValue(20));
      });

      test('non-numeric string returns #VALUE! in arithmetic', () {
        setCell('A1', const TextCellValue('hello'));
        expect(eval('=A1+1'), const ErrorCellValue(CellError.value));
      });
    });

    // -------------------------------------------------------------------------
    // Error propagation
    // -------------------------------------------------------------------------
    group('error propagation', () {
      test('error in left operand propagates', () {
        setCell('A1', const ErrorCellValue(CellError.ref));
        expect(eval('=A1+1'), const ErrorCellValue(CellError.ref));
      });

      test('error in right operand propagates', () {
        setCell('B1', const ErrorCellValue(CellError.value));
        expect(eval('=1+B1'), const ErrorCellValue(CellError.value));
      });

      test('unknown function returns #NAME?', () {
        expect(eval('=NONEXISTENT()'), const ErrorCellValue(CellError.name));
      });
    });

    // -------------------------------------------------------------------------
    // Built-in functions
    // -------------------------------------------------------------------------
    group('SUM function', () {
      test('SUM of range', () {
        setCell('A1', const NumberCellValue(1));
        setCell('A2', const NumberCellValue(2));
        setCell('A3', const NumberCellValue(3));
        expect(eval('=SUM(A1:A3)'), const NumberCellValue(6));
      });

      test('SUM of empty range returns 0', () {
        expect(eval('=SUM(Z1:Z5)'), const NumberCellValue(0));
      });

      test('SUM with multiple literal args', () {
        expect(eval('=SUM(1,2,3,4)'), const NumberCellValue(10));
      });

      test('SUM ignores text values in range', () {
        setCell('A1', const NumberCellValue(5));
        setCell('A2', const TextCellValue('hello'));
        setCell('A3', const NumberCellValue(3));
        expect(eval('=SUM(A1:A3)'), const NumberCellValue(8));
      });
    });

    group('AVERAGE function', () {
      test('AVERAGE of numeric range', () {
        setCell('A1', const NumberCellValue(2));
        setCell('A2', const NumberCellValue(4));
        setCell('A3', const NumberCellValue(6));
        expect(eval('=AVERAGE(A1:A3)'), const NumberCellValue(4));
      });

      test('AVERAGE of empty range returns #DIV/0!', () {
        expect(
          eval('=AVERAGE(Z1:Z5)'),
          const ErrorCellValue(CellError.divZero),
        );
      });
    });

    group('MIN and MAX functions', () {
      test('MIN', () {
        setCell('A1', const NumberCellValue(5));
        setCell('A2', const NumberCellValue(2));
        setCell('A3', const NumberCellValue(8));
        expect(eval('=MIN(A1:A3)'), const NumberCellValue(2));
      });

      test('MAX', () {
        setCell('A1', const NumberCellValue(5));
        setCell('A2', const NumberCellValue(2));
        setCell('A3', const NumberCellValue(8));
        expect(eval('=MAX(A1:A3)'), const NumberCellValue(8));
      });
    });

    group('COUNT and COUNTA functions', () {
      test('COUNT counts numeric values only', () {
        setCell('A1', const NumberCellValue(1));
        setCell('A2', const TextCellValue('text'));
        setCell('A3', const NumberCellValue(3));
        expect(eval('=COUNT(A1:A3)'), const NumberCellValue(2));
      });

      test('COUNTA counts non-empty values', () {
        setCell('A1', const NumberCellValue(1));
        setCell('A2', const TextCellValue('text'));
        setCell('A3', const EmptyCellValue());
        expect(eval('=COUNTA(A1:A3)'), const NumberCellValue(2));
      });
    });

    group('IF function', () {
      test('IF true branch', () {
        expect(eval('=IF(1=1,"yes","no")'), const TextCellValue('yes'));
      });

      test('IF false branch', () {
        expect(eval('=IF(1=2,"yes","no")'), const TextCellValue('no'));
      });

      test('IF with numeric result', () {
        setCell('A1', const NumberCellValue(10));
        expect(eval('=IF(A1>5, A1*2, 0)'), const NumberCellValue(20));
      });

      test('IF with missing false argument returns FALSE', () {
        expect(eval('=IF(FALSE,"yes")'), const BooleanCellValue(false));
      });
    });

    group('ABS function', () {
      test('ABS of negative number', () {
        expect(eval('=ABS(-10)'), const NumberCellValue(10));
      });

      test('ABS of positive number', () {
        expect(eval('=ABS(5)'), const NumberCellValue(5));
      });
    });

    group('ROUND function', () {
      test('rounds to 2 decimal places', () {
        expect(eval('=ROUND(3.14159, 2)'), const NumberCellValue(3.14));
      });

      test('rounds to 0 decimal places', () {
        expect(eval('=ROUND(2.5, 0)'), const NumberCellValue(3));
      });

      test('rounds negative number', () {
        expect(eval('=ROUND(-2.567, 2)'), const NumberCellValue(-2.57));
      });
    });

    group('AND/OR/NOT functions', () {
      test('AND with all true', () {
        expect(eval('=AND(TRUE, TRUE, TRUE)'), const BooleanCellValue(true));
      });

      test('AND with one false', () {
        expect(eval('=AND(TRUE, FALSE, TRUE)'), const BooleanCellValue(false));
      });

      test('OR with one true', () {
        expect(eval('=OR(FALSE, TRUE, FALSE)'), const BooleanCellValue(true));
      });

      test('OR with all false', () {
        expect(eval('=OR(FALSE, FALSE)'), const BooleanCellValue(false));
      });

      test('NOT true returns false', () {
        expect(eval('=NOT(TRUE)'), const BooleanCellValue(false));
      });

      test('NOT false returns true', () {
        expect(eval('=NOT(FALSE)'), const BooleanCellValue(true));
      });
    });
  });
}
