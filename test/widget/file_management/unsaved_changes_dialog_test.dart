import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/features/file_management/file_management.dart';

void main() {
  group('UnsavedChangesDialog Widget Tests', () {
    testWidgets('renders dialog with document name and warning', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnsavedChangesDialog(fileName: 'Expenses 2024.gsheet'),
          ),
        ),
      );

      expect(find.byKey(const Key('unsaved_changes_dialog')), findsOneWidget);
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.textContaining('Expenses 2024.gsheet'), findsOneWidget);
      expect(
        find.byKey(const Key('unsaved_changes_save_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('unsaved_changes_discard_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('unsaved_changes_cancel_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Save button returns UnsavedChangesAction.save', (
      tester,
    ) async {
      UnsavedChangesAction? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await UnsavedChangesDialog.show(
                    context,
                    fileName: 'Budget.gsheet',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unsaved_changes_dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('unsaved_changes_save_button')));
      await tester.pumpAndSettle();

      expect(result, equals(UnsavedChangesAction.save));
      expect(find.byKey(const Key('unsaved_changes_dialog')), findsNothing);
    });

    testWidgets(
      'tapping Don\'t Save button returns UnsavedChangesAction.discard',
      (tester) async {
        UnsavedChangesAction? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await UnsavedChangesDialog.show(
                      context,
                      fileName: 'Budget.gsheet',
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('unsaved_changes_discard_button')),
        );
        await tester.pumpAndSettle();

        expect(result, equals(UnsavedChangesAction.discard));
        expect(find.byKey(const Key('unsaved_changes_dialog')), findsNothing);
      },
    );

    testWidgets('tapping Cancel button returns UnsavedChangesAction.cancel', (
      tester,
    ) async {
      UnsavedChangesAction? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await UnsavedChangesDialog.show(
                    context,
                    fileName: 'Budget.gsheet',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('unsaved_changes_cancel_button')));
      await tester.pumpAndSettle();

      expect(result, equals(UnsavedChangesAction.cancel));
      expect(find.byKey(const Key('unsaved_changes_dialog')), findsNothing);
    });
  });
}
