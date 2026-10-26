import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// User decision when prompted with unsaved changes.
enum UnsavedChangesAction {
  /// Save changes and continue.
  save,

  /// Discard changes and continue without saving.
  discard,

  /// Cancel the operation and return to editing.
  cancel,
}

/// Dialog displayed when closing, opening a new file, or quitting with unsaved changes.
class UnsavedChangesDialog extends StatelessWidget {
  final String? fileName;

  const UnsavedChangesDialog({super.key, this.fileName});

  /// Displays the unsaved changes dialog and returns the user's selected [UnsavedChangesAction].
  static Future<UnsavedChangesAction?> show(
    BuildContext context, {
    String? fileName,
  }) {
    return showDialog<UnsavedChangesAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UnsavedChangesDialog(fileName: fileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = fileName ?? 'this workbook';

    return AlertDialog(
      key: const Key('unsaved_changes_dialog'),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFC19C00), size: 24),
          SizedBox(width: 8),
          Text(
            'Unsaved Changes',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Do you want to save the changes you made to "$name"?\n'
        'Your changes will be lost if you don\'t save them.',
        style: const TextStyle(
          fontFamily: AppTypography.uiFontFamily,
          fontSize: 13,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
      actions: [
        // Save
        ElevatedButton(
          key: const Key('unsaved_changes_save_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.canvasWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.save),
          child: const Text(
            'Save',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Discard / Don't Save
        OutlinedButton(
          key: const Key('unsaved_changes_discard_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC62828),
            side: const BorderSide(color: Color(0xFFE57373)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.discard),
          child: const Text(
            'Don\'t Save',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Cancel
        TextButton(
          key: const Key('unsaved_changes_cancel_button'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.cancel),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
