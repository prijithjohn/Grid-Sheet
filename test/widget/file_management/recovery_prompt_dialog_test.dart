import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/data/persistence/recovery_service.dart';
import 'package:grid_sheet/features/file_management/file_management.dart';

void main() {
  group('RecoveryPromptDialog Widget Tests', () {
    final testInfo = RecoveryJournalInfo(
      journalPath: 'C:\\path\\journal_test.gsheet',
      workbookId: 'wb_123',
      originalFilePath: 'C:\\Users\\User\\Documents\\Quarterly.gsheet',
      savedAt: DateTime(2026, 10, 26, 14, 30),
      isDirty: true,
    );

    testWidgets('renders recovery prompt dialog details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RecoveryPromptDialog(info: testInfo)),
        ),
      );

      expect(find.byKey(const Key('recovery_prompt_dialog')), findsOneWidget);
      expect(find.text('Document Recovery'), findsOneWidget);
      expect(find.textContaining('Quarterly.gsheet'), findsOneWidget);
      expect(find.textContaining('2026-10-26 14:30'), findsOneWidget);
      expect(find.byKey(const Key('recovery_restore_button')), findsOneWidget);
      expect(find.byKey(const Key('recovery_discard_button')), findsOneWidget);
    });

    testWidgets('tapping Restore returns RecoveryAction.restore', (
      tester,
    ) async {
      RecoveryAction? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await RecoveryPromptDialog.show(
                    context,
                    info: testInfo,
                  );
                },
                child: const Text('Show Prompt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Prompt'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recovery_restore_button')));
      await tester.pumpAndSettle();

      expect(result, equals(RecoveryAction.restore));
      expect(find.byKey(const Key('recovery_prompt_dialog')), findsNothing);
    });

    testWidgets('tapping Discard returns RecoveryAction.discard', (
      tester,
    ) async {
      RecoveryAction? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await RecoveryPromptDialog.show(
                    context,
                    info: testInfo,
                  );
                },
                child: const Text('Show Prompt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Prompt'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recovery_discard_button')));
      await tester.pumpAndSettle();

      expect(result, equals(RecoveryAction.discard));
      expect(find.byKey(const Key('recovery_prompt_dialog')), findsNothing);
    });
  });
}
