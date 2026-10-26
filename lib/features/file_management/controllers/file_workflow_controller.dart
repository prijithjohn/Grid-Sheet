import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../app/state/workbook_state.dart';
import '../../../data/persistence/file_persistence_service.dart';
import '../../../data/persistence/recent_files_service.dart';
import '../../../data/persistence/recovery_service.dart';
import '../../../domain/domain.dart';
import '../widgets/recovery_prompt_dialog.dart';
import '../widgets/unsaved_changes_dialog.dart';

/// Coordinates file-level user workflows: Save, Save As, Open, New, and Crash Recovery.
class FileWorkflowController {
  final WorkbookState state;
  final FilePersistenceService persistenceService;
  final RecoveryService recoveryService;
  final RecentFilesService recentFilesService;

  FileWorkflowController({
    required this.state,
    FilePersistenceService? persistenceService,
    RecoveryService? recoveryService,
    RecentFilesService? recentFilesService,
    bool enableAutoSave = true,
  }) : persistenceService = persistenceService ?? FilePersistenceService(),
       recoveryService = recoveryService ?? RecoveryService(),
       recentFilesService = recentFilesService ?? RecentFilesService() {
    if (enableAutoSave) {
      this.recoveryService.startAutoSave(state);
    }
  }

  /// Saves the current workbook. If untitled, redirects to [saveAs].
  Future<bool> save({BuildContext? context}) async {
    if (state.filePath == null || state.filePath!.isEmpty) {
      return saveAs(context: context);
    }

    try {
      final path = state.filePath!;
      await persistenceService.saveWorkbook(state.workbook, path);
      state.markClean(savedFilePath: path);
      await recoveryService.deleteJournal(state.workbook.id);
      await recentFilesService.addRecentFile(path);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workbook saved: ${p.basename(path)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workbook: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return false;
    }
  }

  /// Prompts the user for a save location and saves the workbook.
  Future<bool> saveAs({BuildContext? context}) async {
    try {
      final suggested = state.filePath != null
          ? p.basename(state.filePath!)
          : '${state.title.isNotEmpty ? state.title : 'Untitled'}.gsheet';

      final path = await persistenceService.pickSaveLocation(
        suggestedName: suggested,
      );

      if (path == null) {
        return false; // User cancelled
      }

      await persistenceService.saveWorkbook(state.workbook, path);
      state.markClean(savedFilePath: path);
      await recoveryService.deleteJournal(state.workbook.id);
      await recentFilesService.addRecentFile(path);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workbook saved as: ${p.basename(path)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workbook: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return false;
    }
  }

  /// Opens an existing workbook using the file picker.
  ///
  /// Prompts to save unsaved changes first if the current workbook is dirty.
  Future<bool> open({BuildContext? context}) async {
    if (state.isDirty && context != null && context.mounted) {
      final action = await UnsavedChangesDialog.show(
        context,
        fileName: state.filePath != null
            ? p.basename(state.filePath!)
            : state.title,
      );

      if (action == null || action == UnsavedChangesAction.cancel) {
        return false;
      }

      if (action == UnsavedChangesAction.save) {
        if (!context.mounted) return false;
        final saved = await save(context: context);
        if (!saved) return false;
      }
    }

    final path = await persistenceService.pickOpenLocation();
    if (path == null) return false;

    if (context != null && !context.mounted) return false;
    return openFromPath(path, context: context);
  }

  /// Loads and opens a workbook directly from [filePath].
  Future<bool> openFromPath(String filePath, {BuildContext? context}) async {
    try {
      final workbook = await persistenceService.loadWorkbook(filePath);
      state.loadWorkbook(workbook, filePath: filePath);
      await recentFilesService.addRecentFile(filePath);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${p.basename(filePath)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load workbook: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return false;
    }
  }

  /// Creates a new default blank workbook, confirming unsaved changes first.
  Future<bool> newWorkbook({BuildContext? context}) async {
    if (state.isDirty && context != null && context.mounted) {
      final action = await UnsavedChangesDialog.show(
        context,
        fileName: state.filePath != null
            ? p.basename(state.filePath!)
            : state.title,
      );

      if (action == null || action == UnsavedChangesAction.cancel) {
        return false;
      }

      if (action == UnsavedChangesAction.save) {
        if (!context.mounted) return false;
        final saved = await save(context: context);
        if (!saved) return false;
      }
    }

    final newWb = Workbook.createDefault();
    state.loadWorkbook(newWb, filePath: null);
    return true;
  }

  /// Checks for any orphaned crash recovery journals on startup and prompts the user.
  Future<void> checkRecoveryOnStartup(BuildContext context) async {
    final journals = await recoveryService.scanOrphanedJournals();
    if (journals.isEmpty || !context.mounted) return;

    // Prompt for the most recent recovery journal
    final mostRecent = journals.reduce(
      (a, b) => a.savedAt.isAfter(b.savedAt) ? a : b,
    );

    final action = await RecoveryPromptDialog.show(context, info: mostRecent);
    if (action == RecoveryAction.restore) {
      try {
        final recoveredWb = await recoveryService.recoverWorkbook(
          mostRecent.journalPath,
        );
        state.loadWorkbook(recoveredWb, filePath: mostRecent.originalFilePath);
        // Note: mark as dirty because it contains recovered unsaved edits
        // State is refreshed with recovered contents
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to restore recovered workbook: $e'),
              backgroundColor: const Color(0xFFC62828),
            ),
          );
        }
      }
    } else {
      // Discard
      await recoveryService.deleteJournalByPath(mostRecent.journalPath);
    }
  }

  /// Disposes background timers and services.
  void dispose() {
    recoveryService.dispose();
  }
}
