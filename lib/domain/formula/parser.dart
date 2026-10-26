import '../cell/cell_coordinate.dart';
import '../cell/cell_range.dart';
import '../cell/cell_value.dart';
import 'ast.dart';
import 'lexer.dart';
import 'token.dart';

/// Exception thrown when a formula syntax error occurs during parsing.
class FormulaParseException implements Exception {
  final String message;
  final int position;

  const FormulaParseException(this.message, {this.position = 0});

  @override
  String toString() => 'FormulaParseException: $message at pos $position';
}

/// Recursive-descent parser that transforms tokens from [FormulaLexer] into an AST [FormulaNode].
class FormulaParser {
  final List<FormulaToken> _tokens;
  int _current = 0;

  FormulaParser(this._tokens);

  /// Convenience factory creating a parser directly from a formula source string.
  factory FormulaParser.fromString(String source) {
    final lexer = FormulaLexer(source);
    return FormulaParser(lexer.tokenize());
  }

  /// Parses the complete formula expression and returns the root [FormulaNode].
  FormulaNode parse() {
    if (_tokens.isEmpty || _peek.type == TokenType.eof) {
      return const NumberLiteralNode(0);
    }

    try {
      final expr = _expression();
      if (!_isAtEnd && _peek.type != TokenType.eof) {
        throw FormulaParseException(
          'Unexpected trailing token: "${_peek.lexeme}"',
          position: _peek.position,
        );
      }
      return expr;
    } on FormulaParseException catch (e) {
      return ErrorNode(CellError.name, e.message);
    }
  }

  // expression -> comparison
  FormulaNode _expression() {
    return _comparison();
  }

  // comparison -> additive ( ( "=" | "<>" | "!=" | "<" | "<=" | ">" | ">=" ) additive )*
  FormulaNode _comparison() {
    var expr = _additive();

    while (true) {
      BinaryOp? op;
      if (_match(TokenType.equal)) {
        op = BinaryOp.equal;
      } else if (_match(TokenType.notEqual)) {
        op = BinaryOp.notEqual;
      } else if (_match(TokenType.lessThanOrEqual)) {
        op = BinaryOp.lessThanOrEqual;
      } else if (_match(TokenType.greaterThanOrEqual)) {
        op = BinaryOp.greaterThanOrEqual;
      } else if (_match(TokenType.lessThan)) {
        op = BinaryOp.lessThan;
      } else if (_match(TokenType.greaterThan)) {
        op = BinaryOp.greaterThan;
      } else {
        break;
      }

      final right = _additive();
      expr = BinaryOpNode(op: op, left: expr, right: right);
    }

    return expr;
  }

  // additive -> multiplicative ( ( "+" | "-" ) multiplicative )*
  FormulaNode _additive() {
    var expr = _multiplicative();

    while (true) {
      BinaryOp? op;
      if (_match(TokenType.plus)) {
        op = BinaryOp.add;
      } else if (_match(TokenType.minus)) {
        op = BinaryOp.subtract;
      } else {
        break;
      }

      final right = _multiplicative();
      expr = BinaryOpNode(op: op, left: expr, right: right);
    }

    return expr;
  }

  // multiplicative -> exponentiation ( ( "*" | "/" ) exponentiation )*
  FormulaNode _multiplicative() {
    var expr = _exponentiation();

    while (true) {
      BinaryOp? op;
      if (_match(TokenType.multiply)) {
        op = BinaryOp.multiply;
      } else if (_match(TokenType.divide)) {
        op = BinaryOp.divide;
      } else {
        break;
      }

      final right = _exponentiation();
      expr = BinaryOpNode(op: op, left: expr, right: right);
    }

    return expr;
  }

  // exponentiation -> unary ( "^" exponentiation )?  (right-associative)
  FormulaNode _exponentiation() {
    final expr = _unary();

    if (_match(TokenType.power)) {
      final right =
          _exponentiation(); // right-recursive for right-associativity
      return BinaryOpNode(op: BinaryOp.power, left: expr, right: right);
    }

    return expr;
  }

  // unary -> ( "+" | "-" ) unary | range
  FormulaNode _unary() {
    if (_match(TokenType.minus)) {
      final operand = _unary();
      return UnaryOpNode(op: UnaryOp.minus, operand: operand);
    }
    if (_match(TokenType.plus)) {
      final operand = _unary();
      return UnaryOpNode(op: UnaryOp.plus, operand: operand);
    }

    return _range();
  }

  // range -> primary ( ":" primary )?
  FormulaNode _range() {
    final expr = _primary();

    if (_match(TokenType.colon)) {
      final right = _primary();

      // Check if both sides are cell references to build a RangeReferenceNode
      if (expr is CellReferenceNode && right is CellReferenceNode) {
        final startCoord = expr.coordinate;
        final endCoord = right.coordinate;
        final range = CellRange(startCoord, endCoord);
        final rawText = '${expr.rawText}:${right.rawText}';
        final sheetName = expr.sheetName ?? right.sheetName;
        return RangeReferenceNode(
          sheetName: sheetName,
          range: range,
          rawText: rawText,
        );
      } else {
        return const ErrorNode(
          CellError.ref,
          'Colon range operator requires cell references on both sides',
        );
      }
    }

    return expr;
  }

  // primary -> number | string | boolean | cellReference | functionCall | "(" expression ")"
  FormulaNode _primary() {
    if (_match(TokenType.number)) {
      final val = _previous.literalValue as num? ?? 0;
      return NumberLiteralNode(val);
    }

    if (_match(TokenType.string)) {
      final val = _previous.literalValue as String? ?? '';
      return StringLiteralNode(val);
    }

    if (_match(TokenType.boolean)) {
      final val = _previous.literalValue as bool? ?? false;
      return BooleanLiteralNode(val);
    }

    if (_match(TokenType.cellReference)) {
      return _parseCellReference(_previous.lexeme);
    }

    if (_match(TokenType.identifier)) {
      final name = _previous.lexeme.toUpperCase();

      // Check if followed by '(' -> function call
      if (_match(TokenType.openParen)) {
        return _parseFunctionCall(name);
      }

      // If standalone TRUE or FALSE
      if (name == 'TRUE') return const BooleanLiteralNode(true);
      if (name == 'FALSE') return const BooleanLiteralNode(false);

      // Unrecognized identifier not followed by parentheses
      return ErrorNode(CellError.name, 'Unrecognized function or name: $name');
    }

    if (_match(TokenType.openParen)) {
      final expr = _expression();
      _consume(TokenType.closeParen, "Expected ')' after expression");
      return expr;
    }

    if (_match(TokenType.error)) {
      return ErrorNode(
        CellError.name,
        _previous.literalValue as String? ?? 'Syntax error',
      );
    }

    throw FormulaParseException(
      'Unexpected token: "${_peek.lexeme}"',
      position: _peek.position,
    );
  }

  FormulaNode _parseFunctionCall(String functionName) {
    final args = <FormulaNode>[];

    if (!_check(TokenType.closeParen)) {
      do {
        if (_check(TokenType.closeParen)) break;
        args.add(_expression());
      } while (_match(TokenType.comma));
    }

    _consume(
      TokenType.closeParen,
      "Expected ')' after arguments for $functionName",
    );
    return FunctionCallNode(functionName: functionName, arguments: args);
  }

  FormulaNode _parseCellReference(String raw) {
    String? sheetName;
    String coordPart = raw;

    final bangIndex = raw.indexOf('!');
    if (bangIndex != -1) {
      sheetName = raw.substring(0, bangIndex);
      if (sheetName.startsWith('\'') && sheetName.endsWith('\'')) {
        sheetName = sheetName.substring(1, sheetName.length - 1);
      }
      coordPart = raw.substring(bangIndex + 1);
    }

    bool isColAbs = false;
    bool isRowAbs = false;

    var s = coordPart;
    if (s.startsWith(r'$')) {
      isColAbs = true;
      s = s.substring(1);
    }

    // Split letters and digits
    final letters = StringBuffer();
    final digits = StringBuffer();
    bool hitRowDollar = false;

    for (int i = 0; i < s.length; i++) {
      final char = s[i];
      if (char == r'$') {
        hitRowDollar = true;
        isRowAbs = true;
      } else if (!hitRowDollar && _isAlpha(char)) {
        letters.write(char.toUpperCase());
      } else if (_isDigit(char)) {
        digits.write(char);
      }
    }

    try {
      final colStr = letters.toString();
      final rowStr = digits.toString();

      if (colStr.isEmpty || rowStr.isEmpty) {
        return ErrorNode(CellError.ref, 'Invalid reference syntax: $raw');
      }

      final col = CellCoordinate.lettersToColumn(colStr);
      final rowNum = int.parse(rowStr);
      final row = rowNum - 1; // Convert 1-indexed to 0-indexed

      if (col < 0 ||
          col >= CellCoordinate.maxCols ||
          row < 0 ||
          row >= CellCoordinate.maxRows) {
        return ErrorNode(CellError.ref, 'Reference out of bounds: $raw');
      }

      final coordinate = CellCoordinate(row, col);
      return CellReferenceNode(
        sheetName: sheetName,
        coordinate: coordinate,
        isColAbsolute: isColAbs,
        isRowAbsolute: isRowAbs,
        rawText: raw,
      );
    } catch (_) {
      return ErrorNode(CellError.ref, 'Invalid cell reference: $raw');
    }
  }

  bool _isAlpha(String s) {
    if (s.isEmpty) return false;
    final code = s.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isDigit(String s) {
    if (s.isEmpty) return false;
    final code = s.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _match(TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek.type == type;
  }

  FormulaToken _advance() {
    if (!_isAtEnd) _current++;
    return _previous;
  }

  bool get _isAtEnd => _peek.type == TokenType.eof;

  FormulaToken get _peek => _tokens[_current];

  FormulaToken get _previous => _tokens[_current - 1];

  FormulaToken _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw FormulaParseException(message, position: _peek.position);
  }
}
