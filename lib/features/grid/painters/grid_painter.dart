import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// High-performance CustomPainter rendering visible grid cells, gridlines, and cell values.
class GridPainter extends CustomPainter {
  GridPainter({
    required this.worksheet,
    required this.scrollX,
    required this.scrollY,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  final Worksheet worksheet;
  final double scrollX;
  final double scrollY;
  final double viewportWidth;
  final double viewportHeight;

  @override
  void paint(Canvas canvas, Size size) {
    // Clip to viewport
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridlinePaint = Paint()
      ..color = AppColors.gridline
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Calculate visible columns (0-indexed)
    double currentX = 0;
    int col = 0;
    final visibleCols = <int, double>{}; // colIndex -> startX

    while (currentX < scrollX + viewportWidth && col < CellCoordinate.maxCols) {
      final colWidth = worksheet.getColumnWidth(col);
      if (currentX + colWidth >= scrollX) {
        visibleCols[col] = currentX - scrollX;
      }
      currentX += colWidth;
      col++;
    }

    // Calculate visible rows (0-indexed)
    double currentY = 0;
    int row = 0;
    final visibleRows = <int, double>{}; // rowIndex -> startY

    while (currentY < scrollY + viewportHeight &&
        row < CellCoordinate.maxRows) {
      final rowHeight = worksheet.getRowHeight(row);
      if (currentY + rowHeight >= scrollY) {
        visibleRows[row] = currentY - scrollY;
      }
      currentY += rowHeight;
      row++;
    }

    // Draw cell backgrounds and gridlines
    for (final colEntry in visibleCols.entries) {
      final colIdx = colEntry.key;
      final startX = colEntry.value;
      final colWidth = worksheet.getColumnWidth(colIdx);

      for (final rowEntry in visibleRows.entries) {
        final rowIdx = rowEntry.key;
        final startY = rowEntry.value;
        final rowHeight = worksheet.getRowHeight(rowIdx);

        final cellRect = Rect.fromLTWH(startX, startY, colWidth, rowHeight);

        // Check if cell has content
        final coord = CellCoordinate(rowIdx, colIdx);
        final cell = worksheet.getCell(coord);

        if (cell != null && cell.style.fillColor != null) {
          final fillPaint = Paint()
            ..color = Color(cell.style.fillColor!)
            ..style = PaintingStyle.fill;
          canvas.drawRect(cellRect, fillPaint);
        }

        // Draw 1px bottom and right gridlines
        canvas.drawLine(
          Offset(startX, startY + rowHeight),
          Offset(startX + colWidth, startY + rowHeight),
          gridlinePaint,
        );
        canvas.drawLine(
          Offset(startX + colWidth, startY),
          Offset(startX + colWidth, startY + rowHeight),
          gridlinePaint,
        );

        // Draw cell text if populated
        if (cell != null && cell.formattedText.isNotEmpty) {
          _drawCellText(canvas, cell, cellRect);
        }
      }
    }
  }

  void _drawCellText(Canvas canvas, Cell cell, Rect cellRect) {
    final textColor = Color(cell.style.textColor);

    TextAlign textAlign = TextAlign.left;
    if (cell.value is NumberCellValue) {
      textAlign = TextAlign.right;
    }
    if (cell.style.horizontalAlignment == CellHorizontalAlignment.center) {
      textAlign = TextAlign.center;
    } else if (cell.style.horizontalAlignment ==
        CellHorizontalAlignment.right) {
      textAlign = TextAlign.right;
    } else if (cell.style.horizontalAlignment == CellHorizontalAlignment.left) {
      textAlign = TextAlign.left;
    }

    final textSpan = TextSpan(
      text: cell.formattedText,
      style: TextStyle(
        fontFamily: AppTypography.monoFontFamily,
        fontSize: cell.style.fontSize,
        fontWeight: cell.style.isBold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: cell.style.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: cell.style.isUnderline
            ? TextDecoration.underline
            : TextDecoration.none,
        color: textColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: (cellRect.width - 8).clamp(0, double.infinity));

    double xOffset = cellRect.left + 4;
    if (textAlign == TextAlign.right) {
      xOffset = cellRect.right - textPainter.width - 4;
    } else if (textAlign == TextAlign.center) {
      xOffset = cellRect.left + (cellRect.width - textPainter.width) / 2;
    }

    final yOffset = cellRect.top + (cellRect.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xOffset, yOffset));
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.scrollX != scrollX ||
        oldDelegate.scrollY != scrollY ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.worksheet != worksheet;
  }
}
