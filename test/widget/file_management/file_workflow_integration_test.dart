import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/data/persistence/file_persistence_service.dart';
import 'package:grid_sheet/data/persistence/recent_files_service.dart';
import 'package:grid_sheet/data/persistence/recovery_service.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/file_management/file_management.dart';
import 'package:grid_sheet/features/workbook/screens/workbook_screen.dart';
import 'package:path/path.dart' as p;

class MockFilePersistenceService extends FilePersistenceService {
  String? mockOpenLocation;
  String? mockSaveLocation;
  Workbook? savedWorkbook;
  String? savedPath;

  @override
  Future<void> saveWorkbook(Workbook workbook, String filePath) async {
    savedWorkbook = workbook;
    savedPath = filePath;
  }

  @override
  Future<Workbook> loadWorkbook(String filePath) async {
    return Workbook.createDefault(title: p.basename(filePath));
  }

  @override
  Future<String?> pickOpenLocation({String? initialDirectory}) async {
    return mockOpenLocation;
  }

  @override
  Future<String?> pickSaveLocation({
    String? suggestedName,
    String? initialDirectory,
    Uint8List? bytes,
  }) async {
    return mockSaveLocation;
  }
}

void main() {
  group('File Workflow Integration Widget Tests', () {
    late Directory tempDir;
    late MockFilePersistenceService mockPersistence;
    late RecoveryService recoveryService;
    late RecentFilesService recentFilesService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gsheet_ui_test_');
      mockPersistence = MockFilePersistenceService();
      recoveryService = RecoveryService(customRecoveryDir: tempDir.path);
      recentFilesService = RecentFilesService(
        customStoragePath: p.join(tempDir.path, 'recent_ui.json'),
      );
    });

    tearDown(() async {
      recoveryService.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets(
      'Quick Access Save button in title bar saves and clears dirty state',
      (tester) async {
        final wb = Workbook.createDefault(title: 'ActiveDoc.gsheet');
        final state = WorkbookState(
          initialWorkbook: wb,
          filePath: p.join(tempDir.path, 'ActiveDoc.gsheet'),
        );

        final controller = FileWorkflowController(
          state: state,
          persistenceService: mockPersistence,
          recoveryService: recoveryService,
          recentFilesService: recentFilesService,
          enableAutoSave: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: WorkbookScreen(state: state, fileController: controller),
          ),
        );

        expect(state.isDirty, isFalse);
        expect(find.byKey(const Key('dirty_indicator')), findsNothing);

        // Mutate a cell to mark as dirty
        state.editActiveCell('Dirty Value');
        await tester.pump();

        expect(state.isDirty, isTrue);
        expect(find.byKey(const Key('dirty_indicator')), findsOneWidget);

        // Tap quick access save button in WindowTitleBar
        expect(find.byKey(const Key('quick_save_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('quick_save_button')));
        await tester.pump();

        expect(
          mockPersistence.savedPath,
          equals(p.join(tempDir.path, 'ActiveDoc.gsheet')),
        );
        expect(state.isDirty, isFalse);
        expect(find.byKey(const Key('dirty_indicator')), findsNothing);
      },
    );

    testWidgets(
      'Ribbon File tab renders New, Open, Save, and Save As buttons',
      (tester) async {
        final state = WorkbookState(
          filePath: p.join(tempDir.path, 'Test.gsheet'),
        );
        final controller = FileWorkflowController(
          state: state,
          persistenceService: mockPersistence,
          recoveryService: recoveryService,
          recentFilesService: recentFilesService,
          enableAutoSave: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: WorkbookScreen(state: state, fileController: controller),
          ),
        );

        // Initially on Home tab, tap File tab header
        await tester.tap(find.text('File'));
        await tester.pumpAndSettle();

        // Verify ribbon action panel contains file actions
        expect(find.byKey(const Key('ribbon_file_new_button')), findsOneWidget);
        expect(
          find.byKey(const Key('ribbon_file_open_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('ribbon_file_save_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('ribbon_file_save_as_button')),
          findsOneWidget,
        );

        // Tap Save button from Ribbon
        state.editActiveCell('Edited via Ribbon');
        expect(state.isDirty, isTrue);

        await tester.tap(find.byKey(const Key('ribbon_file_save_button')));
        await tester.pump();

        expect(state.isDirty, isFalse);
      },
    );

    testWidgets('Ctrl+S shortcut triggers save', (tester) async {
      final state = WorkbookState(
        filePath: p.join(tempDir.path, 'ShortcutDoc.gsheet'),
      );
      final controller = FileWorkflowController(
        state: state,
        persistenceService: mockPersistence,
        recoveryService: recoveryService,
        recentFilesService: recentFilesService,
        enableAutoSave: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkbookScreen(state: state, fileController: controller),
        ),
      );

      state.editActiveCell('Needs Save');
      expect(state.isDirty, isTrue);

      // Send Ctrl+S
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(state.isDirty, isFalse);
      expect(
        mockPersistence.savedPath,
        equals(p.join(tempDir.path, 'ShortcutDoc.gsheet')),
      );
    });

    testWidgets(
      'Opening new file with unsaved changes prompts UnsavedChangesDialog',
      (tester) async {
        final state = WorkbookState(
          filePath: p.join(tempDir.path, 'Existing.gsheet'),
        );
        final controller = FileWorkflowController(
          state: state,
          persistenceService: mockPersistence,
          recoveryService: recoveryService,
          recentFilesService: recentFilesService,
          enableAutoSave: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: WorkbookScreen(state: state, fileController: controller),
          ),
        );

        // Make dirty
        state.editActiveCell('Unsaved Work');
        expect(state.isDirty, isTrue);

        // Switch to File tab and tap New
        await tester.tap(find.text('File'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('ribbon_file_new_button')));
        await tester.pumpAndSettle();

        // Dialog is shown
        expect(find.byKey(const Key('unsaved_changes_dialog')), findsOneWidget);

        // Choose "Don't Save" to discard and proceed
        await tester.tap(
          find.byKey(const Key('unsaved_changes_discard_button')),
        );
        await tester.pumpAndSettle();

        // Should have created a fresh new workbook
        expect(find.byKey(const Key('unsaved_changes_dialog')), findsNothing);
        expect(state.isDirty, isFalse);
        expect(state.filePath, isNull);
      },
    );
  });
}
