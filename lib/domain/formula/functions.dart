import '../cell/cell_value.dart';
import 'ast.dart';
import 'context.dart';
import 'evaluator.dart';

/// Function signature for evaluating spreadsheet formula functions.
typedef FormulaFunctionHandler = CellValue Function(
  List<FormulaNode> args,
  FormulaEvaluator evaluator,
  EvaluationContext context,
);

/// Registry of built-in spreadsheet functions.
class FunctionRegistry {
  static final Map<String, FormulaFunctionHandler> _functions = {
    'SUM': _fnSum,
    'AVERAGE': _fnAverage,
    'MIN': _fnMin,
    'MAX': _fnMax,
    'COUNT': _fnCount,
    'COUNTA': _fnCountA,
    'IF': _fnIf,
    'ABS': _fnAbs,
    'ROUND': _fnRound,
    'NOT': _fnNot,
    'AND': _fnAnd,
    'OR': _fnOr,
  };

  /// Returns true if [functionName] is registered.
  static bool hasFunction(String functionName) =>
      _functions.containsKey(functionName.toUpperCase());

  /// Retrieves the evaluation handler for [functionName], or null if unregistered.
  static FormulaFunctionHandler? getHandler(String functionName) =>
      _functions[functionName.toUpperCase()];

  /// Registers or overrides a function handler.
  static void register(String name, FormulaFunctionHandler handler) {
    _functions[name.toUpperCase()] = handler;
  }

  // ---------------------------------------------------------------------------
  // Built-in Function Implementations
  // ---------------------------------------------------------------------------

  static CellValue _fnSum(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    num sum = 0;

    for (final arg in args) {
      if (arg is RangeReferenceNode) {
        for (final val in context.getRangeValues(
          arg.range,
          sheetName: arg.sheetName,
        )) {
          if (val is ErrorCellValue) return val;
          if (val is NumberCellValue) {
            sum += val.value;
          }
        }
      } else if (arg is CellReferenceNode) {
        final val = context.getCellValue(
          arg.coordinate,
          sheetName: arg.sheetName,
        );
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          sum += val.value;
        }
      } else {
        final val = evaluator.evaluate(arg, context);
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          sum += val.value;
        } else if (val is TextCellValue) {
          final parsed = num.tryParse(val.text.trim());
          if (parsed != null) {
            sum += parsed;
          } else {
            return const ErrorCellValue(CellError.value);
          }
        } else if (val is BooleanCellValue) {
          sum += val.value ? 1 : 0;
        }
      }
    }

    return NumberCellValue(sum);
  }

  static CellValue _fnAverage(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    num sum = 0;
    int count = 0;

    for (final arg in args) {
      if (arg is RangeReferenceNode) {
        for (final val in context.getRangeValues(
          arg.range,
          sheetName: arg.sheetName,
        )) {
          if (val is ErrorCellValue) return val;
          if (val is NumberCellValue) {
            sum += val.value;
            count++;
          }
        }
      } else if (arg is CellReferenceNode) {
        final val = context.getCellValue(
          arg.coordinate,
          sheetName: arg.sheetName,
        );
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          sum += val.value;
          count++;
        }
      } else {
        final val = evaluator.evaluate(arg, context);
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          sum += val.value;
          count++;
        } else if (val is TextCellValue) {
          final parsed = num.tryParse(val.text.trim());
          if (parsed != null) {
            sum += parsed;
            count++;
          } else {
            return const ErrorCellValue(CellError.value);
          }
        } else if (val is BooleanCellValue) {
          sum += val.value ? 1 : 0;
          count++;
        }
      }
    }

    if (count == 0) {
      return const ErrorCellValue(CellError.divZero);
    }
    return NumberCellValue(sum / count);
  }

  static CellValue _fnMin(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    num? minVal;

    for (final arg in args) {
      if (arg is RangeReferenceNode) {
        for (final val in context.getRangeValues(
          arg.range,
          sheetName: arg.sheetName,
        )) {
          if (val is ErrorCellValue) return val;
          if (val is NumberCellValue) {
            minVal = minVal == null
                ? val.value
                : (val.value < minVal ? val.value : minVal);
          }
        }
      } else if (arg is CellReferenceNode) {
        final val = context.getCellValue(
          arg.coordinate,
          sheetName: arg.sheetName,
        );
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          minVal = minVal == null
              ? val.value
              : (val.value < minVal ? val.value : minVal);
        }
      } else {
        final val = evaluator.evaluate(arg, context);
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          minVal = minVal == null
              ? val.value
              : (val.value < minVal ? val.value : minVal);
        } else if (val is TextCellValue) {
          final parsed = num.tryParse(val.text.trim());
          if (parsed != null) {
            minVal = minVal == null
                ? parsed
                : (parsed < minVal ? parsed : minVal);
          } else {
            return const ErrorCellValue(CellError.value);
          }
        }
      }
    }

    return NumberCellValue(minVal ?? 0);
  }

  static CellValue _fnMax(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    num? maxVal;

    for (final arg in args) {
      if (arg is RangeReferenceNode) {
        for (final val in context.getRangeValues(
          arg.range,
          sheetName: arg.sheetName,
        )) {
          if (val is ErrorCellValue) return val;
          if (val is NumberCellValue) {
            maxVal = maxVal == null
                ? val.value
                : (val.value > maxVal ? val.value : maxVal);
          }
        }
      } else if (arg is CellReferenceNode) {
        final val = context.getCellValue(
          arg.coordinate,
          sheetName: arg.sheetName,
        );
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          maxVal = maxVal == null
              ? val.value
              : (val.value > maxVal ? val.value : maxVal);
        }
      } else {
        final val = evaluator.evaluate(arg, context);
        if (val is ErrorCellValue) return val;
        if (val is NumberCellValue) {
          maxVal = maxVal == null
              ? val.value
              : (val.value > maxVal ? val.value : maxVal);
        } else if (val is TextCellValue) {
          final parsed = num.tryParse(val.text.trim());
          if (parsed != null) {
            maxVal = maxVal == null
                ? parsed
                : (parsed > maxVal ? parsed : maxVal);
          } else {
            return const ErrorCellValue(CellError.value);
          }
        }
      }
    }

    return NumberCellValue(maxVal ?? 0);
  }

  static CellValue _fnCount(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    int count = 0;

    for (final arg in args) {
      if (arg is RangeReferenceNode) {
        for (final val in context.getRangeValues(
          arg.range,
          sheetName: arg.sheetName,
        )) {
          if (val is NumberCellValue) count++;
        }
      } else if (arg is CellReferenceNode) {
        final val = context.getCellValue(
          arg.coordinate,
          sheetName: arg.sheetName,
        );
        if (val is NumberCellValue) count++;
      } else {
        final val = evaluator.evaluate(arg, context);
        if (val is NumberCellValue) {
          count++;
        } else if (val is TextCellValue &&
            num.tryParse(val.text.trim()) != null) {
          count++;
        }
      }
    }

    return NumberCellValue(count);
  }

  static CellValue _fnCountA(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    int count = 0;

    for (final arg in args) {
      if (arg is RangeReferenceNode) {
        for (final val in context.getRangeValues(
          arg.range,
          sheetName: arg.sheetName,
        )) {
          if (val is! EmptyCellValue) count++;
        }
      } else if (arg is CellReferenceNode) {
        final val = context.getCellValue(
          arg.coordinate,
          sheetName: arg.sheetName,
        );
        if (val is! EmptyCellValue) count++;
      } else {
        final val = evaluator.evaluate(arg, context);
        if (val is! EmptyCellValue) count++;
      }
    }

    return NumberCellValue(count);
  }

  static CellValue _fnIf(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    if (args.length < 2 || args.length > 3) {
      return const ErrorCellValue(CellError.value);
    }

    // Evaluate condition
    final conditionVal = evaluator.evaluate(args[0], context);
    if (conditionVal is ErrorCellValue) return conditionVal;

    bool isTrue = false;
    if (conditionVal is BooleanCellValue) {
      isTrue = conditionVal.value;
    } else if (conditionVal is NumberCellValue) {
      isTrue = conditionVal.value != 0;
    } else if (conditionVal is TextCellValue) {
      final text = conditionVal.text.trim().toUpperCase();
      if (text == 'TRUE') {
        isTrue = true;
      } else if (text == 'FALSE') {
        isTrue = false;
      } else {
        return const ErrorCellValue(CellError.value);
      }
    } else if (conditionVal is EmptyCellValue) {
      isTrue = false;
    }

    // Lazy branch execution
    if (isTrue) {
      return evaluator.evaluate(args[1], context);
    } else {
      if (args.length == 3) {
        return evaluator.evaluate(args[2], context);
      }
      return const BooleanCellValue(false);
    }
  }

  static CellValue _fnAbs(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    if (args.length != 1) return const ErrorCellValue(CellError.value);
    final val = evaluator.evaluate(args[0], context);
    if (val is ErrorCellValue) return val;

    final n = evaluator.coerceToNumber(val);
    if (n == null) return const ErrorCellValue(CellError.value);
    return NumberCellValue(n.abs());
  }

  static CellValue _fnRound(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    if (args.isEmpty || args.length > 2) {
      return const ErrorCellValue(CellError.value);
    }
    final val = evaluator.evaluate(args[0], context);
    if (val is ErrorCellValue) return val;

    final n = evaluator.coerceToNumber(val);
    if (n == null) return const ErrorCellValue(CellError.value);

    int digits = 0;
    if (args.length == 2) {
      final digitsVal = evaluator.evaluate(args[1], context);
      if (digitsVal is ErrorCellValue) return digitsVal;
      final d = evaluator.coerceToNumber(digitsVal);
      if (d == null) return const ErrorCellValue(CellError.value);
      digits = d.toInt();
    }

    if (digits >= 0) {
      final factor = _pow10(digits);
      return NumberCellValue((n * factor).round() / factor);
    } else {
      final factor = _pow10(-digits);
      return NumberCellValue((n / factor).round() * factor);
    }
  }

  static num _pow10(int exp) {
    num res = 1;
    for (int i = 0; i < exp; i++) {
      res *= 10;
    }
    return res;
  }

  static CellValue _fnNot(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    if (args.length != 1) return const ErrorCellValue(CellError.value);
    final val = evaluator.evaluate(args[0], context);
    if (val is ErrorCellValue) return val;

    final b = evaluator.coerceToBoolean(val);
    if (b == null) return const ErrorCellValue(CellError.value);
    return BooleanCellValue(!b);
  }

  static CellValue _fnAnd(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    if (args.isEmpty) return const ErrorCellValue(CellError.value);

    for (final arg in args) {
      final val = evaluator.evaluate(arg, context);
      if (val is ErrorCellValue) return val;
      final b = evaluator.coerceToBoolean(val);
      if (b == null) return const ErrorCellValue(CellError.value);
      if (!b) return const BooleanCellValue(false);
    }
    return const BooleanCellValue(true);
  }

  static CellValue _fnOr(
    List<FormulaNode> args,
    FormulaEvaluator evaluator,
    EvaluationContext context,
  ) {
    if (args.isEmpty) return const ErrorCellValue(CellError.value);

    for (final arg in args) {
      final val = evaluator.evaluate(arg, context);
      if (val is ErrorCellValue) return val;
      final b = evaluator.coerceToBoolean(val);
      if (b == null) return const ErrorCellValue(CellError.value);
      if (b) return const BooleanCellValue(true);
    }
    return const BooleanCellValue(false);
  }
}
