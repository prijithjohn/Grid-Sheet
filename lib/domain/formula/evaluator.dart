import 'dart:math' as math;

import '../cell/cell_value.dart';
import 'ast.dart';
import 'context.dart';
import 'functions.dart';

/// Pure Dart visitor that evaluates a [FormulaNode] AST against an [EvaluationContext].
class FormulaEvaluator implements FormulaVisitor<CellValue> {
  EvaluationContext? _context;

  FormulaEvaluator();

  /// Evaluates [node] within [context] and returns the resulting [CellValue].
  CellValue evaluate(FormulaNode node, EvaluationContext context) {
    final prevContext = _context;
    _context = context;
    try {
      return node.accept(this);
    } finally {
      _context = prevContext;
    }
  }

  @override
  CellValue visitNumberLiteral(NumberLiteralNode node) {
    return NumberCellValue(node.value);
  }

  @override
  CellValue visitStringLiteral(StringLiteralNode node) {
    return TextCellValue(node.value);
  }

  @override
  CellValue visitBooleanLiteral(BooleanLiteralNode node) {
    return BooleanCellValue(node.value);
  }

  @override
  CellValue visitCellReference(CellReferenceNode node) {
    if (_context == null) return const EmptyCellValue();
    return _context!.getCellValue(node.coordinate, sheetName: node.sheetName);
  }

  @override
  CellValue visitRangeReference(RangeReferenceNode node) {
    if (_context == null) return const EmptyCellValue();
    // In scalar evaluation context, a range reference returns its top-left cell value
    return _context!.getCellValue(node.range.start, sheetName: node.sheetName);
  }

  @override
  CellValue visitUnaryOp(UnaryOpNode node) {
    final operandVal = node.operand.accept(this);
    if (operandVal is ErrorCellValue) return operandVal;

    final n = coerceToNumber(operandVal);
    if (n == null) return const ErrorCellValue(CellError.value);

    switch (node.op) {
      case UnaryOp.plus:
        return NumberCellValue(n);
      case UnaryOp.minus:
        return NumberCellValue(-n);
    }
  }

  @override
  CellValue visitBinaryOp(BinaryOpNode node) {
    final leftVal = node.left.accept(this);
    if (leftVal is ErrorCellValue) return leftVal;

    final rightVal = node.right.accept(this);
    if (rightVal is ErrorCellValue) return rightVal;

    // Comparison operators
    if (_isComparisonOp(node.op)) {
      return _evaluateComparison(node.op, leftVal, rightVal);
    }

    // Arithmetic operators
    final leftNum = coerceToNumber(leftVal);
    final rightNum = coerceToNumber(rightVal);

    if (leftNum == null || rightNum == null) {
      return const ErrorCellValue(CellError.value);
    }

    switch (node.op) {
      case BinaryOp.add:
        return NumberCellValue(leftNum + rightNum);
      case BinaryOp.subtract:
        return NumberCellValue(leftNum - rightNum);
      case BinaryOp.multiply:
        return NumberCellValue(leftNum * rightNum);
      case BinaryOp.divide:
        if (rightNum == 0) {
          return const ErrorCellValue(CellError.divZero);
        }
        return NumberCellValue(leftNum / rightNum);
      case BinaryOp.power:
        final res = math.pow(leftNum, rightNum);
        if (res.isNaN || res.isInfinite) {
          return const ErrorCellValue(CellError.num);
        }
        return NumberCellValue(res);
      default:
        return const ErrorCellValue(CellError.value);
    }
  }

  @override
  CellValue visitFunctionCall(FunctionCallNode node) {
    final handler = FunctionRegistry.getHandler(node.functionName);
    if (handler == null) {
      return const ErrorCellValue(CellError.name);
    }
    if (_context == null) return const EmptyCellValue();
    return handler(node.arguments, this, _context!);
  }

  @override
  CellValue visitError(ErrorNode node) {
    return ErrorCellValue(node.error);
  }

  // ---------------------------------------------------------------------------
  // Type Coercion Helpers
  // ---------------------------------------------------------------------------

  /// Coerces a [CellValue] to numeric [num] per standard spreadsheet rules.
  num? coerceToNumber(CellValue val) {
    if (val is NumberCellValue) return val.value;
    if (val is EmptyCellValue) return 0;
    if (val is BooleanCellValue) return val.value ? 1 : 0;
    if (val is TextCellValue) {
      final trimmed = val.text.trim();
      if (trimmed.isEmpty) return 0;
      return num.tryParse(trimmed);
    }
    return null;
  }

  /// Coerces a [CellValue] to boolean [bool].
  bool? coerceToBoolean(CellValue val) {
    if (val is BooleanCellValue) return val.value;
    if (val is NumberCellValue) return val.value != 0;
    if (val is EmptyCellValue) return false;
    if (val is TextCellValue) {
      final upper = val.text.trim().toUpperCase();
      if (upper == 'TRUE') return true;
      if (upper == 'FALSE') return false;
      final n = num.tryParse(upper);
      if (n != null) return n != 0;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Comparison Helpers
  // ---------------------------------------------------------------------------

  bool _isComparisonOp(BinaryOp op) {
    switch (op) {
      case BinaryOp.equal:
      case BinaryOp.notEqual:
      case BinaryOp.lessThan:
      case BinaryOp.lessThanOrEqual:
      case BinaryOp.greaterThan:
      case BinaryOp.greaterThanOrEqual:
        return true;
      default:
        return false;
    }
  }

  CellValue _evaluateComparison(BinaryOp op, CellValue left, CellValue right) {
    final cmp = _compareValues(left, right);

    bool result;
    switch (op) {
      case BinaryOp.equal:
        result = cmp == 0;
        break;
      case BinaryOp.notEqual:
        result = cmp != 0;
        break;
      case BinaryOp.lessThan:
        result = cmp < 0;
        break;
      case BinaryOp.lessThanOrEqual:
        result = cmp <= 0;
        break;
      case BinaryOp.greaterThan:
        result = cmp > 0;
        break;
      case BinaryOp.greaterThanOrEqual:
        result = cmp >= 0;
        break;
      default:
        return const ErrorCellValue(CellError.value);
    }

    return BooleanCellValue(result);
  }

  int _compareValues(CellValue left, CellValue right) {
    // Treat empty cells as zero/empty string depending on peer
    var l = left;
    var r = right;

    if (l is EmptyCellValue && r is NumberCellValue) {
      l = const NumberCellValue(0);
    } else if (l is NumberCellValue && r is EmptyCellValue) {
      r = const NumberCellValue(0);
    } else if (l is EmptyCellValue && r is TextCellValue) {
      l = const TextCellValue('');
    } else if (l is TextCellValue && r is EmptyCellValue) {
      r = const TextCellValue('');
    } else if (l is EmptyCellValue && r is BooleanCellValue) {
      l = const BooleanCellValue(false);
    } else if (l is BooleanCellValue && r is EmptyCellValue) {
      r = const BooleanCellValue(false);
    }

    if (l is NumberCellValue && r is NumberCellValue) {
      return l.value.compareTo(r.value);
    }

    if (l is TextCellValue && r is TextCellValue) {
      return l.text.toUpperCase().compareTo(r.text.toUpperCase());
    }

    if (l is BooleanCellValue && r is BooleanCellValue) {
      if (l.value == r.value) return 0;
      return l.value ? 1 : -1;
    }

    // Excel type order: Number < Text < Boolean
    final typeOrder = {
      NumberCellValue: 1,
      TextCellValue: 2,
      BooleanCellValue: 3,
      EmptyCellValue: 0,
    };

    final leftOrder = typeOrder[l.runtimeType] ?? 0;
    final rightOrder = typeOrder[r.runtimeType] ?? 0;
    return leftOrder.compareTo(rightOrder);
  }
}
