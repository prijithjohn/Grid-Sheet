import 'package:flutter/material.dart';

import '../../../app/state/selection_state.dart';
import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// Interactive sticky column header strip (A, B, C...) with drag-resizing.
class ColumnHeaderStrip extends StatelessWidget {
  const ColumnHeaderStrip({
    super.key,
    required this.state,
    required this.scrollX,
    required this.viewportWidth,
  });

  final WorkbookState state;
  final double scrollX;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    final worksheet = state.activeWorksheet;
    final selection = state.selection;

    // Calculate visible columns (0-indexed)
    double currentX = 0;
    int col = 0;
    final visibleCols = <_VisibleColInfo>[];

    while (currentX < scrollX + viewportWidth && col < CellCoordinate.maxCols) {
      final width = worksheet.getColumnWidth(col);
      if (currentX + width >= scrollX) {
        visibleCols.add(
          _VisibleColInfo(
            colIndex: col,
            startX: currentX - scrollX,
            width: width,
          ),
        );
      }
      currentX += width;
      col++;
    }

    return Container(
      height: AppDimensions.columnHeaderHeight,
      color: AppColors.recessedChrome,
      child: Stack(
        children: [
          for (final info in visibleCols)
            Positioned(
              left: info.startX,
              top: 0,
              width: info.width,
              height: AppDimensions.columnHeaderHeight,
              child: _ColumnHeaderCell(
                colIndex: info.colIndex,
                isSelected:
                    selection.mode == SelectionMode.entireSheet ||
                    (selection.activeRange.leftCol <= info.colIndex &&
                        info.colIndex <= selection.activeRange.rightCol),
                onTap: () => state.selectEntireColumn(info.colIndex),
              ),
            ),
          for (final info in visibleCols)
            Positioned(
              left: info.startX + info.width - 4,
              top: 0,
              width: 8,
              height: AppDimensions.columnHeaderHeight,
              child: _ColumnResizeHandle(
                initialWidth: info.width,
                onResize: (newWidth) =>
                    state.resizeColumn(info.colIndex, newWidth),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisibleColInfo {
  _VisibleColInfo({
    required this.colIndex,
    required this.startX,
    required this.width,
  });

  final int colIndex;
  final double startX;
  final double width;
}

class _ColumnHeaderCell extends StatelessWidget {
  const _ColumnHeaderCell({
    required this.colIndex,
    required this.isSelected,
    required this.onTap,
  });

  final int colIndex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final letter = CellCoordinate.columnToLetters(colIndex);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.selectionFill : AppColors.recessedChrome,
        border: const Border(
          right: BorderSide(color: AppColors.neutralBorder, width: 1),
          bottom: BorderSide(color: AppColors.neutralBorder, width: 1),
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
              letter,
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

class _ColumnResizeHandle extends StatefulWidget {
  const _ColumnResizeHandle({
    required this.initialWidth,
    required this.onResize,
  });

  final double initialWidth;
  final void Function(double newWidth) onResize;

  @override
  State<_ColumnResizeHandle> createState() => _ColumnResizeHandleState();
}

class _ColumnResizeHandleState extends State<_ColumnResizeHandle> {
  double? _dragCurrentWidth;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragCurrentWidth = widget.initialWidth;
        },
        onHorizontalDragUpdate: (details) {
          if (_dragCurrentWidth != null) {
            final newWidth = (_dragCurrentWidth! + details.delta.dx).clamp(
              AppDimensions.minColumnWidth,
              800.0,
            );
            _dragCurrentWidth = newWidth;
            widget.onResize(newWidth);
          }
        },
        onHorizontalDragEnd: (_) {
          _dragCurrentWidth = null;
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}
