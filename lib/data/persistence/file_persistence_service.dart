import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../domain/domain.dart';
import '../serialization/gsheet_format.dart';
import '../serialization/workbook_serializer.dart';

/// Service responsible for file-level operations, atomic persistence,
/// and file dialog picker interactions for `.gsheet` workbooks.
class FilePersistenceService {
  final WorkbookSerializer serializer;

  FilePersistenceService({WorkbookSerializer? serializer})
    : serializer = serializer ?? const WorkbookSerializer();

  /// Saves [workbook] to [filePath] atomically using a write-to-temp and rename strategy.
  ///
  /// Prevents file corruption in case of crash, power loss, or write failures.
  Future<void> saveWorkbook(Workbook workbook, String filePath) async {
    final tmpPath = '$filePath.tmp';
    final targetFile = File(filePath);
    final tmpFile = File(tmpPath);

    // Ensure directory exists
    final parentDir = targetFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final jsonString = serializer.encode(workbook);

    try {
      // 1. Write to temporary file with flush
      await tmpFile.writeAsString(jsonString, encoding: utf8, flush: true);

      // 2. Atomically rename/replace target file
      // On Windows File.rename can fail if the destination exists, so we handle replace
      if (Platform.isWindows && await targetFile.exists()) {
        await targetFile.delete();
      }
      await tmpFile.rename(filePath);
    } catch (e) {
      // Clean up temp file on failure
      if (await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Loads a [Workbook] from [filePath].
  ///
  /// Throws [FileSystemException] if file doesn't exist,
  /// or [WorkbookLoadException] if the file format or schema is invalid.
  Future<Workbook> loadWorkbook(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final content = await file.readAsString(encoding: utf8);
    return serializer.decode(content);
  }

  /// Displays the native file picker to pick a `.gsheet` file to open.
  ///
  /// Returns the selected file path, or `null` if the user cancelled.
  Future<String?> pickOpenLocation({String? initialDirectory}) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Open Grid Sheet Workbook',
        type: FileType.custom,
        allowedExtensions: [kGsheetExtension],
        initialDirectory: initialDirectory,
      );

      if (result.isNotEmpty && result.first.path != null) {
        return result.first.path;
      }
    } catch (_) {
      // Return null if file picker cannot be displayed (e.g. headless test environment)
    }
    return null;
  }

  /// Displays the native file picker to select a location to save a `.gsheet` file.
  ///
  /// Returns the target file path, or `null` if the user cancelled.
  Future<String?> pickSaveLocation({
    String? suggestedName,
    String? initialDirectory,
    Uint8List? bytes,
  }) async {
    try {
      var fileName = suggestedName ?? 'Untitled.$kGsheetExtension';
      if (!fileName.toLowerCase().endsWith('.$kGsheetExtension')) {
        fileName = '$fileName.$kGsheetExtension';
      }

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save Workbook As',
        fileName: fileName,
        bytes: bytes ?? Uint8List(0),
        initialDirectory: initialDirectory,
      );

      if (uri != null) {
        var path = uri.toFilePath();
        if (!path.toLowerCase().endsWith('.$kGsheetExtension')) {
          path = '$path.$kGsheetExtension';
        }
        return path;
      }
    } catch (_) {
      // Return null if file picker cannot be displayed (e.g. headless test environment)
    }
    return null;
  }
}
