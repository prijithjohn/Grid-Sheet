import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/persistence/recovery_service.dart';

/// User decision when prompted with detected crash recovery journal.
enum RecoveryAction {
  /// Restore the recovered workbook.
  restore,

  /// Discard the recovery file.
  discard,
}

/// Dialog displayed on startup when crash recovery journals are detected.
class RecoveryPromptDialog extends StatelessWidget {
  final RecoveryJournalInfo info;

  const RecoveryPromptDialog({super.key, required this.info});

  /// Displays the recovery prompt dialog.
  static Future<RecoveryAction?> show(
    BuildContext context, {
    required RecoveryJournalInfo info,
  }) {
    return showDialog<RecoveryAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RecoveryPromptDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        '${info.savedAt.year}-${info.savedAt.month.toString().padLeft(2, '0')}-${info.savedAt.day.toString().padLeft(2, '0')} '
        '${info.savedAt.hour.toString().padLeft(2, '0')}:${info.savedAt.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      key: const Key('recovery_prompt_dialog'),
      title: const Row(
        children: [
          Icon(Icons.restore_page_rounded, color: AppColors.primary, size: 24),
          SizedBox(width: 8),
          Text(
            'Document Recovery',
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
        'Grid Sheet recovered unsaved changes from a previous session:\n\n'
        '• File: ${info.displayName}\n'
        '• Auto-saved: $formattedTime\n\n'
        'Would you like to restore this recovered version?',
        style: const TextStyle(
          fontFamily: AppTypography.uiFontFamily,
          fontSize: 13,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
      actions: [
        ElevatedButton(
          key: const Key('recovery_restore_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.canvasWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(RecoveryAction.restore),
          child: const Text(
            'Restore',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          key: const Key('recovery_discard_button'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () => Navigator.of(context).pop(RecoveryAction.discard),
          child: const Text(
            'Discard',
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
