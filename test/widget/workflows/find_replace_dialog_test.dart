import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/find_replace/dialogs/find_replace_dialog.dart';

void main() {
  group('Phase 08: Find and Replace Dialog Widget Tests', () {
    testWidgets('mounts and renders Find and Replace tabs and fields', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final sheet = workbook.sheets[0];
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Apple Pie'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Banana Split'));
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FindReplaceDialog.show(context, state: state);
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Find'), findsWidgets);
      expect(find.text('Replace'), findsWidgets);
      expect(find.text('Match case'), findsOneWidget);
      expect(find.text('Find Next'), findsOneWidget);

      // Enter search term
      await tester.enterText(find.byType(TextField).first, 'Apple');
      await tester.pumpAndSettle();

      // Find next match
      await tester.tap(find.text('Find Next'));
      await tester.pumpAndSettle();

      expect(find.text('Match 1 of 1'), findsOneWidget);
    });

    testWidgets('Replace tab allows replacing matches', (tester) async {
      final workbook = Workbook.createDefault();
      final sheet = workbook.sheets[0];
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Fox'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Fox'));
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FindReplaceDialog.show(
                      context,
                      state: state,
                      initialTab: 1,
                    );
                  },
                  child: const Text('Open Replace Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Replace Dialog'));
      await tester.pumpAndSettle();

      // Enter Find and Replace texts
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.at(0), 'Fox');
      await tester.enterText(textFields.at(1), 'Wolf');
      await tester.pumpAndSettle();

      // Tap Replace All
      await tester.tap(find.text('Replace All'));
      await tester.pumpAndSettle();

      // Verify cells updated
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'Wolf');
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, 'Wolf');
    });
  });
}
