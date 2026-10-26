import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/filtering/dialogs/column_filter_dialog.dart';

void main() {
  group('Phase 08: Column Filter Dialog Widget Tests', () {
    testWidgets('mounts, applies text condition and filters rows', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final sheet = workbook.sheets[0];
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Apple'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Banana'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), 'Apricot'));

      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ColumnFilterDialog.show(context, state: state, colIndex: 0);
                  },
                  child: const Text('Open Filter'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Column A'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Enter filter value "Ap"
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Ap');
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Row 1 (Banana) should now be hidden!
      expect(sheet.isRowHidden(1), isTrue);
      expect(sheet.isRowHidden(0), isFalse);
      expect(sheet.isRowHidden(2), isFalse);
    });
  });
}
