import 'package:flutter_test/flutter_test.dart';

import 'package:grid_sheet/data/import_export/csv_engine.dart';

void main() {
  const engine = CsvEngine();

  group('Delimiter detection accuracy', () {
    test('comma-separated 5-column data', () {
      const sample = '''
Name,Age,City,Country,Email
Alice,30,New York,USA,alice@example.com
Bob,25,London,UK,bob@example.com
Carol,35,Paris,France,carol@example.com
''';
      final result = engine.detectDelimiter(sample);
      expect(result.delimiter, CsvDelimiter.comma);
      expect(result.confidence, greaterThan(0.5));
    });

    test('tab-separated 3-column data', () {
      const sample = 'Product\tPrice\tQty\nApple\t1.20\t50\nBanana\t0.80\t100';
      final result = engine.detectDelimiter(sample);
      expect(result.delimiter, CsvDelimiter.tab);
    });

    test('semicolon-separated European locale data', () {
      const sample = 'Artikel;Preis;Menge\nApfel;1,20;50\nBanane;0,80;100';
      final result = engine.detectDelimiter(sample);
      expect(result.delimiter, CsvDelimiter.semicolon);
    });

    test('pipe-separated data', () {
      const sample = 'ID|Name|Status\n1|Alice|Active\n2|Bob|Inactive';
      final result = engine.detectDelimiter(sample);
      expect(result.delimiter, CsvDelimiter.pipe);
    });

    test('single column data returns confidence 0.0 or lowest', () {
      const sample = 'Alice\nBob\nCarol';
      final result = engine.detectDelimiter(sample);
      // All delimiters score 0; result.confidence should be very low
      expect(result.confidence, lessThanOrEqualTo(0.5));
    });

    test('comma in quoted field does not confuse semicolon detection', () {
      // Data with semicolons but quoted commas
      const sample = 'Name;Notes\nAlice;"Has,comma inside"\nBob;"No comma"';
      final result = engine.detectDelimiter(sample, maxLines: 10);
      expect(result.delimiter, CsvDelimiter.semicolon);
    });

    test('tab detection with consistent column count', () {
      final lines = List.generate(
        10,
        (i) => 'col1_$i\tcol2_$i\tcol3_$i\tcol4_$i',
      );
      final result = engine.detectDelimiter(lines.join('\n'));
      expect(result.delimiter, CsvDelimiter.tab);
      expect(result.confidence, greaterThan(0.5));
    });

    test('mixed content, comma should win for CSV from Excel', () {
      const sample = '''
First Name,Last Name,Department,Salary
John,Smith,Engineering,95000
Jane,Doe,Marketing,80000
Robert,Brown,HR,70000
''';
      final result = engine.detectDelimiter(sample);
      expect(result.delimiter, CsvDelimiter.comma);
    });
  });

  group('Delimiter detection edge cases', () {
    test('maxLines parameter limits analysis to N lines', () {
      // First 2 lines use semicolons, rest use commas — with maxLines=2 should pick semicolon
      final lines = ['a;b;c', 'x;y;z', 'p,q,r', 's,t,u', 'm,n,o'];
      final result = engine.detectDelimiter(lines.join('\n'), maxLines: 2);
      expect(result.delimiter, CsvDelimiter.semicolon);
    });

    test('empty lines are ignored in scoring', () {
      const sample = 'a,b,c\n\n\nd,e,f';
      final result = engine.detectDelimiter(sample);
      expect(result.delimiter, CsvDelimiter.comma);
    });
  });
}
