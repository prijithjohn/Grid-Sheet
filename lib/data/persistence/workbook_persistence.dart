import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/domain.dart';
import '../serialization/gsheet_format.dart';
import '../serialization/workbook_serializer.dart';

/// Result of a persistence save operation.
class PersistenceResult {
  final bool success;
  final String? errorMessage;

  const PersistenceResult.success() : success = true, errorMessage = null;
  const PersistenceResult.failure(this.errorMessage) : success = false;
}

/// Result of a workbook load operation.
class LoadResult {
  final Workbook? workbook;
  final String? errorMessage;

  const LoadResult.success(this.workbook) : errorMessage = null;
  const LoadResult.failure(this.errorMessage) : workbook = null;
}

/// Metadata about a pending recovery file.
class RecoveryInfo {
  /// Absolute path of the recovery file on disk.
  final String recoveryPath;

  /// The original file path this recovery is for (null = unsaved new workbook).
  final String? sourcePath;

  /// When the recovery snapshot was written.
  final DateTime savedAt;

  /// Whether the workbook had unsaved changes when the snapshot was taken.
  final bool isDirty;

  const RecoveryInfo({
    required this.recoveryPath,
    this.sourcePath,
    required this.savedAt,
    required this.isDirty,
  });

  bool get hasSourcePath => sourcePath != null && sourcePath!.isNotEmpty;
}

/// Low-level workbook file I/O service.
///
/// Responsibilities:
/// - Safe atomic save (write-to-temp → rename).
/// - Load with validation and descriptive error messages.
/// - Recovery file creation, metadata reading, and cleanup.
class WorkbookPersistence {
  WorkbookPersistence({WorkbookSerializer? serializer})
    : _serializer = serializer ?? const WorkbookSerializer();

  final WorkbookSerializer _serializer;

  /// The serializer used by this persistence layer.
  WorkbookSerializer get serializer => _serializer;

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// Saves [workbook] to [filePath] using a safe temp-file → rename strategy.
  ///
  /// Writes to `<filePath>.tmp`, flushes, then renames to [filePath].
  /// On failure, cleans up the temp file and returns a [PersistenceResult.failure].
  Future<PersistenceResult> save(Workbook workbook, String filePath) async {
    final tmpPath = '$filePath.tmp';
    try {
      // Ensure parent directory exists
      final dir = File(filePath).parent;
      if (!await dir.exists()) await dir.create(recursive: true);

      final content = _serializer.encode(workbook);
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsString(content, encoding: utf8, flush: true);
      await tmpFile.rename(filePath);
      return const PersistenceResult.success();
    } catch (e) {
      // Best-effort cleanup
      try {
        final tmp = File(tmpPath);
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      return PersistenceResult.failure('Failed to save file: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Loads a [Workbook] from [filePath].
  ///
  /// Never throws — returns [LoadResult.failure] on any error.
  Future<LoadResult> load(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return LoadResult.failure('File not found: $filePath');
      }
      final content = await file.readAsString(encoding: utf8);
      final workbook = _serializer.decode(content);
      return LoadResult.success(workbook);
    } on WorkbookLoadException catch (e) {
      return LoadResult.failure(e.message);
    } catch (e) {
      return LoadResult.failure('Cannot read file: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Recovery
  // ---------------------------------------------------------------------------

  /// Returns the expected recovery file path for a given workbook.
  ///
  /// [recoveryDir] is the directory where recovery files are stored.
  /// [sourceFilePath] is the current save path (null/empty for unsaved workbooks).
  /// [workbookId] is used as a fallback identifier.
  String getRecoveryPath(
    String recoveryDir, {
    String? sourceFilePath,
    required String workbookId,
  }) {
    if (sourceFilePath != null && sourceFilePath.isNotEmpty) {
      final base = p.basenameWithoutExtension(sourceFilePath);
      // Sanitize to safe filename characters
      final sanitized = base.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      return p.join(recoveryDir, '.$sanitized.recovery.$kGsheetExtension');
    }
    final idPart = workbookId.length > 8
        ? workbookId.substring(0, 8)
        : workbookId;
    return p.join(recoveryDir, '.$idPart.recovery.$kGsheetExtension');
  }

  /// Writes a recovery snapshot of [workbook] to [recoveryFilePath].
  ///
  /// The recovery file is a valid `.gsheet` file with an additional top-level
  /// `"recovery"` metadata object injected.
  Future<PersistenceResult> writeRecovery(
    Workbook workbook,
    String recoveryFilePath, {
    String? sourceFilePath,
  }) async {
    try {
      final dir = File(recoveryFilePath).parent;
      if (!await dir.exists()) await dir.create(recursive: true);

      final baseJson = _serializer.encode(workbook);
      final content = _injectRecoveryMeta(
        baseJson,
        sourceFilePath: sourceFilePath,
        savedAt: DateTime.now(),
      );
      await File(recoveryFilePath)
          .writeAsString(content, encoding: utf8, flush: true);
      return const PersistenceResult.success();
    } catch (e) {
      return PersistenceResult.failure('Recovery write failed: $e');
    }
  }

  /// Reads recovery metadata from [recoveryFilePath] without fully parsing the workbook.
  ///
  /// Returns `null` if the file does not exist, cannot be read, or contains no
  /// recovery metadata block.
  Future<RecoveryInfo?> readRecoveryInfo(String recoveryFilePath) async {
    try {
      final file = File(recoveryFilePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString(encoding: utf8);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;

      final meta = decoded[kKeyRecovery];
      if (meta is! Map<String, dynamic>) return null;

      final sourcePath = meta[kKeySourcePath] as String?;
      final savedAtStr = meta[kKeySavedAt] as String?;
      final isDirty = meta[kKeyDirty] as bool? ?? true;

      final savedAt = savedAtStr != null
          ? DateTime.tryParse(savedAtStr) ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);

      return RecoveryInfo(
        recoveryPath: recoveryFilePath,
        sourcePath: (sourcePath == null || sourcePath.isEmpty)
            ? null
            : sourcePath,
        savedAt: savedAt,
        isDirty: isDirty,
      );
    } catch (_) {
      return null;
    }
  }

  /// Loads the workbook from a recovery file (same format as regular save).
  Future<LoadResult> loadRecovery(String recoveryFilePath) =>
      load(recoveryFilePath);

  /// Deletes the recovery file at [recoveryFilePath] if it exists.
  Future<void> deleteRecovery(String recoveryFilePath) async {
    try {
      final file = File(recoveryFilePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _injectRecoveryMeta(
    String baseJson, {
    String? sourceFilePath,
    required DateTime savedAt,
  }) {
    try {
      final decoded = jsonDecode(baseJson);
      if (decoded is Map<String, dynamic>) {
        decoded[kKeyRecovery] = {
          kKeySourcePath: sourceFilePath ?? '',
          kKeySavedAt: savedAt.toIso8601String(),
          kKeyDirty: true,
        };
        return jsonEncode(decoded);
      }
    } catch (_) {}
    return baseJson;
  }
}
