import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/data/persistence/recovery_service.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('RecoveryService Tests', () {
    late Directory tempDir;
    late RecoveryService recoveryService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gsheet_recovery_test_');
      recoveryService = RecoveryService(
        customRecoveryDir: tempDir.path,
        autoSaveInterval: const Duration(milliseconds: 100),
      );
      await recoveryService.init();
    });

    tearDown(() async {
      recoveryService.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes and detects crash recovery journals', () async {
      final wb = Workbook.createDefault(title: 'Critical Report.gsheet');
      wb.activeSheet.setCell(
        Cell.fromInput(const CellCoordinate(0, 0), 'Unsaved Financial Data'),
      );

      // Initially no journals exist
      var journals = await recoveryService.scanOrphanedJournals();
      expect(journals, isEmpty);

      // Write crash recovery journal
      await recoveryService.writeJournal(
        wb,
        originalFilePath: 'C:\\Users\\Accountant\\Critical Report.gsheet',
        isDirty: true,
      );

      // Scan should now detect the journal
      journals = await recoveryService.scanOrphanedJournals();
      expect(journals.length, equals(1));

      final info = journals.first;
      expect(info.workbookId, equals(wb.id));
      expect(info.displayName, equals('Critical Report.gsheet'));
      expect(info.isDirty, isTrue);
      expect(
        info.originalFilePath,
        equals('C:\\Users\\Accountant\\Critical Report.gsheet'),
      );
      expect(
        info.savedAt.isBefore(DateTime.now().add(const Duration(seconds: 1))),
        isTrue,
      );

      // Recover workbook from journal
      final recoveredWb = await recoveryService.recoverWorkbook(
        info.journalPath,
      );
      expect(recoveredWb.title, equals('Critical Report.gsheet'));
      expect(
        recoveredWb.activeSheet.getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Unsaved Financial Data'),
      );

      // Delete journal on clean save/discard
      await recoveryService.deleteJournal(wb.id);
      journals = await recoveryService.scanOrphanedJournals();
      expect(journals, isEmpty);
    });

    test('handles fallback display name for untitled journals', () async {
      final wb = Workbook.createDefault();
      wb.activeSheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '123'));

      await recoveryService.writeJournal(wb, isDirty: true);

      final journals = await recoveryService.scanOrphanedJournals();
      expect(journals.length, equals(1));
      expect(journals.first.displayName, equals('Untitled (Recovered)'));
      expect(journals.first.originalFilePath, isNull);
    });

    test(
      'background auto-save writes journal only when state is dirty',
      () async {
        final wb = Workbook.createDefault(title: 'AutoSaveTest.gsheet');
        final state = WorkbookState(initialWorkbook: wb);

        recoveryService.startAutoSave(state);

        // 1. Wait a bit while state is clean (isDirty == false)
        await Future.delayed(const Duration(milliseconds: 150));
        var journals = await recoveryService.scanOrphanedJournals();
        expect(journals, isEmpty);

        // 2. Mutate state so isDirty == true
        state.editActiveCell('AutoSaved Value');
        expect(state.isDirty, isTrue);

        // Wait for auto-save interval to fire
        await Future.delayed(const Duration(milliseconds: 250));
        journals = await recoveryService.scanOrphanedJournals();
        expect(journals.length, equals(1));

        final recovered = await recoveryService.recoverWorkbook(
          journals.first.journalPath,
        );
        expect(
          recovered.activeSheet.getCell(state.selection.primaryCell)?.rawInput,
          equals('AutoSaved Value'),
        );

        // 3. Mark clean and ensure deleting journal works
        state.markClean();
        await recoveryService.deleteJournal(wb.id);
        expect(await recoveryService.scanOrphanedJournals(), isEmpty);
      },
    );
  });
}
