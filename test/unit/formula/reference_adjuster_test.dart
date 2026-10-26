import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('FormulaReferenceAdjuster', () {
    test('non-formula string returns unchanged', () {
      expect(
        FormulaReferenceAdjuster.adjustReferences('Hello World'),
        'Hello World',
      );
      expect(FormulaReferenceAdjuster.adjustReferences('12345'), '12345');
    });

    test('relative references shift on fill down (deltaRows)', () {
      expect(
        FormulaReferenceAdjuster.adjustReferences('=A1+B1', deltaRows: 1),
        '=A2+B2',
      );
      expect(
        FormulaReferenceAdjuster.adjustReferences('=A1+B1', deltaRows: 5),
        '=A6+B6',
      );
    });

    test('absolute row references do not shift on fill down', () {
      expect(
        FormulaReferenceAdjuster.adjustReferences('=A\$1+\$B\$2', deltaRows: 3),
        '=A\$1+\$B\$2',
      );
    });

    test('relative references shift on fill right (deltaCols)', () {
      expect(
        FormulaReferenceAdjuster.adjustReferences('=A1+A2', deltaCols: 1),
        '=B1+B2',
      );
      expect(
        FormulaReferenceAdjuster.adjustReferences('=A1+A2', deltaCols: 2),
        '=C1+C2',
      );
    });

    test('absolute col references do not shift on fill right', () {
      expect(
        FormulaReferenceAdjuster.adjustReferences('=\$A1+\$B\$2', deltaCols: 4),
        '=\$A1+\$B\$2',
      );
    });

    test('mixed relative and absolute references adjust correctly', () {
      // $A1: A is fixed, 1 can move
      // B$1: B can move, 1 is fixed
      expect(
        FormulaReferenceAdjuster.adjustReferences(
          '=\$A1+B\$1',
          deltaRows: 2,
          deltaCols: 3,
        ),
        '=\$A3+E\$1',
      );
    });

    test('range references adjust both start and end coordinates', () {
      expect(
        FormulaReferenceAdjuster.adjustReferences('=SUM(A1:B10)', deltaRows: 2),
        '=SUM(A3:B12)',
      );
      expect(
        FormulaReferenceAdjuster.adjustReferences('=SUM(A1:B10)', deltaCols: 1),
        '=SUM(B1:C10)',
      );
    });

    test('sheet qualified references preserve sheet name', () {
      expect(
        FormulaReferenceAdjuster.adjustReferences(
          '=Sheet1!A1+\'Sales Data\'!B2',
          deltaRows: 1,
        ),
        '=Sheet1!A2+\'Sales Data\'!B3',
      );
    });

    test('row insertion shifts references at or below insertion row', () {
      // Insert 1 row at row index 2 (Row 3 in 1-based)
      // A1 (row 0) should remain A1
      // A3 (row 2) should become A4
      // A5 (row 4) should become A6
      expect(
        FormulaReferenceAdjuster.adjustReferences(
          '=A1+A3+A5',
          insertedRowAt: 2,
          insertedRowCount: 1,
        ),
        '=A1+A4+A6',
      );
    });

    test('row deletion shifts rows up or turns into #REF!', () {
      // Delete row index 2 (Row 3 in 1-based)
      // A1 (row 0) remains A1
      // A3 (row 2) becomes #REF!
      // A4 (row 3) becomes A3
      expect(
        FormulaReferenceAdjuster.adjustReferences(
          '=A1+A3+A4',
          deletedRowAt: 2,
          deletedRowCount: 1,
        ),
        '=A1+#REF!+A3',
      );
    });

    test('column insertion and deletion shifts appropriately', () {
      // Insert col at B (col index 1)
      expect(
        FormulaReferenceAdjuster.adjustReferences(
          '=A1+B1+C1',
          insertedColAt: 1,
          insertedColCount: 1,
        ),
        '=A1+C1+D1',
      );

      // Delete col at B (col index 1)
      expect(
        FormulaReferenceAdjuster.adjustReferences(
          '=A1+B1+C1',
          deletedColAt: 1,
          deletedColCount: 1,
        ),
        '=A1+#REF!+B1',
      );
    });
  });
}
