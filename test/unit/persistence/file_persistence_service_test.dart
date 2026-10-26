import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/data/persistence/file_persistence_service.dart';
import 'package:grid_sheet/data/persistence/recent_files_service.dart';
import 'package:grid_sheet/data/serialization/workbook_serializer.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FilePersistenceService and RecentFilesService Tests', () {
    late Directory tempDir;
    late FilePersistenceService fileService;
    late RecentFilesService recentFilesService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gsheet_file_test_');
      fileService = FilePersistenceService();
      recentFilesService = RecentFilesService(
        customStoragePath: p.join(tempDir.path, 'recent_test.json'),
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves and loads workbook with atomic file writing', () async {
      final targetPath = p.join(tempDir.path, 'test_workbook.gsheet');
      final wb = Workbook.createDefault(title: 'Atomic Test.gsheet');
      final sheet = wb.activeSheet;
      sheet.setCell(
        Cell.fromInput(const CellCoordinate(0, 0), 'Atomic Header'),
      );
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), '=SUM(10, 20)'));

      // Save workbook
      await fileService.saveWorkbook(wb, targetPath);

      // Verify file exists on disk and no temporary .tmp file is left
      final file = File(targetPath);
      final tmpFile = File('$targetPath.tmp');
      expect(await file.exists(), isTrue);
      expect(await tmpFile.exists(), isFalse);

      // Load workbook
      final loadedWb = await fileService.loadWorkbook(targetPath);
      expect(loadedWb.title, equals('Atomic Test.gsheet'));
      expect(
        loadedWb.activeSheet.getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Atomic Header'),
      );
      expect(
        loadedWb.activeSheet.getCell(const CellCoordinate(1, 0))?.rawInput,
        equals('=SUM(10, 20)'),
      );
    });

    test('throws FileSystemException when loading non-existent file', () async {
      final nonExistent = p.join(tempDir.path, 'ghost.gsheet');
      expect(
        () => fileService.loadWorkbook(nonExistent),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws WorkbookLoadException when loading corrupted file', () async {
      final corruptPath = p.join(tempDir.path, 'corrupted.gsheet');
      await File(corruptPath).writeAsString('{ "corrupt": true }');

      expect(
        () => fileService.loadWorkbook(corruptPath),
        throwsA(isA<WorkbookLoadException>()),
      );
    });

    test(
      'RecentFilesService tracks, dedupes, and trims recent file entries',
      () async {
        final f1 = p.join(tempDir.path, 'file1.gsheet');
        final f2 = p.join(tempDir.path, 'file2.gsheet');
        final f3 = p.join(tempDir.path, 'file3.gsheet');

        expect(await recentFilesService.getRecentFiles(), isEmpty);

        await recentFilesService.addRecentFile(f1);
        await recentFilesService.addRecentFile(f2);
        expect(await recentFilesService.getRecentFiles(), equals([f2, f1]));

        // Adding f1 again should dedupe and move it to the front
        await recentFilesService.addRecentFile(f1);
        expect(await recentFilesService.getRecentFiles(), equals([f1, f2]));

        await recentFilesService.addRecentFile(f3);
        expect(await recentFilesService.getRecentFiles(), equals([f3, f1, f2]));

        // Remove an entry
        await recentFilesService.removeRecentFile(f1);
        expect(await recentFilesService.getRecentFiles(), equals([f3, f2]));

        // Clear all
        await recentFilesService.clearRecentFiles();
        expect(await recentFilesService.getRecentFiles(), isEmpty);
      },
    );
  });
}
