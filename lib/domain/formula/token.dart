/// Tokens produced by [FormulaLexer] representing syntactic elements of a spreadsheet formula.
enum TokenType {
  // Literals
  number,
  string,
  boolean,

  // References
  cellReference,
  rangeReference,

  // Identifier / Function Name
  identifier,

  // Arithmetic Operators
  plus, // +
  minus, // -
  multiply, // *
  divide, // /
  power, // ^

  // Comparison Operators
  equal, // =
  notEqual, // <> or !=
  lessThan, // <
  lessThanOrEqual, // <=
  greaterThan, // >
  greaterThanOrEqual, // >=

  // Punctuation
  openParen, // (
  closeParen, // )
  comma, // ,
  colon, // :

  // End of file / error
  eof,
  error,
}

/// A lexical token in a spreadsheet formula expression.
class FormulaToken {
  final TokenType type;
  final String lexeme;
  final Object? literalValue;
  final int position;

  const FormulaToken({
    required this.type,
    required this.lexeme,
    this.literalValue,
    required this.position,
  });

  @override
  String toString() =>
      'FormulaToken($type, "$lexeme", value: $literalValue, pos: $position)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaToken &&
          type == other.type &&
          lexeme == other.lexeme &&
          literalValue == other.literalValue &&
          position == other.position;

  @override
  int get hashCode => Object.hash(type, lexeme, literalValue, position);
}
