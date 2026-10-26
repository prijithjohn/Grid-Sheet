import 'token.dart';

/// Lexer that tokenizes formula strings into a sequence of [FormulaToken]s.
class FormulaLexer {
  final String source;
  final int _length;
  int _current = 0;
  final List<FormulaToken> _tokens = [];

  FormulaLexer(String input)
    : source = input.startsWith('=') ? input.substring(1) : input,
      _length = (input.startsWith('=') ? input.substring(1) : input).length;

  /// Tokenizes the source expression and returns all tokens including [TokenType.eof].
  List<FormulaToken> tokenize() {
    _tokens.clear();
    _current = 0;

    while (!_isAtEnd) {
      _skipWhitespace();
      if (_isAtEnd) break;

      final startPos = _current;
      final c = _advance();

      switch (c) {
        case '(':
          _addToken(TokenType.openParen, '(', startPos);
          break;
        case ')':
          _addToken(TokenType.closeParen, ')', startPos);
          break;
        case ',':
          _addToken(TokenType.comma, ',', startPos);
          break;
        case ':':
          _addToken(TokenType.colon, ':', startPos);
          break;
        case '+':
          _addToken(TokenType.plus, '+', startPos);
          break;
        case '-':
          _addToken(TokenType.minus, '-', startPos);
          break;
        case '*':
          _addToken(TokenType.multiply, '*', startPos);
          break;
        case '/':
          _addToken(TokenType.divide, '/', startPos);
          break;
        case '^':
          _addToken(TokenType.power, '^', startPos);
          break;
        case '=':
          _addToken(TokenType.equal, '=', startPos);
          break;
        case '<':
          if (_match('>')) {
            _addToken(TokenType.notEqual, '<>', startPos);
          } else if (_match('=')) {
            _addToken(TokenType.lessThanOrEqual, '<=', startPos);
          } else {
            _addToken(TokenType.lessThan, '<', startPos);
          }
          break;
        case '>':
          if (_match('=')) {
            _addToken(TokenType.greaterThanOrEqual, '>=', startPos);
          } else {
            _addToken(TokenType.greaterThan, '>', startPos);
          }
          break;
        case '!':
          if (_match('=')) {
            _addToken(TokenType.notEqual, '!=', startPos);
          } else {
            _addToken(
              TokenType.error,
              '!',
              startPos,
              literalValue: 'Unexpected character: !',
            );
          }
          break;
        case '"':
          _string(startPos);
          break;
        case '\'':
          // Single-quoted sheet name, e.g. 'Sheet 1'!A1
          _singleQuotedSheetReference(startPos);
          break;
        default:
          if (_isDigit(c) || (c == '.' && _isDigit(_peek))) {
            _number(startPos, c == '.');
          } else if (_isAlpha(c) || c == r'$') {
            _identifierOrReference(startPos);
          } else {
            _addToken(
              TokenType.error,
              c,
              startPos,
              literalValue: 'Unexpected character: $c',
            );
          }
          break;
      }
    }

    _tokens.add(
      FormulaToken(type: TokenType.eof, lexeme: '', position: _current),
    );

    return List.unmodifiable(_tokens);
  }

  void _skipWhitespace() {
    while (!_isAtEnd) {
      final c = _peek;
      if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
        _advance();
      } else {
        break;
      }
    }
  }

  void _string(int startPos) {
    final buffer = StringBuffer();
    while (!_isAtEnd) {
      if (_peek == '"') {
        _advance();
        // Check for escaped quote ""
        if (_peek == '"') {
          buffer.write('"');
          _advance();
        } else {
          // End of string
          _tokens.add(
            FormulaToken(
              type: TokenType.string,
              lexeme: source.substring(startPos, _current),
              literalValue: buffer.toString(),
              position: startPos,
            ),
          );
          return;
        }
      } else {
        buffer.write(_advance());
      }
    }

    // Unterminated string
    _tokens.add(
      FormulaToken(
        type: TokenType.error,
        lexeme: source.substring(startPos, _current),
        literalValue: 'Unterminated string literal',
        position: startPos,
      ),
    );
  }

  void _singleQuotedSheetReference(int startPos) {
    // Read until closing quote '
    while (!_isAtEnd && _peek != '\'') {
      _advance();
    }
    if (_isAtEnd) {
      _tokens.add(
        FormulaToken(
          type: TokenType.error,
          lexeme: source.substring(startPos, _current),
          literalValue: 'Unterminated sheet name in reference',
          position: startPos,
        ),
      );
      return;
    }
    _advance(); // consume closing '

    // Must be followed by !
    if (_peek == '!') {
      _advance(); // consume !
      // Now read cell coordinate
      while (!_isAtEnd && (_isAlphaNumeric(_peek) || _peek == r'$')) {
        _advance();
      }
      final lexeme = source.substring(startPos, _current);
      _tokens.add(
        FormulaToken(
          type: TokenType.cellReference,
          lexeme: lexeme,
          literalValue: lexeme,
          position: startPos,
        ),
      );
    } else {
      final lexeme = source.substring(startPos, _current);
      _tokens.add(
        FormulaToken(
          type: TokenType.error,
          lexeme: lexeme,
          literalValue: "Expected '!' after sheet name",
          position: startPos,
        ),
      );
    }
  }

  void _number(int startPos, bool startsWithDot) {
    bool hasDot = startsWithDot;

    while (!_isAtEnd) {
      if (_isDigit(_peek)) {
        _advance();
      } else if (_peek == '.' && !hasDot) {
        hasDot = true;
        _advance();
      } else {
        break;
      }
    }

    // Optional exponent (e.g. 1e5, 1.2e-3)
    if (!_isAtEnd && (_peek == 'e' || _peek == 'E')) {
      final nextChar = _peekNext;
      if (_isDigit(nextChar) || nextChar == '+' || nextChar == '-') {
        _advance(); // consume e/E
        if (_peek == '+' || _peek == '-') {
          _advance(); // consume sign
        }
        while (!_isAtEnd && _isDigit(_peek)) {
          _advance();
        }
      }
    }

    final lexeme = source.substring(startPos, _current);
    final numValue = num.tryParse(lexeme);
    _tokens.add(
      FormulaToken(
        type: TokenType.number,
        lexeme: lexeme,
        literalValue: numValue ?? 0,
        position: startPos,
      ),
    );
  }

  void _identifierOrReference(int startPos) {
    while (!_isAtEnd &&
        (_isAlphaNumeric(_peek) || _peek == r'$' || _peek == '_')) {
      _advance();
    }

    // Check if this is a sheet-qualified reference, e.g. Sheet1!A1
    if (!_isAtEnd && _peek == '!') {
      _advance(); // consume !
      while (!_isAtEnd && (_isAlphaNumeric(_peek) || _peek == r'$')) {
        _advance();
      }
      final lexeme = source.substring(startPos, _current);
      _tokens.add(
        FormulaToken(
          type: TokenType.cellReference,
          lexeme: lexeme,
          literalValue: lexeme,
          position: startPos,
        ),
      );
      return;
    }

    final lexeme = source.substring(startPos, _current);
    final upper = lexeme.toUpperCase();

    // Check if followed by '(' -> function call identifier
    _skipWhitespace();
    if (!_isAtEnd && _peek == '(') {
      _tokens.add(
        FormulaToken(
          type: TokenType.identifier,
          lexeme: upper,
          literalValue: upper,
          position: startPos,
        ),
      );
      return;
    }

    // Check boolean literals
    if (upper == 'TRUE') {
      _tokens.add(
        FormulaToken(
          type: TokenType.boolean,
          lexeme: lexeme,
          literalValue: true,
          position: startPos,
        ),
      );
      return;
    }
    if (upper == 'FALSE') {
      _tokens.add(
        FormulaToken(
          type: TokenType.boolean,
          lexeme: lexeme,
          literalValue: false,
          position: startPos,
        ),
      );
      return;
    }

    // Check if it matches cell coordinate pattern (e.g. A1, $A$1, B$10, $XFD1048576)
    if (_isCellCoordinate(lexeme)) {
      _tokens.add(
        FormulaToken(
          type: TokenType.cellReference,
          lexeme: lexeme,
          literalValue: lexeme,
          position: startPos,
        ),
      );
      return;
    }

    // Otherwise, generic identifier / function without parentheses yet
    _tokens.add(
      FormulaToken(
        type: TokenType.identifier,
        lexeme: upper,
        literalValue: upper,
        position: startPos,
      ),
    );
  }

  static final RegExp _cellCoordRegex = RegExp(
    r'^\$?([A-Za-z]{1,3})\$?([1-9][0-9]{0,6})$',
  );

  bool _isCellCoordinate(String str) {
    final match = _cellCoordRegex.firstMatch(str);
    if (match == null) return false;
    final rowStr = match.group(2);
    if (rowStr == null) return false;
    final rowNum = int.tryParse(rowStr);
    if (rowNum == null || rowNum < 1 || rowNum > 1048576) return false;
    return true;
  }

  bool get _isAtEnd => _current >= _length;

  String _advance() {
    return source[_current++];
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (source[_current] != expected) return false;
    _current++;
    return true;
  }

  String get _peek {
    if (_isAtEnd) return '\x00';
    return source[_current];
  }

  String get _peekNext {
    if (_current + 1 >= _length) return '\x00';
    return source[_current + 1];
  }

  bool _isDigit(String s) {
    if (s.isEmpty) return false;
    final code = s.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isAlpha(String s) {
    if (s.isEmpty) return false;
    final code = s.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        code == 95; // _
  }

  bool _isAlphaNumeric(String s) {
    return _isAlpha(s) || _isDigit(s);
  }

  void _addToken(
    TokenType type,
    String lexeme,
    int position, {
    Object? literalValue,
  }) {
    _tokens.add(
      FormulaToken(
        type: type,
        lexeme: lexeme,
        position: position,
        literalValue: literalValue,
      ),
    );
  }
}
