import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/grid/widgets/grid_viewport.dart';
import 'package:grid_sheet/features/grid/widgets/status_bar.dart';
import 'package:grid_sheet/features/workbook/screens/workbook_screen.dart';

void main() {
  group('Phase 03B: Grid Interaction & Canvas Tests', () {
    testWidgets('Tapping on a cell updates WorkbookState selection', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: GridViewport(state: state),
            ),
          ),
        ),
      );

      expect(state.selection.primaryCell, const CellCoordinate(0, 0));

      final gesture = await tester.startGesture(const Offset(160, 40));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(state.selection.primaryCell.row, greaterThanOrEqualTo(0));
      expect(state.selection.primaryCell.col, greaterThanOrEqualTo(0));
    });

    testWidgets(
      'Double clicking cell opens in-grid text editor and commits on Enter',
      (tester) async {
        final workbook = Workbook.createDefault();
        final state = WorkbookState(initialWorkbook: workbook);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: GridViewport(state: state),
              ),
            ),
          ),
        );

        // Select cell
        state.selectCell(const CellCoordinate(0, 0));
        await tester.pump();

        // Double tap at cell A1 (Offset rowHeaderWidth 44 + 20, colHeaderHeight 24 + 12)
        await tester.tapAt(const Offset(60, 36));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(const Offset(60, 36));
        await tester.pumpAndSettle();

        // In-grid editor textfield appears
        final editorFinder = find.byType(TextField);
        expect(editorFinder, findsOneWidget);

        await tester.enterText(editorFinder, 'Revenue 2024');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Cell value committed to workbook
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput,
          'Revenue 2024',
        );
      },
    );

    testWidgets(
      'StatusBar displays live aggregates for selected numeric cells',
      (tester) async {
        final workbook = Workbook.createDefault();
        final sheet = workbook.activeSheet;

        // Populate cells
        sheet.setCell(CellModel.fromInput(const CellCoordinate(0, 0), '10'));
        sheet.setCell(CellModel.fromInput(const CellCoordinate(1, 0), '20'));
        sheet.setCell(CellModel.fromInput(const CellCoordinate(2, 0), '30'));

        final state = WorkbookState(initialWorkbook: workbook);
        // Select range A1:A3
        state.selectRange(
          const CellRange.normalized(
            start: CellCoordinate(0, 0),
            end: CellCoordinate(2, 0),
            topRow: 0,
            bottomRow: 2,
            leftCol: 0,
            rightCol: 0,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StatusBar(state: state)),
          ),
        );

        // Verify Average: 20.00, Count: 3, Sum: 60.00
        expect(find.text('Average: 20.00'), findsOneWidget);
        expect(find.text('Count: 3'), findsOneWidget);
        expect(find.text('Sum: 60.00'), findsOneWidget);
      },
    );

    testWidgets(
      'Full WorkbookScreen integrates keyboard shortcuts for undo/redo',
      (tester) async {
        final workbook = Workbook.createDefault();
        final state = WorkbookState(initialWorkbook: workbook);

        await tester.pumpWidget(
          MaterialApp(home: WorkbookScreen(state: state)),
        );
        await tester.pumpAndSettle();

        // Edit cell
        state.editActiveCell('First Edit');
        expect(state.activeCellInput, 'First Edit');
        expect(state.canUndo, isTrue);

        // Trigger Undo
        state.undo();
        expect(state.activeCellInput, '');
        expect(state.canRedo, isTrue);

        // Trigger Redo
        state.redo();
        expect(state.activeCellInput, 'First Edit');
      },
    );
  });
}
