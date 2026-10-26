import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/sorting/dialogs/sort_dialog.dart';

void main() {
  group('Phase 08: Sort Dialog Widget Tests', () {
    testWidgets('mounts, allows configuring sort column/direction and sorts', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final sheet = workbook.sheets[0];
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Name'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Charlie'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), 'Alice'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(3, 0), 'Bob'));

      final state = WorkbookState(initialWorkbook: workbook);
      // Select range A1:A4
      state.selectRange(
        CellRange(const CellCoordinate(0, 0), const CellCoordinate(3, 0)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SortDialog.show(context, state: state);
                  },
                  child: const Text('Open Sort'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sort'));
      await tester.pumpAndSettle();

      expect(find.text('Sort Range'), findsOneWidget);
      expect(find.text('My data has headers'), findsOneWidget);
      expect(find.text('Sort'), findsOneWidget);

      // Check "My data has headers"
      await tester.tap(find.text('My data has headers'));
      await tester.pumpAndSettle();

      // Tap Sort button
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.text('Sort Range'), findsNothing);

      // Verify sorted order (header preserved, rows 1-3 sorted)
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'Name');
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, 'Alice');
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, 'Bob');
      expect(sheet.getCell(const CellCoordinate(3, 0))?.rawInput, 'Charlie');
    });
  });
}
