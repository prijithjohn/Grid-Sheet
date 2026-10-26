import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/workbook/widgets/window_title_bar.dart';

void main() {
  group('Phase 03A: WindowTitleBar Widget Tests', () {
    WorkbookState makeState({String title = 'TestFile.gsheet'}) {
      final workbook = Workbook.createDefault(title: title);
      return WorkbookState(initialWorkbook: workbook);
    }

    testWidgets('renders application title and file name', (tester) async {
      final state = makeState(title: 'Q1_Financials.gsheet');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WindowTitleBar(state: state)),
        ),
      );

      expect(find.text('Grid Sheet'), findsOneWidget);
      expect(find.text('Q1_Financials.gsheet'), findsOneWidget);
    });

    testWidgets('dirty indicator hidden when state is clean', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WindowTitleBar(state: state)),
        ),
      );

      expect(state.isDirty, isFalse);
      expect(find.byKey(const Key('dirty_indicator')), findsNothing);
    });

    testWidgets('dirty indicator shown when WorkbookState.isDirty == true', (
      tester,
    ) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WindowTitleBar(state: state)),
        ),
      );

      // Mutate to make dirty
      state.editCellAt(const CellCoordinate(0, 0), 'Hello');
      await tester.pump();

      expect(state.isDirty, isTrue);
      expect(find.byKey(const Key('dirty_indicator')), findsOneWidget);
    });

    testWidgets('dirty indicator disappears after markClean', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WindowTitleBar(state: state)),
        ),
      );

      state.editCellAt(const CellCoordinate(0, 0), 'Hello');
      await tester.pump();
      expect(find.byKey(const Key('dirty_indicator')), findsOneWidget);

      state.markClean();
      await tester.pump();
      expect(find.byKey(const Key('dirty_indicator')), findsNothing);
    });

    testWidgets('renders minimize, maximize and close caption buttons', (
      tester,
    ) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WindowTitleBar(state: state)),
        ),
      );

      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.crop_square), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('caption button callbacks fire when tapped', (tester) async {
      final state = makeState();
      bool minimizeFired = false;
      bool closeFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WindowTitleBar(
              state: state,
              onMinimize: () => minimizeFired = true,
              onClose: () => closeFired = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(minimizeFired, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closeFired, isTrue);
    });
  });
}
