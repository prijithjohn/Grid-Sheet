import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';

void main() {
  group('CellCoordinate - Construction & Conversion', () {
    test('constructs basic coordinate and converts to A1', () {
      const coord = CellCoordinate(0, 0);
      expect(coord.row, 0);
      expect(coord.col, 0);
      expect(coord.toA1(), 'A1');
      expect(coord.toString(), 'A1');
    });

    test('parses standard A1 addresses correctly', () {
      final a1 = CellCoordinate.fromA1('A1');
      expect(a1.row, 0);
      expect(a1.col, 0);
      expect(a1.isColAbsolute, false);
      expect(a1.isRowAbsolute, false);

      final c10 = CellCoordinate.fromA1('C10');
      expect(c10.row, 9);
      expect(c10.col, 2);
      expect(c10.toA1(), 'C10');

      final z100 = CellCoordinate.fromA1('Z100');
      expect(z100.row, 99);
      expect(z100.col, 25);
      expect(z100.toA1(), 'Z100');

      final aa1 = CellCoordinate.fromA1('AA1');
      expect(aa1.row, 0);
      expect(aa1.col, 26);
      expect(aa1.toA1(), 'AA1');

      final ab5 = CellCoordinate.fromA1('AB5');
      expect(ab5.row, 4);
      expect(ab5.col, 27);
      expect(ab5.toA1(), 'AB5');
    });

    test(r'parses and preserves absolute reference anchors ($)', () {
      final absBoth = CellCoordinate.fromA1(r'$B$5');
      expect(absBoth.col, 1);
      expect(absBoth.row, 4);
      expect(absBoth.isColAbsolute, true);
      expect(absBoth.isRowAbsolute, true);
      expect(absBoth.toA1(), r'$B$5');
      expect(absBoth.toA1(includeAnchors: false), 'B5');

      final absColOnly = CellCoordinate.fromA1(r'$C12');
      expect(absColOnly.isColAbsolute, true);
      expect(absColOnly.isRowAbsolute, false);
      expect(absColOnly.toA1(), r'$C12');

      final absRowOnly = CellCoordinate.fromA1(r'D$20');
      expect(absRowOnly.isColAbsolute, false);
      expect(absRowOnly.isRowAbsolute, true);
      expect(absRowOnly.toA1(), r'D$20');
    });

    test('supports standard maximum spreadsheet boundaries (XFD1048576)', () {
      final maxCoord = CellCoordinate.fromA1('XFD1048576');
      expect(maxCoord.col, 16383);
      expect(maxCoord.row, 1048575);
      expect(maxCoord.toA1(), 'XFD1048576');

      const fromIndices = CellCoordinate(1048575, 16383);
      expect(fromIndices.toA1(), 'XFD1048576');
    });

    test('handles case-insensitivity on column letters', () {
      final lower = CellCoordinate.fromA1('xfd1048576');
      expect(lower.col, 16383);
      expect(lower.row, 1048575);
      expect(lower.toA1(), 'XFD1048576');
    });
  });

  group('CellCoordinate - Letters and Columns Bi-directional Conversion', () {
    test(
      'columnToLetters converts single, double, and triple letters accurately',
      () {
        expect(CellCoordinate.columnToLetters(0), 'A');
        expect(CellCoordinate.columnToLetters(25), 'Z');
        expect(CellCoordinate.columnToLetters(26), 'AA');
        expect(CellCoordinate.columnToLetters(27), 'AB');
        expect(CellCoordinate.columnToLetters(51), 'AZ');
        expect(CellCoordinate.columnToLetters(52), 'BA');
        expect(CellCoordinate.columnToLetters(701), 'ZZ');
        expect(CellCoordinate.columnToLetters(702), 'AAA');
        expect(CellCoordinate.columnToLetters(16383), 'XFD');
      },
    );

    test('lettersToColumn converts letters to 0-indexed integers', () {
      expect(CellCoordinate.lettersToColumn('A'), 0);
      expect(CellCoordinate.lettersToColumn('Z'), 25);
      expect(CellCoordinate.lettersToColumn('AA'), 26);
      expect(CellCoordinate.lettersToColumn('AB'), 27);
      expect(CellCoordinate.lettersToColumn('ZZ'), 701);
      expect(CellCoordinate.lettersToColumn('AAA'), 702);
      expect(CellCoordinate.lettersToColumn('XFD'), 16383);
    });

    test('round-trips all column indices up to maxCols', () {
      final sampleIndices = [0, 1, 25, 26, 52, 100, 701, 702, 1000, 16383];
      for (final col in sampleIndices) {
        final letters = CellCoordinate.columnToLetters(col);
        expect(CellCoordinate.lettersToColumn(letters), col);
      }
    });
  });

  group('CellCoordinate - Error Handling & Boundary Rejections', () {
    test('rejects out of bounds column or row in constructor', () {
      expect(() => CellCoordinate.validated(-1, 0), throwsRangeError);
      expect(() => CellCoordinate.validated(0, -1), throwsRangeError);
      expect(
        () => CellCoordinate.validated(CellCoordinate.maxRows, 0),
        throwsRangeError,
      );
      expect(
        () => CellCoordinate.validated(0, CellCoordinate.maxCols),
        throwsRangeError,
      );
    });

    test('rejects malformed A1 address strings', () {
      expect(() => CellCoordinate.fromA1(''), throwsFormatException);
      expect(() => CellCoordinate.fromA1('   '), throwsFormatException);
      expect(() => CellCoordinate.fromA1('A'), throwsFormatException);
      expect(() => CellCoordinate.fromA1('1'), throwsFormatException);
      expect(() => CellCoordinate.fromA1('1A'), throwsFormatException);
      expect(
        () => CellCoordinate.fromA1('A0'),
        throwsFormatException,
      ); // Rows are 1-indexed
      expect(() => CellCoordinate.fromA1('A-5'), throwsFormatException);
      expect(() => CellCoordinate.fromA1(r'$$A1'), throwsFormatException);
      expect(() => CellCoordinate.fromA1('A1B2'), throwsFormatException);
    });

    test('rejects coordinates exceeding maximum limits in fromA1', () {
      // Column beyond XFD
      expect(() => CellCoordinate.fromA1('XFE1'), throwsFormatException);
      // Row beyond 1048576
      expect(() => CellCoordinate.fromA1('A1048577'), throwsFormatException);
    });
  });

  group('CellCoordinate - Offset, Equality & Comparison', () {
    test('offset calculates relative shifts', () {
      const coord = CellCoordinate(5, 5);
      final shifted = coord.offset(rowDelta: 2, colDelta: -3);
      expect(shifted.row, 7);
      expect(shifted.col, 2);
    });

    test('offset throws when shifted outside boundaries', () {
      const coord = CellCoordinate(0, 0);
      expect(() => coord.offset(rowDelta: -1), throwsRangeError);
      expect(() => coord.offset(colDelta: -1), throwsRangeError);
    });

    test('equality and hashcode conform to contract', () {
      const c1 = CellCoordinate(10, 2, isColAbsolute: true);
      const c2 = CellCoordinate(10, 2, isColAbsolute: true);
      const c3 = CellCoordinate(10, 2, isColAbsolute: false);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('compareTo sorts coordinates in row-major order', () {
      final list = [
        const CellCoordinate(2, 0),
        const CellCoordinate(0, 5),
        const CellCoordinate(0, 1),
        const CellCoordinate(1, 1),
      ]..sort();

      expect(list[0], const CellCoordinate(0, 1));
      expect(list[1], const CellCoordinate(0, 5));
      expect(list[2], const CellCoordinate(1, 1));
      expect(list[3], const CellCoordinate(2, 0));
    });
  });
}
