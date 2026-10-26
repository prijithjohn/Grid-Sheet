import '../cell/cell_coordinate.dart';
import '../cell/cell_range.dart';
import '../cell/cell_value.dart';

/// Supported unary operators in formulas.
enum UnaryOp {
  plus('+'),
  minus('-');

  final String symbol;
  const UnaryOp(this.symbol);

  @override
  String toString() => symbol;
}

/// Supported binary operators in formulas.
enum BinaryOp {
  add('+'),
  subtract('-'),
  multiply('*'),
  divide('/'),
  power('^'),
  equal('='),
  notEqual('<>'),
  lessThan('<'),
  lessThanOrEqual('<='),
  greaterThan('>'),
  greaterThanOrEqual('>=');

  final String symbol;
  const BinaryOp(this.symbol);

  @override
  String toString() => symbol;
}

/// Abstract base class for all nodes in the formula Abstract Syntax Tree (AST).
abstract class FormulaNode {
  const FormulaNode();

  /// Accepts a visitor implementation.
  T accept<T>(FormulaVisitor<T> visitor);

  /// Recursively collects all precedent cell coordinates and ranges referenced by this expression.
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  });
}

/// Visitor interface for AST node traversals.
abstract class FormulaVisitor<T> {
  T visitNumberLiteral(NumberLiteralNode node);
  T visitStringLiteral(StringLiteralNode node);
  T visitBooleanLiteral(BooleanLiteralNode node);
  T visitCellReference(CellReferenceNode node);
  T visitRangeReference(RangeReferenceNode node);
  T visitUnaryOp(UnaryOpNode node);
  T visitBinaryOp(BinaryOpNode node);
  T visitFunctionCall(FunctionCallNode node);
  T visitError(ErrorNode node);
}

/// A numeric literal node (e.g. `42`, `3.1415`).
class NumberLiteralNode extends FormulaNode {
  final num value;

  const NumberLiteralNode(this.value);

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitNumberLiteral(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {}

  @override
  String toString() => '$value';
}

/// A string literal node (e.g. `"Total"`, `"N/A"`).
class StringLiteralNode extends FormulaNode {
  final String value;

  const StringLiteralNode(this.value);

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitStringLiteral(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {}

  @override
  String toString() => '"$value"';
}

/// A boolean literal node (`TRUE` or `FALSE`).
class BooleanLiteralNode extends FormulaNode {
  final bool value;

  const BooleanLiteralNode(this.value);

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitBooleanLiteral(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {}

  @override
  String toString() => value ? 'TRUE' : 'FALSE';
}

/// A single cell coordinate reference node (e.g. `A1`, `$B$5`, `Sheet1!C3`).
class CellReferenceNode extends FormulaNode {
  final String? sheetName;
  final CellCoordinate coordinate;
  final bool isColAbsolute;
  final bool isRowAbsolute;
  final String rawText;

  const CellReferenceNode({
    this.sheetName,
    required this.coordinate,
    this.isColAbsolute = false,
    this.isRowAbsolute = false,
    required this.rawText,
  });

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitCellReference(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {
    coordinates.add(coordinate);
  }

  @override
  String toString() => rawText;
}

/// A rectangular range reference node (e.g. `A1:B10`, `Sheet1!$A$1:$C$20`).
class RangeReferenceNode extends FormulaNode {
  final String? sheetName;
  final CellRange range;
  final String rawText;

  const RangeReferenceNode({
    this.sheetName,
    required this.range,
    required this.rawText,
  });

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitRangeReference(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {
    ranges.add(range);
    // Also include all coordinates spanned by the range for dependency tracking
    for (var r = range.topRow; r <= range.bottomRow; r++) {
      for (var c = range.leftCol; c <= range.rightCol; c++) {
        coordinates.add(CellCoordinate(r, c));
      }
    }
  }

  @override
  String toString() => rawText;
}

/// Unary prefix operator node (e.g. `-A1`, `+5`).
class UnaryOpNode extends FormulaNode {
  final UnaryOp op;
  final FormulaNode operand;

  const UnaryOpNode({required this.op, required this.operand});

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitUnaryOp(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {
    operand.collectReferences(coordinates: coordinates, ranges: ranges);
  }

  @override
  String toString() => '${op.symbol}($operand)';
}

/// Binary operator node (e.g. `A1 + B1`, `X > 10`).
class BinaryOpNode extends FormulaNode {
  final BinaryOp op;
  final FormulaNode left;
  final FormulaNode right;

  const BinaryOpNode({
    required this.op,
    required this.left,
    required this.right,
  });

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitBinaryOp(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {
    left.collectReferences(coordinates: coordinates, ranges: ranges);
    right.collectReferences(coordinates: coordinates, ranges: ranges);
  }

  @override
  String toString() => '($left ${op.symbol} $right)';
}

/// Function call node (e.g. `SUM(A1:A10)`, `IF(A1 > 0, "Positive", "Negative")`).
class FunctionCallNode extends FormulaNode {
  final String functionName;
  final List<FormulaNode> arguments;

  const FunctionCallNode({required this.functionName, required this.arguments});

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitFunctionCall(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {
    for (final arg in arguments) {
      arg.collectReferences(coordinates: coordinates, ranges: ranges);
    }
  }

  @override
  String toString() => '$functionName(${arguments.join(', ')})';
}

/// A syntax or reference error captured during parsing (e.g. `#REF!`, `#NAME?`).
class ErrorNode extends FormulaNode {
  final CellError error;
  final String? message;

  const ErrorNode(this.error, [this.message]);

  @override
  T accept<T>(FormulaVisitor<T> visitor) => visitor.visitError(this);

  @override
  void collectReferences({
    required List<CellCoordinate> coordinates,
    required List<CellRange> ranges,
  }) {}

  @override
  String toString() => error.code;
}
