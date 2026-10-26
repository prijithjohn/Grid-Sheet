import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/formula/lexer.dart';
import 'package:grid_sheet/domain/formula/token.dart';

void main() {
  group('FormulaLexer', () {
    List<FormulaToken> lex(String input) =>
        FormulaLexer(input).tokenize().toList();

    TokenType typeOf(List<FormulaToken> tokens, int i) => tokens[i].type;
    Object? literalOf(List<FormulaToken> tokens, int i) => tokens[i].literalValue;

    // -------------------------------------------------------------------------
    // Basic single-char operators
    // -------------------------------------------------------------------------
    group('operators', () {
      test('tokenizes + - * / ^ operators', () {
        final tokens = lex('=1+2-3*4/5^6');
        expect(typeOf(tokens, 0), TokenType.number);
        expect(typeOf(tokens, 1), TokenType.plus);
        expect(typeOf(tokens, 2), TokenType.number);
        expect(typeOf(tokens, 3), TokenType.minus);
        expect(typeOf(tokens, 4), TokenType.number);
        expect(typeOf(tokens, 5), TokenType.multiply);
        expect(typeOf(tokens, 6), TokenType.number);
        expect(typeOf(tokens, 7), TokenType.divide);
        expect(typeOf(tokens, 8), TokenType.number);
        expect(typeOf(tokens, 9), TokenType.power);
        expect(typeOf(tokens, 10), TokenType.number);
        expect(typeOf(tokens, 11), TokenType.eof);
      });

      test('tokenizes parentheses and comma', () {
        final tokens = lex('=(A1,B2)');
        expect(typeOf(tokens, 0), TokenType.openParen);
        expect(typeOf(tokens, 1), TokenType.cellReference);
        expect(typeOf(tokens, 2), TokenType.comma);
        expect(typeOf(tokens, 3), TokenType.cellReference);
        expect(typeOf(tokens, 4), TokenType.closeParen);
        expect(typeOf(tokens, 5), TokenType.eof);
      });

      test('tokenizes colon', () {
        final tokens = lex('=A1:B2');
        expect(typeOf(tokens, 1), TokenType.colon);
      });
    });

    // -------------------------------------------------------------------------
    // Comparison operators
    // -------------------------------------------------------------------------
    group('comparison operators', () {
      test('= (equal)', () {
        final t = lex('=A1=B1');
        expect(typeOf(t, 1), TokenType.equal);
      });

      test('< (less than)', () {
        final t = lex('=A1<B1');
        expect(typeOf(t, 1), TokenType.lessThan);
      });

      test('<= (less than or equal)', () {
        final t = lex('=A1<=B1');
        expect(typeOf(t, 1), TokenType.lessThanOrEqual);
      });

      test('> (greater than)', () {
        final t = lex('=A1>B1');
        expect(typeOf(t, 1), TokenType.greaterThan);
      });

      test('>= (greater than or equal)', () {
        final t = lex('=A1>=B1');
        expect(typeOf(t, 1), TokenType.greaterThanOrEqual);
      });

      test('<> (not equal)', () {
        final t = lex('=A1<>B1');
        expect(typeOf(t, 1), TokenType.notEqual);
      });
    });

    // -------------------------------------------------------------------------
    // Number literals
    // -------------------------------------------------------------------------
    group('number literals', () {
      test('integer', () {
        final t = lex('=42');
        expect(typeOf(t, 0), TokenType.number);
        expect(literalOf(t, 0), 42);
      });

      test('decimal', () {
        final t = lex('=3.14');
        expect(typeOf(t, 0), TokenType.number);
        expect(literalOf(t, 0), 3.14);
      });

      test('leading dot', () {
        final t = lex('=.5');
        expect(typeOf(t, 0), TokenType.number);
        expect(literalOf(t, 0), 0.5);
      });

      test('scientific notation', () {
        final t = lex('=1e5');
        expect(typeOf(t, 0), TokenType.number);
        expect(literalOf(t, 0), 1e5);
      });

      test('scientific notation with negative exponent', () {
        final t = lex('=1.5e-3');
        expect(typeOf(t, 0), TokenType.number);
        expect((literalOf(t, 0) as num).toStringAsExponential(), '1.5e-3');
      });
    });

    // -------------------------------------------------------------------------
    // String literals
    // -------------------------------------------------------------------------
    group('string literals', () {
      test('simple string', () {
        final t = lex('="hello"');
        expect(typeOf(t, 0), TokenType.string);
        expect(literalOf(t, 0), 'hello');
      });

      test('empty string', () {
        final t = lex('=""');
        expect(typeOf(t, 0), TokenType.string);
        expect(literalOf(t, 0), '');
      });

      test('string with escaped double quote', () {
        final t = lex('="say ""hi"""');
        expect(typeOf(t, 0), TokenType.string);
        expect(literalOf(t, 0), 'say "hi"');
      });

      test('unterminated string produces error token', () {
        final t = lex('="hello');
        expect(typeOf(t, 0), TokenType.error);
      });
    });

    // -------------------------------------------------------------------------
    // Boolean literals
    // -------------------------------------------------------------------------
    group('boolean literals', () {
      test('TRUE', () {
        final t = lex('=TRUE');
        expect(typeOf(t, 0), TokenType.boolean);
        expect(literalOf(t, 0), true);
      });

      test('FALSE', () {
        final t = lex('=FALSE');
        expect(typeOf(t, 0), TokenType.boolean);
        expect(literalOf(t, 0), false);
      });

      test('lowercase true becomes boolean', () {
        final t = lex('=true');
        expect(typeOf(t, 0), TokenType.boolean);
        expect(literalOf(t, 0), true);
      });
    });

    // -------------------------------------------------------------------------
    // Cell references
    // -------------------------------------------------------------------------
    group('cell references', () {
      test('simple reference A1', () {
        final t = lex('=A1');
        expect(typeOf(t, 0), TokenType.cellReference);
        expect(t[0].lexeme, 'A1');
      });

      test('absolute reference \$A\$1', () {
        final t = lex('=\$A\$1');
        expect(typeOf(t, 0), TokenType.cellReference);
      });

      test('mixed reference A\$1', () {
        final t = lex('=A\$1');
        expect(typeOf(t, 0), TokenType.cellReference);
      });

      test('multi-column reference XFD1', () {
        final t = lex('=XFD1');
        expect(typeOf(t, 0), TokenType.cellReference);
      });

      test('sheet-qualified reference Sheet1!A1', () {
        final t = lex('=Sheet1!A1');
        expect(typeOf(t, 0), TokenType.cellReference);
        expect(t[0].lexeme, 'Sheet1!A1');
      });

      test('single-quoted sheet reference', () {
        final t = lex("='My Sheet'!B2");
        expect(typeOf(t, 0), TokenType.cellReference);
      });
    });

    // -------------------------------------------------------------------------
    // Function identifiers
    // -------------------------------------------------------------------------
    group('function identifiers', () {
      test('SUM( is tokenized as identifier then openParen', () {
        final t = lex('=SUM(');
        expect(typeOf(t, 0), TokenType.identifier);
        expect(t[0].lexeme, 'SUM');
        expect(typeOf(t, 1), TokenType.openParen);
      });

      test('lowercase function becomes uppercase identifier', () {
        final t = lex('=average(');
        expect(typeOf(t, 0), TokenType.identifier);
        expect(t[0].lexeme, 'AVERAGE');
      });
    });

    // -------------------------------------------------------------------------
    // Whitespace handling
    // -------------------------------------------------------------------------
    group('whitespace', () {
      test('leading/trailing spaces are skipped', () {
        final t = lex('=  1  +  2  ');
        expect(typeOf(t, 0), TokenType.number);
        expect(typeOf(t, 1), TokenType.plus);
        expect(typeOf(t, 2), TokenType.number);
        expect(typeOf(t, 3), TokenType.eof);
      });
    });

    // -------------------------------------------------------------------------
    // Formula without = prefix
    // -------------------------------------------------------------------------
    group('raw expression (no = prefix)', () {
      test('tokenizes without leading =', () {
        final t = lex('1+2');
        expect(typeOf(t, 0), TokenType.number);
        expect(typeOf(t, 1), TokenType.plus);
        expect(typeOf(t, 2), TokenType.number);
        expect(typeOf(t, 3), TokenType.eof);
      });
    });

    // -------------------------------------------------------------------------
    // Unexpected characters
    // -------------------------------------------------------------------------
    group('error tokens', () {
      test('unexpected character produces error token', () {
        final t = lex('=@');
        expect(typeOf(t, 0), TokenType.error);
      });
    });
  });
}
