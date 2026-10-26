import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Service managing recent files list persisted to local application storage.
class RecentFilesService {
  final String? customStoragePath;
  final int maxEntries;

  RecentFilesService({this.customStoragePath, this.maxEntries = 10});

  File get _storageFile {
    if (customStoragePath != null) {
      return File(customStoragePath!);
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
        'Application Support',
      );
    } else if (Platform.isLinux) {
      basePath =
          Platform.environment['XDG_CONFIG_HOME'] ??
          p.join(
            Platform.environment['HOME'] ?? Directory.systemTemp.path,
            '.config',
          );
    } else {
      basePath = Directory.systemTemp.path;
    }

    return File(p.join(basePath, 'GridSheet', 'recent_files.json'));
  }

  /// Retrieves the list of recent file paths.
  Future<List<String>> getRecentFiles() async {
    try {
      final file = _storageFile;
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString(encoding: utf8);
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}
    return [];
  }

  /// Adds [filePath] to recent files, placing it at the top and deduplicating.
  Future<void> addRecentFile(String filePath) async {
    try {
      final list = await getRecentFiles();
      list.remove(filePath);
      list.insert(0, filePath);

      final trimmed = list.take(maxEntries).toList();
      final file = _storageFile;
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(
        jsonEncode(trimmed),
        encoding: utf8,
        flush: true,
      );
    } catch (_) {}
  }

  /// Removes [filePath] from recent files.
  Future<void> removeRecentFile(String filePath) async {
    try {
      final list = await getRecentFiles();
      if (list.remove(filePath)) {
        final file = _storageFile;
        await file.writeAsString(jsonEncode(list), encoding: utf8, flush: true);
      }
    } catch (_) {}
  }

  /// Clears all recent files.
  Future<void> clearRecentFiles() async {
    try {
      final file = _storageFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
