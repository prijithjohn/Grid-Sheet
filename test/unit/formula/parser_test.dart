import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/formula/ast.dart';
import 'package:grid_sheet/domain/formula/parser.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';
import 'package:grid_sheet/domain/cell/cell_range.dart';

void main() {
  group('FormulaParser', () {
    FormulaNode parse(String input) => FormulaParser.fromString(input).parse();

    // -------------------------------------------------------------------------
    // Literals
    // -------------------------------------------------------------------------
    group('literal expressions', () {
      test('parses integer literal', () {
        final node = parse('=42');
        expect(node, isA<NumberLiteralNode>());
        expect((node as NumberLiteralNode).value, 42);
      });

      test('parses decimal literal', () {
        final node = parse('=3.14');
        expect(node, isA<NumberLiteralNode>());
        expect((node as NumberLiteralNode).value, 3.14);
      });

      test('parses string literal', () {
        final node = parse('="hello"');
        expect(node, isA<StringLiteralNode>());
        expect((node as StringLiteralNode).value, 'hello');
      });

      test('parses TRUE boolean literal', () {
        final node = parse('=TRUE');
        expect(node, isA<BooleanLiteralNode>());
        expect((node as BooleanLiteralNode).value, true);
      });

      test('parses FALSE boolean literal', () {
        final node = parse('=FALSE');
        expect(node, isA<BooleanLiteralNode>());
        expect((node as BooleanLiteralNode).value, false);
      });
    });

    // -------------------------------------------------------------------------
    // Unary operators
    // -------------------------------------------------------------------------
    group('unary operators', () {
      test('unary minus', () {
        final node = parse('=-5');
        expect(node, isA<UnaryOpNode>());
        final unary = node as UnaryOpNode;
        expect(unary.op, UnaryOp.minus);
        expect(unary.operand, isA<NumberLiteralNode>());
      });

      test('unary plus', () {
        final node = parse('=+10');
        expect(node, isA<UnaryOpNode>());
        final unary = node as UnaryOpNode;
        expect(unary.op, UnaryOp.plus);
      });

      test('double unary minus', () {
        final node = parse('=--5');
        expect(node, isA<UnaryOpNode>());
        final outer = node as UnaryOpNode;
        expect(outer.op, UnaryOp.minus);
        expect(outer.operand, isA<UnaryOpNode>());
      });
    });

    // -------------------------------------------------------------------------
    // Arithmetic binary operators and precedence
    // -------------------------------------------------------------------------
    group('arithmetic and precedence', () {
      test('addition', () {
        final node = parse('=1+2');
        expect(node, isA<BinaryOpNode>());
        final bin = node as BinaryOpNode;
        expect(bin.op, BinaryOp.add);
      });

      test('subtraction', () {
        final node = parse('=5-3');
        expect(node, isA<BinaryOpNode>());
        expect((node as BinaryOpNode).op, BinaryOp.subtract);
      });

      test('multiplication has higher precedence than addition', () {
        // 1+2*3 should parse as 1+(2*3)
        final node = parse('=1+2*3');
        expect(node, isA<BinaryOpNode>());
        final outer = node as BinaryOpNode;
        expect(outer.op, BinaryOp.add);
        expect(outer.left, isA<NumberLiteralNode>());
        expect(outer.right, isA<BinaryOpNode>());
        final inner = outer.right as BinaryOpNode;
        expect(inner.op, BinaryOp.multiply);
      });

      test('parentheses override precedence', () {
        // (1+2)*3 should parse as (1+2)*3
        final node = parse('=(1+2)*3');
        expect(node, isA<BinaryOpNode>());
        final outer = node as BinaryOpNode;
        expect(outer.op, BinaryOp.multiply);
        expect(outer.left, isA<BinaryOpNode>());
        final inner = outer.left as BinaryOpNode;
        expect(inner.op, BinaryOp.add);
      });

      test('power operator', () {
        final node = parse('=2^10');
        expect(node, isA<BinaryOpNode>());
        expect((node as BinaryOpNode).op, BinaryOp.power);
      });

      test('power is right-associative: 2^3^2 = 2^(3^2)', () {
        final node = parse('=2^3^2');
        expect(node, isA<BinaryOpNode>());
        final outer = node as BinaryOpNode;
        expect(outer.op, BinaryOp.power);
        expect(outer.right, isA<BinaryOpNode>());
        final inner = outer.right as BinaryOpNode;
        expect(inner.op, BinaryOp.power);
      });

      test('division', () {
        final node = parse('=10/2');
        expect((node as BinaryOpNode).op, BinaryOp.divide);
      });
    });

    // -------------------------------------------------------------------------
    // Comparison operators
    // -------------------------------------------------------------------------
    group('comparison operators', () {
      test('equal', () {
        final node = parse('=A1=B1');
        expect((node as BinaryOpNode).op, BinaryOp.equal);
      });

      test('not equal <>', () {
        final node = parse('=A1<>B1');
        expect((node as BinaryOpNode).op, BinaryOp.notEqual);
      });

      test('less than', () {
        final node = parse('=A1<10');
        expect((node as BinaryOpNode).op, BinaryOp.lessThan);
      });

      test('less than or equal', () {
        final node = parse('=A1<=10');
        expect((node as BinaryOpNode).op, BinaryOp.lessThanOrEqual);
      });

      test('greater than', () {
        final node = parse('=A1>10');
        expect((node as BinaryOpNode).op, BinaryOp.greaterThan);
      });

      test('greater than or equal', () {
        final node = parse('=A1>=10');
        expect((node as BinaryOpNode).op, BinaryOp.greaterThanOrEqual);
      });
    });

    // -------------------------------------------------------------------------
    // Cell references
    // -------------------------------------------------------------------------
    group('cell references', () {
      test('parses simple cell reference A1', () {
        final node = parse('=A1');
        expect(node, isA<CellReferenceNode>());
        final ref = node as CellReferenceNode;
        expect(ref.coordinate, const CellCoordinate(0, 0));
        expect(ref.sheetName, isNull);
      });

      test('parses absolute cell reference \$B\$2', () {
        final node = parse('=\$B\$2');
        expect(node, isA<CellReferenceNode>());
        final ref = node as CellReferenceNode;
        expect(ref.coordinate.row, 1);
        expect(ref.coordinate.col, 1);
        expect(ref.isColAbsolute, true);
        expect(ref.isRowAbsolute, true);
      });

      test('parses range reference A1:B2', () {
        final node = parse('=A1:B2');
        expect(node, isA<RangeReferenceNode>());
        final range = node as RangeReferenceNode;
        expect(range.range.topRow, 0);
        expect(range.range.leftCol, 0);
        expect(range.range.bottomRow, 1);
        expect(range.range.rightCol, 1);
      });

      test('parses cross-sheet reference Sheet2!C3', () {
        final node = parse('=Sheet2!C3');
        expect(node, isA<CellReferenceNode>());
        final ref = node as CellReferenceNode;
        expect(ref.sheetName, 'Sheet2');
        expect(ref.coordinate.row, 2);
        expect(ref.coordinate.col, 2);
      });
    });

    // -------------------------------------------------------------------------
    // Function calls
    // -------------------------------------------------------------------------
    group('function calls', () {
      test('no-arg function call', () {
        final node = parse('=NOW()');
        expect(node, isA<FunctionCallNode>());
        final fn = node as FunctionCallNode;
        expect(fn.functionName, 'NOW');
        expect(fn.arguments, isEmpty);
      });

      test('single-arg function call', () {
        final node = parse('=ABS(-5)');
        expect(node, isA<FunctionCallNode>());
        final fn = node as FunctionCallNode;
        expect(fn.functionName, 'ABS');
        expect(fn.arguments.length, 1);
        expect(fn.arguments.first, isA<UnaryOpNode>());
      });

      test('multi-arg function call', () {
        final node = parse('=IF(A1>0, 1, -1)');
        expect(node, isA<FunctionCallNode>());
        final fn = node as FunctionCallNode;
        expect(fn.functionName, 'IF');
        expect(fn.arguments.length, 3);
      });

      test('range argument function call', () {
        final node = parse('=SUM(A1:A10)');
        expect(node, isA<FunctionCallNode>());
        final fn = node as FunctionCallNode;
        expect(fn.functionName, 'SUM');
        expect(fn.arguments.length, 1);
        expect(fn.arguments.first, isA<RangeReferenceNode>());
      });

      test('nested function calls', () {
        final node = parse('=SUM(ABS(A1), ABS(B1))');
        expect(node, isA<FunctionCallNode>());
        final outer = node as FunctionCallNode;
        expect(outer.functionName, 'SUM');
        expect(outer.arguments.length, 2);
        expect(outer.arguments.first, isA<FunctionCallNode>());
      });
    });

    // -------------------------------------------------------------------------
    // Reference collection
    // -------------------------------------------------------------------------
    group('collectReferences', () {
      test('BinaryOpNode collects refs from both sides', () {
        final node = parse('=A1+B2');
        final coords = <CellCoordinate>[];
        final ranges = <CellRange>[];
        node.collectReferences(coordinates: coords, ranges: ranges);
        expect(coords, contains(const CellCoordinate(0, 0))); // A1
        expect(coords, contains(const CellCoordinate(1, 1))); // B2
      });

      test('RangeReferenceNode collects expanded coordinates', () {
        final node = parse('=A1:B2');
        final coords = <CellCoordinate>[];
        final ranges = <CellRange>[];
        node.collectReferences(coordinates: coords, ranges: ranges);
        // Should contain A1, A2, B1, B2
        expect(coords.length, 4);
      });

      test('literal nodes collect no references', () {
        final node = parse('=42');
        final coords = <CellCoordinate>[];
        final ranges = <CellRange>[];
        node.collectReferences(coordinates: coords, ranges: ranges);
        expect(coords, isEmpty);
        expect(ranges, isEmpty);
      });
    });
  });
}
