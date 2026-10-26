import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../domain/domain.dart';
import 'workbook_persistence.dart';

/// High-level result of a user-facing file operation.
enum FileOperationStatus {
  /// Operation completed successfully.
  success,

  /// User cancelled (no-op, no state change).
  cancelled,

  /// A file error occurred; [FileOperationResult.errorMessage] is set.
  error,
}

/// Result of a user-facing save or open operation.
class FileOperationResult {
  final FileOperationStatus status;
  final String? savedPath;
  final Workbook? loadedWorkbook;
  final String? errorMessage;

  const FileOperationResult.success({this.savedPath, this.loadedWorkbook})
    : status = FileOperationStatus.success,
      errorMessage = null;

  const FileOperationResult.cancelled()
    : status = FileOperationStatus.cancelled,
      savedPath = null,
      loadedWorkbook = null,
      errorMessage = null;

  const FileOperationResult.error(this.errorMessage)
    : status = FileOperationStatus.error,
      savedPath = null,
      loadedWorkbook = null;

  bool get isSuccess => status == FileOperationStatus.success;
  bool get isCancelled => status == FileOperationStatus.cancelled;
  bool get isError => status == FileOperationStatus.error;
}

/// High-level workbook file operations service.
///
/// Orchestrates:
/// - Save, Save As, and Open with native file picker dialogs.
/// - Safe overwrite via [WorkbookPersistence].
/// - Autosave / recovery file management.
class WorkbookFileService {
  WorkbookFileService({WorkbookPersistence? persistence})
    : _persistence = persistence ?? WorkbookPersistence();

  final WorkbookPersistence _persistence;

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// Saves [workbook] to [currentFilePath] without showing a picker dialog.
  ///
  /// Returns [FileOperationResult.error] if [currentFilePath] is null/empty.
  Future<FileOperationResult> save(
    Workbook workbook,
    String? currentFilePath,
  ) async {
    if (currentFilePath == null || currentFilePath.isEmpty) {
      return const FileOperationResult.error(
        'No current file path — use Save As.',
      );
    }
    final result = await _persistence.save(workbook, currentFilePath);
    if (result.success) {
      return FileOperationResult.success(savedPath: currentFilePath);
    }
    return FileOperationResult.error(result.errorMessage);
  }

  /// Saves [workbook] to a user-selected path using a native file picker dialog.
  ///
  /// Pre-populates the picker with [suggestedName] if provided.
  /// Returns [FileOperationResult.cancelled] if the user dismisses the dialog.
  Future<FileOperationResult> saveAs(
    Workbook workbook, {
    String? suggestedName,
    String? initialDirectory,
  }) async {
    String? outputPath;
    try {
      final jsonString = _persistence.serializer.encode(workbook);
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save Workbook',
        fileName: suggestedName ?? 'Untitled.gsheet',
        bytes: Uint8List.fromList(utf8.encode(jsonString)),
        initialDirectory: initialDirectory,
      );
      if (uri != null) {
        outputPath = uri.toFilePath();
      }
    } catch (_) {
      // FilePicker not available in test environment — fall through
    }

    if (outputPath == null) return const FileOperationResult.cancelled();

    // Ensure correct extension
    if (!outputPath.toLowerCase().endsWith('.gsheet')) {
      outputPath = '$outputPath.gsheet';
    }

    final result = await _persistence.save(workbook, outputPath);
    if (result.success) {
      return FileOperationResult.success(savedPath: outputPath);
    }
    return FileOperationResult.error(result.errorMessage);
  }

  // ---------------------------------------------------------------------------
  // Open
  // ---------------------------------------------------------------------------

  /// Opens a workbook from [filePath] directly (no picker dialog).
  ///
  /// Returns the loaded [Workbook] or a descriptive error.
  Future<FileOperationResult> openFromPath(String filePath) async {
    final result = await _persistence.load(filePath);
    if (result.workbook != null) {
      return FileOperationResult.success(
        savedPath: filePath,
        loadedWorkbook: result.workbook,
      );
    }
    return FileOperationResult.error(result.errorMessage);
  }

  /// Shows a native file picker and opens the selected workbook.
  ///
  /// Returns [FileOperationResult.cancelled] if the user dismisses the dialog.
  /// Returns [FileOperationResult.error] if the file cannot be loaded.
  /// Never replaces current workbook on failure.
  Future<FileOperationResult> openWithPicker({String? initialDirectory}) async {
    List<PlatformFile> picked = [];
    try {
      picked = await FilePicker.pickFiles(
        dialogTitle: 'Open Workbook',
        type: FileType.custom,
        allowedExtensions: ['gsheet'],
        initialDirectory: initialDirectory,
      );
    } catch (_) {
      // FilePicker not available in test environment
    }

    if (picked.isEmpty) {
      return const FileOperationResult.cancelled();
    }

    final filePath = picked.first.path;
    if (filePath == null) {
      return const FileOperationResult.error(
        'Could not read selected file path',
      );
    }

    return openFromPath(filePath);
  }

  // ---------------------------------------------------------------------------
  // Recovery
  // ---------------------------------------------------------------------------

  /// Returns the recovery directory for the current platform.
  ///
  /// Uses a `recovery` subdirectory alongside the workbook file if possible,
  /// otherwise falls back to a temp directory.
  String getRecoveryDir({String? currentFilePath}) {
    if (currentFilePath != null && currentFilePath.isNotEmpty) {
      return p.join(p.dirname(currentFilePath), '.gsheet_recovery');
    }
    return p.join(
      Platform.isWindows
          ? (Platform.environment['LOCALAPPDATA'] ??
                Platform.environment['TEMP'] ??
                Directory.systemTemp.path)
          : Directory.systemTemp.path,
      'gsheet_recovery',
    );
  }

  /// Writes a recovery snapshot for [workbook].
  Future<void> writeRecovery(
    Workbook workbook, {
    String? currentFilePath,
  }) async {
    final recoveryDir = getRecoveryDir(currentFilePath: currentFilePath);
    final recoveryFilePath = _persistence.getRecoveryPath(
      recoveryDir,
      sourceFilePath: currentFilePath,
      workbookId: workbook.id,
    );
    await _persistence.writeRecovery(
      workbook,
      recoveryFilePath,
      sourceFilePath: currentFilePath,
    );
  }

  /// Checks whether a recovery file exists for [currentFilePath] (or workbook id).
  Future<RecoveryInfo?> checkForRecovery(
    Workbook workbook, {
    String? currentFilePath,
  }) async {
    final recoveryDir = getRecoveryDir(currentFilePath: currentFilePath);
    final recoveryFilePath = _persistence.getRecoveryPath(
      recoveryDir,
      sourceFilePath: currentFilePath,
      workbookId: workbook.id,
    );
    final info = await _persistence.readRecoveryInfo(recoveryFilePath);
    if (info == null) return null;
    // Return info with the full recovery path filled in
    return RecoveryInfo(
      recoveryPath: recoveryFilePath,
      sourcePath: info.sourcePath,
      savedAt: info.savedAt,
      isDirty: info.isDirty,
    );
  }

  /// Loads the workbook from a recovery file at [recoveryFilePath].
  Future<FileOperationResult> loadRecovery(String recoveryFilePath) async {
    final result = await _persistence.loadRecovery(recoveryFilePath);
    if (result.workbook != null) {
      return FileOperationResult.success(loadedWorkbook: result.workbook);
    }
    return FileOperationResult.error(result.errorMessage);
  }

  /// Deletes the recovery file for [workbook].
  Future<void> discardRecovery(
    Workbook workbook, {
    String? currentFilePath,
  }) async {
    final recoveryDir = getRecoveryDir(currentFilePath: currentFilePath);
    final recoveryFilePath = _persistence.getRecoveryPath(
      recoveryDir,
      sourceFilePath: currentFilePath,
      workbookId: workbook.id,
    );
    await _persistence.deleteRecovery(recoveryFilePath);
  }
}
