import 'package:flutter_test/flutter_test.dart';

import 'package:grid_sheet/data/import_export/csv_engine.dart';

void main() {
  const engine = CsvEngine();

  // ---------------------------------------------------------------------------
  // RFC 4180 Parsing
  // ---------------------------------------------------------------------------

  group('CsvEngine.parseString — basic', () {
    test('parses single field', () {
      final rows = engine.parseString('hello');
      expect(rows, [
        ['hello'],
      ]);
    });

    test('parses single row with comma delimiter', () {
      final rows = engine.parseString('a,b,c');
      expect(rows, [
        ['a', 'b', 'c'],
      ]);
    });

    test('parses multiple rows with \\n line ending', () {
      final rows = engine.parseString('a,b\nc,d');
      expect(rows, [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('parses multiple rows with \\r\\n line ending', () {
      final rows = engine.parseString('a,b\r\nc,d');
      expect(rows, [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('parses rows with \\r-only line ending', () {
      final rows = engine.parseString('a,b\rc,d');
      expect(rows, [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('handles empty fields', () {
      final rows = engine.parseString(',b,,d');
      expect(rows, [
        ['', 'b', '', 'd'],
      ]);
    });

    test('handles trailing newline gracefully', () {
      final rows = engine.parseString('a,b\n');
      // Last empty row should not appear as an extra row in most implementations.
      // Our parser flushes only if buffer is non-empty or row has data.
      expect(rows.isNotEmpty, isTrue);
      expect(rows.first, ['a', 'b']);
    });
  });

  group('CsvEngine.parseString — RFC 4180 quoted fields', () {
    test('parses quoted field', () {
      final rows = engine.parseString('"hello"');
      expect(rows, [
        ['hello'],
      ]);
    });

    test('parses quoted field with embedded comma', () {
      final rows = engine.parseString('"a,b",c');
      expect(rows, [
        ['a,b', 'c'],
      ]);
    });

    test('parses quoted field with double-quote escape', () {
      final rows = engine.parseString('"a""b"');
      expect(rows, [
        ['a"b'],
      ]);
    });

    test('parses quoted field containing embedded newline', () {
      final rows = engine.parseString('"line1\nline2",next');
      expect(rows, [
        ['line1\nline2', 'next'],
      ]);
    });

    test('parses mixed quoted and unquoted fields', () {
      final rows = engine.parseString('plain,"with,comma",also plain');
      expect(rows, [
        ['plain', 'with,comma', 'also plain'],
      ]);
    });

    test('parses multiple escaped quotes', () {
      final rows = engine.parseString('"""quoted"""');
      expect(rows, [
        ['"quoted"'],
      ]);
    });
  });

  group('CsvEngine.parseString — tab delimiter', () {
    test('parses TSV row', () {
      final rows = engine.parseString('a\tb\tc', delimiter: CsvDelimiter.tab);
      expect(rows, [
        ['a', 'b', 'c'],
      ]);
    });

    test('parses TSV multirow', () {
      final rows = engine.parseString(
        'x\ty\nz\tw',
        delimiter: CsvDelimiter.tab,
      );
      expect(rows, [
        ['x', 'y'],
        ['z', 'w'],
      ]);
    });
  });

  group('CsvEngine.parseString — semicolon delimiter', () {
    test('parses semicolon-separated fields', () {
      final rows = engine.parseString(
        'a;b;c',
        delimiter: CsvDelimiter.semicolon,
      );
      expect(rows, [
        ['a', 'b', 'c'],
      ]);
    });
  });

  group('CsvEngine.parseString — UTF-8 BOM', () {
    test('strips UTF-8 BOM from source', () {
      final rows = engine.parseString('\uFEFFa,b,c');
      expect(rows, [
        ['a', 'b', 'c'],
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------------

  group('CsvEngine.writeString', () {
    test('writes simple rows', () {
      final csv = engine.writeString([
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
      expect(csv, 'a,b,c\r\n1,2,3');
    });

    test('quotes fields containing commas', () {
      final csv = engine.writeString([
        ['hello,world', 'plain'],
      ]);
      expect(csv, '"hello,world",plain');
    });

    test('escapes embedded double-quotes', () {
      final csv = engine.writeString([
        ['say "hello"'],
      ]);
      expect(csv, '"say ""hello"""');
    });

    test('quotes fields containing newlines', () {
      final csv = engine.writeString([
        ['line1\nline2'],
      ]);
      expect(csv, '"line1\nline2"');
    });

    test('round-trips quoted-comma field', () {
      final original = [
        ['has,comma', 'normal'],
      ];
      final csvStr = engine.writeString(original);
      final parsed = engine.parseString(csvStr);
      expect(parsed, original);
    });

    test('round-trips multirow data', () {
      final original = [
        ['Name', 'Age', 'City'],
        ['Alice', '30', 'New York'],
        ['Bob', '25', 'London, UK'],
      ];
      final csvStr = engine.writeString(original);
      final parsed = engine.parseString(csvStr);
      expect(parsed, original);
    });

    test('writes TSV with tab delimiter', () {
      final tsv = engine.writeString(
        [
          ['a', 'b'],
          ['c', 'd'],
        ],
        delimiter: CsvDelimiter.tab,
        lineEnding: '\n',
      );
      expect(tsv, 'a\tb\nc\td');
    });
  });

  // ---------------------------------------------------------------------------
  // Delimiter Detection
  // ---------------------------------------------------------------------------

  group('CsvEngine.detectDelimiter', () {
    test('detects comma delimiter', () {
      final result = engine.detectDelimiter('a,b,c\n1,2,3\n4,5,6');
      expect(result.delimiter, CsvDelimiter.comma);
      expect(result.confidence, greaterThan(0.4));
    });

    test('detects tab delimiter', () {
      final result = engine.detectDelimiter('a\tb\tc\n1\t2\t3\n4\t5\t6');
      expect(result.delimiter, CsvDelimiter.tab);
      expect(result.confidence, greaterThan(0.4));
    });

    test('detects semicolon delimiter', () {
      final result = engine.detectDelimiter('a;b;c\n1;2;3\n4;5;6');
      expect(result.delimiter, CsvDelimiter.semicolon);
      expect(result.confidence, greaterThan(0.4));
    });

    test('detects pipe delimiter', () {
      final result = engine.detectDelimiter('a|b|c\n1|2|3\n4|5|6');
      expect(result.delimiter, CsvDelimiter.pipe);
      expect(result.confidence, greaterThan(0.4));
    });

    test('returns comma with 0.0 confidence for empty string', () {
      final result = engine.detectDelimiter('');
      expect(result.delimiter, CsvDelimiter.comma);
      expect(result.confidence, 0.0);
    });

    test('confidence is in [0,1] range', () {
      final result = engine.detectDelimiter('a,b,c\n1,2,3');
      expect(result.confidence, inInclusiveRange(0.0, 1.0));
    });
  });
}
