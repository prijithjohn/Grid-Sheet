import 'package:flutter/material.dart';

import '../../../app/state/selection_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../domain/domain.dart';

/// CustomPainter rendering the active cell ring, range selection fill, and autofill handle.
class SelectionPainter extends CustomPainter {
  SelectionPainter({
    required this.worksheet,
    required this.selection,
    required this.scrollX,
    required this.scrollY,
  });

  final Worksheet worksheet;
  final SelectionState selection;
  final double scrollX;
  final double scrollY;

  @override
  void paint(Canvas canvas, Size size) {
    final range = selection.activeRange;

    // Calculate selection bounding box in pixel coordinates
    final startX = range.start.col < worksheet.frozenCols
        ? worksheet.getColumnOffset(range.start.col)
        : worksheet.getColumnOffset(range.start.col) - scrollX;
    final endX = range.end.col < worksheet.frozenCols
        ? worksheet.getColumnOffset(range.end.col + 1)
        : worksheet.getColumnOffset(range.end.col + 1) - scrollX;
    final startY = range.start.row < worksheet.frozenRows
        ? worksheet.getRowOffset(range.start.row)
        : worksheet.getRowOffset(range.start.row) - scrollY;
    final endY = range.end.row < worksheet.frozenRows
        ? worksheet.getRowOffset(range.end.row + 1)
        : worksheet.getRowOffset(range.end.row + 1) - scrollY;

    final rect = Rect.fromLTRB(startX, startY, endX, endY);

    // Multi-cell translucent fill
    if (range.cellCount > 1) {
      final fillPaint = Paint()
        ..color = AppColors.selectionFill.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
    }

    // Active Selection Ring (2px solid green border)
    final borderPaint = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    // Autofill handle (5x5px filled square at bottom-right corner)
    final handlePaint = Paint()
      ..color = AppColors.primaryContainer
      ..style = PaintingStyle.fill;
    final handleRect = Rect.fromCenter(
      center: Offset(rect.right, rect.bottom),
      width: AppDimensions.autofillHandleSize,
      height: AppDimensions.autofillHandleSize,
    );
    canvas.drawRect(handleRect, handlePaint);
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection ||
        oldDelegate.scrollX != scrollX ||
        oldDelegate.scrollY != scrollY ||
        oldDelegate.worksheet != worksheet;
  }
}
