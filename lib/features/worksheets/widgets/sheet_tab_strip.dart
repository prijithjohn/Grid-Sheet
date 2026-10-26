import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// Bottom worksheet tab strip with tab navigation, creation, and context actions.
class SheetTabStrip extends StatelessWidget {
  const SheetTabStrip({super.key, required this.state});

  final WorkbookState state;

  void _showRenameDialog(BuildContext context, int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Rename Sheet',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sheet name'),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              state.renameWorksheet(index, val.trim());
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                state.renameWorksheet(index, controller.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTabContextMenu(
    BuildContext context,
    Offset position,
    int index,
    Worksheet sheet,
  ) async {
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'rename',
          child: Text('Rename Sheet'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          enabled: state.sheetCount > 1,
          child: Text(
            'Delete Sheet',
            style: TextStyle(
              color: state.sheetCount > 1
                  ? AppColors.errorRed
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (value == 'rename') {
      _showRenameDialog(context, index, sheet.name);
    } else if (value == 'delete') {
      state.removeWorksheetAt(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Container(
        height: AppDimensions.sheetTabStripHeight,
        decoration: const BoxDecoration(
          color: AppColors.recessedChrome,
          border: Border(
            top: BorderSide(color: AppColors.neutralBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Scroll Navigation Controls
            InkWell(
              onTap: () {},
              child: const SizedBox(
                width: 24,
                height: AppDimensions.sheetTabStripHeight,
                child: Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            InkWell(
              onTap: () {},
              child: const SizedBox(
                width: 24,
                height: AppDimensions.sheetTabStripHeight,
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Add New Sheet Button (+)
            Tooltip(
              message: 'Add Worksheet',
              child: InkWell(
                onTap: state.addWorksheet,
                child: Container(
                  width: 28,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: AppColors.neutralBorder,
                      width: 0.5,
                    ),
                    color: AppColors.canvasWhite,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Sheet Tab List
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < state.sheets.length; i++)
                      _SheetTabItem(
                        sheet: state.sheets[i],
                        isActive: state.activeSheetIndex == i,
                        onTap: () => state.setActiveSheetIndex(i),
                        onContextMenu: (pos) => _showTabContextMenu(
                          context,
                          pos,
                          i,
                          state.sheets[i],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTabItem extends StatelessWidget {
  const _SheetTabItem({
    required this.sheet,
    required this.isActive,
    required this.onTap,
    required this.onContextMenu,
  });

  final Worksheet sheet;
  final bool isActive;
  final VoidCallback onTap;
  final void Function(Offset position) onContextMenu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
      onLongPressStart: (details) => onContextMenu(details.globalPosition),
      child: Container(
        height: AppDimensions.sheetTabStripHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.canvasWhite : AppColors.recessedChrome,
          border: Border(
            top: isActive
                ? const BorderSide(color: AppColors.primaryContainer, width: 2)
                : const BorderSide(color: Colors.transparent, width: 2),
            right: const BorderSide(color: AppColors.neutralBorder, width: 1),
          ),
        ),
        child: Text(
          sheet.name,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? AppColors.primaryContainer
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
