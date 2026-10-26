import 'package:flutter/material.dart';

import '../../../app/state/selection_state.dart';
import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// Interactive sticky row header strip (1, 2, 3...) with drag-resizing.
class RowHeaderStrip extends StatelessWidget {
  const RowHeaderStrip({
    super.key,
    required this.state,
    required this.scrollY,
    required this.viewportHeight,
  });

  final WorkbookState state;
  final double scrollY;
  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    final worksheet = state.activeWorksheet;
    final selection = state.selection;

    // Calculate visible rows (0-indexed)
    int startRow = worksheet.getRowAtOffset(scrollY);
    double currentY = worksheet.getRowOffset(startRow);
    int row = startRow;
    final visibleRows = <_VisibleRowInfo>[];

    while (currentY < scrollY + viewportHeight &&
        row < CellCoordinate.maxRows) {
      final height = worksheet.getRowHeight(row);
      if (height > 0 && currentY + height >= scrollY) {
        visibleRows.add(
          _VisibleRowInfo(
            rowIndex: row,
            startY: currentY - scrollY,
            height: height,
            hasHiddenPreceding: row > 0 && worksheet.isRowHidden(row - 1),
          ),
        );
      }
      currentY += height;
      row++;
    }

    return Container(
      width: AppDimensions.rowHeaderWidth,
      color: AppColors.recessedChrome,
      child: Stack(
        children: [
          for (final info in visibleRows)
            Positioned(
              left: 0,
              top: info.startY,
              width: AppDimensions.rowHeaderWidth,
              height: info.height,
              child: _RowHeaderCell(
                rowIndex: info.rowIndex,
                isSelected:
                    selection.mode == SelectionMode.entireSheet ||
                    (selection.activeRange.topRow <= info.rowIndex &&
                        info.rowIndex <= selection.activeRange.bottomRow),
                hasHiddenPreceding: info.hasHiddenPreceding,
                onTap: () => state.selectEntireRow(info.rowIndex),
              ),
            ),
          for (final info in visibleRows)
            Positioned(
              left: 0,
              top: info.startY + info.height - 4,
              width: AppDimensions.rowHeaderWidth,
              height: 8,
              child: _RowResizeHandle(
                initialHeight: info.height,
                onResize: (newHeight) =>
                    state.resizeRow(info.rowIndex, newHeight),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisibleRowInfo {
  _VisibleRowInfo({
    required this.rowIndex,
    required this.startY,
    required this.height,
    this.hasHiddenPreceding = false,
  });

  final int rowIndex;
  final double startY;
  final double height;
  final bool hasHiddenPreceding;
}

class _RowHeaderCell extends StatelessWidget {
  const _RowHeaderCell({
    required this.rowIndex,
    required this.isSelected,
    required this.onTap,
    this.hasHiddenPreceding = false,
  });

  final int rowIndex;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasHiddenPreceding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.selectionFill : AppColors.recessedChrome,
        border: Border(
          top: hasHiddenPreceding
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
          right: const BorderSide(color: AppColors.neutralBorder, width: 1),
          bottom: const BorderSide(color: AppColors.neutralBorder, width: 1),
        ),
      ),
      child: Center(
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            child: Text(
              '${rowIndex + 1}',
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowResizeHandle extends StatefulWidget {
  const _RowResizeHandle({required this.initialHeight, required this.onResize});

  final double initialHeight;
  final void Function(double newHeight) onResize;

  @override
  State<_RowResizeHandle> createState() => _RowResizeHandleState();
}

class _RowResizeHandleState extends State<_RowResizeHandle> {
  double? _dragCurrentHeight;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {
          _dragCurrentHeight = widget.initialHeight;
        },
        onVerticalDragUpdate: (details) {
          if (_dragCurrentHeight != null) {
            final newHeight = (_dragCurrentHeight! + details.delta.dy).clamp(
              AppDimensions.minRowHeight,
              400.0,
            );
            _dragCurrentHeight = newHeight;
            widget.onResize(newHeight);
          }
        },
        onVerticalDragEnd: (_) {
          _dragCurrentHeight = null;
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}
