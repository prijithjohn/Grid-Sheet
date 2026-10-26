import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../app/state/workbook_state.dart';
import '../../domain/domain.dart';
import '../serialization/gsheet_format.dart';
import '../serialization/workbook_serializer.dart';

/// Information about a detected recovery journal file.
class RecoveryJournalInfo {
  final String journalPath;
  final String workbookId;
  final String? originalFilePath;
  final DateTime savedAt;
  final bool isDirty;

  const RecoveryJournalInfo({
    required this.journalPath,
    required this.workbookId,
    this.originalFilePath,
    required this.savedAt,
    required this.isDirty,
  });

  String get displayName {
    if (originalFilePath != null && originalFilePath!.isNotEmpty) {
      return p.basename(originalFilePath!);
    }
    return 'Untitled (Recovered)';
  }
}

/// Service managing periodic auto-save and crash recovery journals in local app cache.
class RecoveryService {
  final WorkbookSerializer serializer;
  final String? customRecoveryDir;
  final Duration autoSaveInterval;

  Timer? _autoSaveTimer;
  WorkbookState? _boundState;

  RecoveryService({
    WorkbookSerializer? serializer,
    this.customRecoveryDir,
    this.autoSaveInterval = const Duration(seconds: 60),
  }) : serializer = serializer ?? const WorkbookSerializer();

  /// Returns the directory used for storing recovery journals.
  Directory get recoveryDirectory {
    if (customRecoveryDir != null) {
      return Directory(customRecoveryDir!);
    }

    final String basePath;
    if (Platform.isWindows) {
      basePath =
          Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ??
          Directory.systemTemp.path;
    } else if (Platform.isMacOS) {
      basePath = p.join(
        Platform.environment['HOME'] ?? Directory.systemTemp.path,
        'Library',
        'Caches',
      );
    } else if (Platform.isLinux) {
      basePath =
          Platform.environment['XDG_CACHE_HOME'] ??
          p.join(
            Platform.environment['HOME'] ?? Directory.systemTemp.path,
            '.cache',
          );
    } else {
      basePath = Directory.systemTemp.path;
    }

    return Directory(p.join(basePath, 'GridSheet', 'recovery'));
  }

  /// Ensures the recovery directory exists.
  Future<void> init() async {
    final dir = recoveryDirectory;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Returns the file path for a workbook's recovery journal.
  String getJournalPath(String workbookId) {
    final sanitizedId = workbookId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return p.join(
      recoveryDirectory.path,
      'journal_$sanitizedId.$kGsheetExtension',
    );
  }

  /// Writes a write-ahead recovery journal for [workbook].
  Future<void> writeJournal(
    Workbook workbook, {
    String? originalFilePath,
    bool isDirty = true,
  }) async {
    await init();
    final journalPath = getJournalPath(workbook.id);
    final tmpPath = '$journalPath.tmp';

    final workbookJson = serializer.encode(workbook);
    final Map<String, dynamic> fullData;

    try {
      final decoded = jsonDecode(workbookJson) as Map<String, dynamic>;
      decoded[kKeyRecovery] = {
        kKeySourcePath: originalFilePath ?? '',
        kKeySavedAt: DateTime.now().toIso8601String(),
        kKeyDirty: isDirty,
        kKeyId: workbook.id,
      };
      fullData = decoded;
    } catch (_) {
      return;
    }

    final journalContent = jsonEncode(fullData);

    try {
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsString(journalContent, encoding: utf8, flush: true);

      final targetFile = File(journalPath);
      if (Platform.isWindows && await targetFile.exists()) {
        await targetFile.delete();
      }
      await tmpFile.rename(journalPath);
    } catch (_) {
      final tmpFile = File(tmpPath);
      if (await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Scans the recovery directory for existing recovery journal files.
  Future<List<RecoveryJournalInfo>> scanOrphanedJournals() async {
    final dir = recoveryDirectory;
    if (!await dir.exists()) return [];

    final list = <RecoveryJournalInfo>[];

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File &&
            entity.path.endsWith('.$kGsheetExtension') &&
            !entity.path.endsWith('.tmp')) {
          final info = await _readJournalInfo(entity.path);
          if (info != null) {
            list.add(info);
          }
        }
      }
    } catch (_) {}

    return list;
  }

  Future<RecoveryJournalInfo?> _readJournalInfo(String journalPath) async {
    try {
      final file = File(journalPath);
      if (!await file.exists()) return null;

      final content = await file.readAsString(encoding: utf8);
      final dynamic raw = jsonDecode(content);
      if (raw is! Map<String, dynamic>) return null;

      final recoveryMeta = raw[kKeyRecovery];
      if (recoveryMeta is! Map<String, dynamic>) return null;

      final sourcePath = recoveryMeta[kKeySourcePath] as String?;
      final savedAtStr = recoveryMeta[kKeySavedAt] as String?;
      final isDirty = recoveryMeta[kKeyDirty] as bool? ?? true;
      final workbookId =
          recoveryMeta[kKeyId] as String? ??
          p.basenameWithoutExtension(journalPath).replaceFirst('journal_', '');

      final savedAt = savedAtStr != null
          ? DateTime.tryParse(savedAtStr) ?? DateTime.now()
          : DateTime.now();

      return RecoveryJournalInfo(
        journalPath: journalPath,
        workbookId: workbookId,
        originalFilePath: (sourcePath == null || sourcePath.isEmpty)
            ? null
            : sourcePath,
        savedAt: savedAt,
        isDirty: isDirty,
      );
    } catch (_) {
      return null;
    }
  }

  /// Loads and reconstructs a [Workbook] from [journalPath].
  Future<Workbook> recoverWorkbook(String journalPath) async {
    final file = File(journalPath);
    if (!await file.exists()) {
      throw FileSystemException('Recovery journal not found', journalPath);
    }

    final content = await file.readAsString(encoding: utf8);
    return serializer.decode(content);
  }

  /// Deletes the recovery journal for [workbookId].
  Future<void> deleteJournal(String workbookId) async {
    final path = getJournalPath(workbookId);
    await deleteJournalByPath(path);
  }

  /// Deletes a recovery journal by its file path.
  Future<void> deleteJournalByPath(String journalPath) async {
    try {
      final file = File(journalPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Starts the periodic auto-save loop bound to [state].
  ///
  /// Every [autoSaveInterval], if [state.isDirty], writes a journal.
  void startAutoSave(WorkbookState state) {
    stopAutoSave();
    _boundState = state;
    _autoSaveTimer = Timer.periodic(autoSaveInterval, (_) {
      if (_boundState != null && _boundState!.isDirty) {
        writeJournal(
          _boundState!.workbook,
          originalFilePath: _boundState!.filePath,
          isDirty: true,
        );
      }
    });
  }

  /// Stops and cancels the background auto-save loop.
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _boundState = null;
  }

  /// Disposes of any resources and cancels timers.
  void dispose() {
    stopAutoSave();
  }
}
