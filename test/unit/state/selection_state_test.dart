import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/selection_state.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('SelectionState - Construction & Basic Invariants', () {
    test('initial selection defaults to cell A1', () {
      const state = SelectionState.initial;
      expect(state.primaryCell, equals(const CellCoordinate(0, 0)));
      expect(state.primaryCell.a1, equals('A1'));
      expect(state.activeRange.start, equals(const CellCoordinate(0, 0)));
      expect(state.activeRange.end, equals(const CellCoordinate(0, 0)));
      expect(state.mode, equals(SelectionMode.cell));
      expect(state.isSingleCell, isTrue);
      expect(state.selectedCellCount, equals(1));
      expect(state.secondaryRanges, isEmpty);
    });

    test('fromCell constructs single cell selection', () {
      const coord = CellCoordinate(4, 2); // C5
      final state = SelectionState.fromCell(coord);

      expect(state.primaryCell, equals(coord));
      expect(state.activeRange.isSingleCell, isTrue);
      expect(state.mode, equals(SelectionMode.cell));
      expect(state.selectedCellCount, equals(1));
    });

    test('fromRange constructs range selection and calculates cell count', () {
      final range = CellRange.fromA1('B2:D4'); // 3 rows x 3 cols = 9 cells
      final state = SelectionState.fromRange(range);

      expect(state.primaryCell, equals(const CellCoordinate(1, 1))); // B2
      expect(state.activeRange, equals(range));
      expect(state.mode, equals(SelectionMode.range));
      expect(state.isSingleCell, isFalse);
      expect(state.selectedCellCount, equals(9));
    });
  });

  group('SelectionState - Navigation & Extensions', () {
    test('selectCell moves primary coordinate and replaces active range', () {
      const state = SelectionState.initial;
      final moved = state.selectCell(const CellCoordinate(2, 3)); // D3

      expect(moved.primaryCell, equals(const CellCoordinate(2, 3)));
      expect(moved.activeRange.a1, equals('D3'));
      expect(moved.isSingleCell, isTrue);
    });

    test(
      'extendSelection preserves primary anchor and recalculates bounding box',
      () {
        final state = SelectionState.fromCell(
          const CellCoordinate(1, 1),
        ); // B2 anchor
        // Extend to D4 (3, 3)
        final extended = state.extendSelection(const CellCoordinate(3, 3));

        expect(
          extended.primaryCell,
          equals(const CellCoordinate(1, 1)),
        ); // B2 anchor preserved
        expect(extended.activeRange.a1, equals('B2:D4'));
        expect(extended.selectedCellCount, equals(9));
        expect(extended.mode, equals(SelectionMode.range));
      },
    );

    test(
      'extendSelection in reverse direction normalizes bounding box properly',
      () {
        final state = SelectionState.fromCell(
          const CellCoordinate(5, 5),
        ); // F6 anchor
        // Drag backward up to D4 (3, 3)
        final extended = state.extendSelection(const CellCoordinate(3, 3));

        expect(extended.primaryCell, equals(const CellCoordinate(5, 5)));
        expect(extended.activeRange.a1, equals('D4:F6'));
      },
    );
  });

  group('SelectionState - Structural Selections (Row, Column, All)', () {
    test('selectEntireRow spans entire column boundary', () {
      final state = SelectionState.initial.selectEntireRow(2); // Row 3

      expect(state.mode, equals(SelectionMode.entireRow));
      expect(state.activeRange.start, equals(const CellCoordinate(2, 0)));
      expect(
        state.activeRange.end,
        equals(const CellCoordinate(2, CellCoordinate.maxCols - 1)),
      );
      expect(state.selectedCellCount, equals(CellCoordinate.maxCols));
    });

    test('selectEntireColumn spans entire row boundary', () {
      final state = SelectionState.initial.selectEntireColumn(1); // Column B

      expect(state.mode, equals(SelectionMode.entireColumn));
      expect(state.activeRange.start, equals(const CellCoordinate(0, 1)));
      expect(
        state.activeRange.end,
        equals(const CellCoordinate(CellCoordinate.maxRows - 1, 1)),
      );
      expect(state.selectedCellCount, equals(CellCoordinate.maxRows));
    });

    test('selectAll covers complete worksheet grid', () {
      final state = SelectionState.initial.selectAll();

      expect(state.mode, equals(SelectionMode.entireSheet));
      expect(state.activeRange.start, equals(const CellCoordinate(0, 0)));
      expect(
        state.activeRange.end,
        equals(
          const CellCoordinate(
            CellCoordinate.maxRows - 1,
            CellCoordinate.maxCols - 1,
          ),
        ),
      );
    });
  });

  group('SelectionState - Disjoint Multi-Selection & Containment', () {
    test('addSecondaryRange tracks disjoint ranges and sums cell counts', () {
      // Primary: A1:A2 (2 cells)
      final primary = SelectionState.fromRange(CellRange.fromA1('A1:A2'));
      // Secondary: C1:C3 (3 cells)
      final withSecondary = primary.addSecondaryRange(
        CellRange.fromA1('C1:C3'),
      );

      expect(withSecondary.secondaryRanges.length, equals(1));
      expect(withSecondary.selectedCellCount, equals(5));

      // Containment checks
      expect(
        withSecondary.contains(const CellCoordinate(0, 0)),
        isTrue,
      ); // A1 (primary)
      expect(
        withSecondary.contains(const CellCoordinate(1, 0)),
        isTrue,
      ); // A2 (primary)
      expect(
        withSecondary.contains(const CellCoordinate(0, 2)),
        isTrue,
      ); // C1 (secondary)
      expect(
        withSecondary.contains(const CellCoordinate(2, 2)),
        isTrue,
      ); // C3 (secondary)
      expect(
        withSecondary.contains(const CellCoordinate(0, 1)),
        isFalse,
      ); // B1 (outside)
    });

    test('equality and hashCode conform to value semantics', () {
      final s1 = SelectionState.fromRange(CellRange.fromA1('A1:B2'));
      final s2 = SelectionState.fromRange(CellRange.fromA1('A1:B2'));
      final s3 = SelectionState.fromRange(CellRange.fromA1('A1:C3'));

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });
}
