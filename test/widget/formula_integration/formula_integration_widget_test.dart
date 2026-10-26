import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/state.dart';
import 'package:grid_sheet/core/keyboard/desktop_shortcuts.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/formula_bar/widgets/formula_bar.dart';

/// Minimal scaffold that wraps [child] with WorkbookState provider and
/// standard Material theming so widgets can render in tests.
Widget _wrap({required WorkbookState state, required Widget child}) {
  return MaterialApp(
    home: ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(body: child),
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Formula Bar — formula preservation display
  // ---------------------------------------------------------------------------
  group('Phase 05 Widget — FormulaBar Formula Display', () {
    testWidgets('formula bar shows rawInput (formula text) for formula cell', (
      tester,
    ) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), '50');
      state.editCellAt(const CellCoordinate(1, 0), '=A1*2');
      state.selectCell(const CellCoordinate(1, 0));

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: FormulaBar(state: state),
        ),
      );
      await tester.pump();

      // The formula bar text field should show the raw formula, not '100'
      expect(find.text('=A1*2'), findsOneWidget);
    });

    testWidgets('formula bar shows plain number for non-formula cell', (
      tester,
    ) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), '42');
      state.selectCell(const CellCoordinate(0, 0));

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: FormulaBar(state: state),
        ),
      );
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets(
      'formula bar updates when selection moves to a different cell',
      (tester) async {
        final state = WorkbookState();
        state.editCellAt(const CellCoordinate(0, 0), '=1+1');
        state.editCellAt(const CellCoordinate(1, 0), 'plain text');

        await tester.pumpWidget(
          _wrap(
            state: state,
            child: FormulaBar(state: state),
          ),
        );

        // Select formula cell
        state.selectCell(const CellCoordinate(0, 0));
        await tester.pump();
        expect(find.text('=1+1'), findsOneWidget);

        // Move to plain text cell
        state.selectCell(const CellCoordinate(1, 0));
        await tester.pump();
        expect(find.text('plain text'), findsOneWidget);
      },
    );

    testWidgets('name box shows correct A1 address of selected cell', (
      tester,
    ) async {
      final state = WorkbookState();
      state.selectCell(const CellCoordinate(2, 3)); // D3

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: FormulaBar(state: state),
        ),
      );
      await tester.pump();

      expect(find.text('D3'), findsOneWidget);
    });

    testWidgets('submitting formula from formula bar commits and evaluates', (
      tester,
    ) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), '5');
      state.selectCell(const CellCoordinate(1, 0)); // A2 selected

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: FormulaBar(state: state),
        ),
      );
      await tester.pump();

      // Tap the formula input field
      final formulaField = find.byType(TextField).last;
      await tester.tap(formulaField);
      await tester.pump();

      // Enter a formula
      await tester.enterText(formulaField, '=A1+10');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final cell = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect(cell?.rawInput, equals('=A1+10'));
      expect((cell?.computedValue as NumberCellValue?)?.value, equals(15));
    });
  });

  // ---------------------------------------------------------------------------
  // Keyboard Shortcuts — Formatting
  // ---------------------------------------------------------------------------
  group('Phase 05 Widget — Formatting Keyboard Shortcuts', () {
    testWidgets('Ctrl+B toggles bold on selection', (tester) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), 'Hello');
      state.selectCell(const CellCoordinate(0, 0));

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: DesktopShortcuts(state: state, child: const SizedBox.expand()),
        ),
      );
      await tester.pump();

      // Focus the widget so shortcuts fire
      await tester.tap(find.byType(Focus).last);
      await tester.pump();

      expect(state.activeCell?.style.isBold, isFalse);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.style.isBold,
        isTrue,
      );
    });

    testWidgets('Ctrl+I toggles italic on selection', (tester) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), 'Text');
      state.selectCell(const CellCoordinate(0, 0));

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: DesktopShortcuts(state: state, child: const SizedBox.expand()),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(Focus).last);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(
        state.activeWorksheet
            .getCell(const CellCoordinate(0, 0))
            ?.style
            .isItalic,
        isTrue,
      );
    });

    testWidgets('Ctrl+U toggles underline on selection', (tester) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), 'Underlined');
      state.selectCell(const CellCoordinate(0, 0));

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: DesktopShortcuts(state: state, child: const SizedBox.expand()),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(Focus).last);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyU);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyU);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(
        state.activeWorksheet
            .getCell(const CellCoordinate(0, 0))
            ?.style
            .isUnderline,
        isTrue,
      );
    });

    testWidgets('Ctrl+B bold can be undone with Ctrl+Z', (tester) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), 'Test');
      state.selectCell(const CellCoordinate(0, 0));

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: DesktopShortcuts(state: state, child: const SizedBox.expand()),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(Focus).last);
      await tester.pump();

      // Bold
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.style.isBold,
        isTrue,
      );

      // Undo
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.style.isBold,
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Regression — Phase 03 Keyboard Navigation still works
  // ---------------------------------------------------------------------------
  group('Phase 05 Regression — Phase 03 Keyboard Navigation', () {
    testWidgets('arrow keys still navigate selection', (tester) async {
      final state = WorkbookState();

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: DesktopShortcuts(state: state, child: const SizedBox.expand()),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(Focus).last);
      await tester.pump();

      expect(state.selection.primaryCell.a1, equals('A1'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(state.selection.primaryCell.a1, equals('A2'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(state.selection.primaryCell.a1, equals('B2'));
    });

    testWidgets('Ctrl+Z undo still works for formula edits', (tester) async {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), '99');

      await tester.pumpWidget(
        _wrap(
          state: state,
          child: DesktopShortcuts(state: state, child: const SizedBox.expand()),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(Focus).last);
      await tester.pump();

      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0)),
        isNotNull,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0)), isNull);
    });
  });
}
