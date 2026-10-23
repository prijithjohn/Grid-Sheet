import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';
import 'package:grid_sheet/domain/cell/cell_range.dart';

void main() {
  group('CellRange - Construction & Bounds Normalization', () {
    test(
      'normalizes bounds when start is top-left and end is bottom-right',
      () {
        final range = CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(4, 2),
        );
        expect(range.topRow, 0);
        expect(range.bottomRow, 4);
        expect(range.leftCol, 0);
        expect(range.rightCol, 2);
        expect(range.rowCount, 5);
        expect(range.colCount, 3);
        expect(range.cellCount, 15);
        expect(range.isSingleCell, false);
        expect(range.toA1(), 'A1:C5');
      },
    );

    test('normalizes bounds when coordinates are given in reverse order', () {
      // Constructed backwards (C5 to A1)
      final range = CellRange(
        const CellCoordinate(4, 2),
        const CellCoordinate(0, 0),
      );
      expect(range.topRow, 0);
      expect(range.bottomRow, 4);
      expect(range.leftCol, 0);
      expect(range.rightCol, 2);
      expect(range.cellCount, 15);
      // toA1 uses start:end
      expect(range.toA1(), 'C5:A1');
    });

    test('single cell range properties', () {
      final single = CellRange.single(const CellCoordinate(2, 3));
      expect(single.topRow, 2);
      expect(single.bottomRow, 2);
      expect(single.leftCol, 3);
      expect(single.rightCol, 3);
      expect(single.rowCount, 1);
      expect(single.colCount, 1);
      expect(single.cellCount, 1);
      expect(single.isSingleCell, true);
      expect(single.toA1(), 'D3');
    });

    test('fromBounds constructs range with normalized indices', () {
      final range = CellRange.fromBounds(
        topRow: 1,
        bottomRow: 3,
        leftCol: 0,
        rightCol: 2,
      );
      expect(range.rowCount, 3);
      expect(range.colCount, 3);
      expect(range.cellCount, 9);
    });

    test('fromBounds throws if inverted bounds are provided', () {
      expect(
        () => CellRange.fromBounds(
          topRow: 5,
          bottomRow: 2,
          leftCol: 0,
          rightCol: 2,
        ),
        throwsArgumentError,
      );
      expect(
        () => CellRange.fromBounds(
          topRow: 0,
          bottomRow: 2,
          leftCol: 5,
          rightCol: 2,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CellRange - A1 String Parsing', () {
    test('parses multi-cell range strings', () {
      final range = CellRange.fromA1('A1:C10');
      expect(range.topRow, 0);
      expect(range.bottomRow, 9);
      expect(range.leftCol, 0);
      expect(range.rightCol, 2);
      expect(range.rowCount, 10);
      expect(range.colCount, 3);
      expect(range.cellCount, 30);
    });

    test('parses single-cell range string', () {
      final range = CellRange.fromA1('B5');
      expect(range.isSingleCell, true);
      expect(range.topRow, 4);
      expect(range.leftCol, 1);
      expect(range.toA1(), 'B5');
    });

    test(r'parses ranges with absolute anchors ($)', () {
      final range = CellRange.fromA1(r'$A$1:$D$20');
      expect(range.start.isColAbsolute, true);
      expect(range.start.isRowAbsolute, true);
      expect(range.end.isColAbsolute, true);
      expect(range.end.isRowAbsolute, true);
      expect(range.toA1(), r'$A$1:$D$20');
      expect(range.toA1(includeAnchors: false), 'A1:D20');
    });

    test('throws FormatException on malformed range strings', () {
      expect(() => CellRange.fromA1(''), throwsFormatException);
      expect(() => CellRange.fromA1('A1:B2:C3'), throwsFormatException);
      expect(() => CellRange.fromA1('Invalid:Range'), throwsFormatException);
    });
  });

  group(
    'CellRange - Spatial Operations (Containment, Intersection, Bounding Box)',
    () {
      final baseRange = CellRange.fromA1('B2:E6'); // rows 1..5, cols 1..4

      test('contains coordinate accurately', () {
        expect(baseRange.contains(const CellCoordinate(1, 1)), isTrue); // B2
        expect(baseRange.contains(const CellCoordinate(5, 4)), isTrue); // E6
        expect(baseRange.contains(const CellCoordinate(3, 2)), isTrue); // C4

        expect(
          baseRange.contains(const CellCoordinate(0, 1)),
          isFalse,
        ); // B1 (above)
        expect(
          baseRange.contains(const CellCoordinate(6, 1)),
          isFalse,
        ); // B7 (below)
        expect(
          baseRange.contains(const CellCoordinate(2, 0)),
          isFalse,
        ); // A3 (left)
        expect(
          baseRange.contains(const CellCoordinate(2, 5)),
          isFalse,
        ); // F3 (right)
      });

      test('containsRange verifies complete containment', () {
        final inner = CellRange.fromA1('C3:D5');
        final edge = CellRange.fromA1('B2:E6');
        final partial = CellRange.fromA1('C3:F5');

        expect(baseRange.containsRange(inner), isTrue);
        expect(baseRange.containsRange(edge), isTrue);
        expect(baseRange.containsRange(partial), isFalse);
      });

      test('intersects verifies overlap between ranges', () {
        final overlapping = CellRange.fromA1('D5:G8');
        final disjoint = CellRange.fromA1('F7:H10');
        final adjacent = CellRange.fromA1('F2:F6'); // Right next to col E

        expect(baseRange.intersects(overlapping), isTrue);
        expect(baseRange.intersects(disjoint), isFalse);
        expect(baseRange.intersects(adjacent), isFalse);
      });

      test('intersection returns overlapping rectangular area', () {
        final overlapping = CellRange.fromA1('C4:F8');
        final result = baseRange.intersection(overlapping);

        expect(result, isNotNull);
        expect(result!.topRow, 3); // row 4
        expect(result.bottomRow, 5); // row 6
        expect(result.leftCol, 2); // col C
        expect(result.rightCol, 4); // col E
        expect(result.toA1(), 'C4:E6');

        final disjoint = CellRange.fromA1('Z1:Z10');
        expect(baseRange.intersection(disjoint), isNull);
      });

      test('boundingBox returns the union envelope of two ranges', () {
        final other = CellRange.fromA1('G8:H10');
        final bounding = baseRange.boundingBox(other);

        expect(bounding.topRow, 1);
        expect(bounding.bottomRow, 9);
        expect(bounding.leftCol, 1);
        expect(bounding.rightCol, 7);
        expect(bounding.toA1(), 'B2:H10');
      });

      test('coordinates yields all cell coordinates in row-major order', () {
        final range = CellRange.fromA1('A1:B2');
        final coords = range.coordinates.toList();

        expect(coords.length, 4);
        expect(coords[0], const CellCoordinate(0, 0)); // A1
        expect(coords[1], const CellCoordinate(0, 1)); // B1
        expect(coords[2], const CellCoordinate(1, 0)); // A2
        expect(coords[3], const CellCoordinate(1, 1)); // B2
      });
    },
  );

  group('CellRange - Equality', () {
    test('ranges with identical normalized bounds are equal', () {
      final r1 = CellRange(
        const CellCoordinate(0, 0),
        const CellCoordinate(2, 2),
      );
      final r2 = CellRange(
        const CellCoordinate(2, 2),
        const CellCoordinate(0, 0),
      );
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });
  });
}
