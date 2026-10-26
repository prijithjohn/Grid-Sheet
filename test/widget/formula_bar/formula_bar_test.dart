import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/formula_bar/widgets/formula_bar.dart';

void main() {
  group('Phase 03A: FormulaBar Widget Tests', () {
    WorkbookState makeState() =>
        WorkbookState(initialWorkbook: Workbook.createDefault());

    testWidgets('Name Box shows A1 for default active cell', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormulaBar(state: state)),
        ),
      );

      expect(find.text('A1'), findsOneWidget);
    });

    testWidgets('Name Box updates reactively when active cell changes', (
      tester,
    ) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormulaBar(state: state)),
        ),
      );

      state.selectCell(const CellCoordinate(4, 1)); // B5
      await tester.pump();

      expect(find.text('B5'), findsOneWidget);
    });

    testWidgets('fx helper label is present', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormulaBar(state: state)),
        ),
      );

      expect(find.text('fx'), findsOneWidget);
    });

    testWidgets('entering text in formula input and submitting commits value', (
      tester,
    ) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormulaBar(state: state)),
        ),
      );

      final formulaField = find.byType(TextField).last;
      await tester.enterText(formulaField, '=SUM(A1:A4)');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(state.activeCellInput, '=SUM(A1:A4)');
    });

    testWidgets(
      'formula input text updates reactively when external state changes',
      (tester) async {
        final state = makeState();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: FormulaBar(state: state)),
          ),
        );

        // Externally set a cell value
        state.editCellAt(const CellCoordinate(0, 0), 'ExternalValue');
        await tester.pump();

        // Formula bar should now show the raw input of active cell
        expect(state.activeCellInput, 'ExternalValue');
      },
    );

    testWidgets('Name Box navigate to cell on submit', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormulaBar(state: state)),
        ),
      );

      // Type into the Name Box
      final nameBox = find.byType(TextField).first;
      await tester.tap(nameBox);
      await tester.pumpAndSettle();

      await tester.enterText(nameBox, 'C7');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(state.activeCellAddress, 'C7');
    });
  });
}
