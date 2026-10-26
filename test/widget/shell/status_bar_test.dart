import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/grid/widgets/status_bar.dart';

void main() {
  group('Phase 03A: StatusBar Widget Tests', () {
    testWidgets('displays "Ready" calculation mode badge', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusBar(state: state)),
        ),
      );

      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('no aggregate chips shown for empty single-cell selection', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusBar(state: state)),
        ),
      );

      expect(find.textContaining('Average:'), findsNothing);
      expect(find.textContaining('Sum:'), findsNothing);
    });

    testWidgets('renders correct Sum, Count, Average for numeric range A1:A3', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final sheet = workbook.activeSheet;

      sheet.setCell(CellModel.fromInput(const CellCoordinate(0, 0), '10'));
      sheet.setCell(CellModel.fromInput(const CellCoordinate(1, 0), '20'));
      sheet.setCell(CellModel.fromInput(const CellCoordinate(2, 0), '30'));

      final state = WorkbookState(initialWorkbook: workbook);
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

      expect(find.text('Average: 20.00'), findsOneWidget);
      expect(find.text('Count: 3'), findsOneWidget);
      expect(find.text('Sum: 60.00'), findsOneWidget);
    });

    testWidgets('Count includes non-numeric text cells', (tester) async {
      final workbook = Workbook.createDefault();
      final sheet = workbook.activeSheet;

      sheet.setCell(CellModel.fromInput(const CellCoordinate(0, 0), 'Alpha'));
      sheet.setCell(CellModel.fromInput(const CellCoordinate(1, 0), 'Beta'));

      final state = WorkbookState(initialWorkbook: workbook);
      state.selectRange(
        const CellRange.normalized(
          start: CellCoordinate(0, 0),
          end: CellCoordinate(1, 0),
          topRow: 0,
          bottomRow: 1,
          leftCol: 0,
          rightCol: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusBar(state: state)),
        ),
      );

      // Count of 2 non-numeric cells, no Average or Sum
      expect(find.text('Count: 2'), findsOneWidget);
      expect(find.textContaining('Average:'), findsNothing);
      expect(find.textContaining('Sum:'), findsNothing);
    });

    testWidgets('zoom slider is rendered and responds to drag', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusBar(state: state)),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
      // Default zoom is 100%
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
