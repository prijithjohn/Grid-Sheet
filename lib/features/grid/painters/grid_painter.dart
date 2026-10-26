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

    final frozenCols = worksheet.frozenCols;
    final frozenRows = worksheet.frozenRows;

    final frozenWidth = worksheet.getColumnOffset(frozenCols);
    final frozenHeight = worksheet.getRowOffset(frozenRows);

    // Calculate visible columns (0-indexed)
    final visibleCols = <int, double>{};
    for (int c = 0; c < frozenCols; c++) {
      visibleCols[c] = worksheet.getColumnOffset(c);
    }

    int startCol = worksheet.getColumnAtOffset(scrollX + frozenWidth);
    if (startCol < frozenCols) startCol = frozenCols;
    double currentX = worksheet.getColumnOffset(startCol);
    int col = startCol;
    while (currentX < scrollX + viewportWidth && col < CellCoordinate.maxCols) {
      final colWidth = worksheet.getColumnWidth(col);
      if (currentX + colWidth >= scrollX + frozenWidth) {
        visibleCols[col] = currentX - scrollX;
      }
      currentX += colWidth;
      col++;
    }

    // Calculate visible rows (0-indexed)
    final visibleRows = <int, double>{};
    for (int r = 0; r < frozenRows; r++) {
      final h = worksheet.getRowHeight(r);
      if (h > 0) {
        visibleRows[r] = worksheet.getRowOffset(r);
      }
    }

    int startRow = worksheet.getRowAtOffset(scrollY + frozenHeight);
    if (startRow < frozenRows) startRow = frozenRows;
    double currentY = worksheet.getRowOffset(startRow);
    int row = startRow;
    while (currentY < scrollY + viewportHeight &&
        row < CellCoordinate.maxRows) {
      final rowHeight = worksheet.getRowHeight(row);
      if (rowHeight > 0 && currentY + rowHeight >= scrollY + frozenHeight) {
        visibleRows[row] = currentY - scrollY;
      }
      currentY += rowHeight;
      row++;
    }

    // Draw non-frozen cells first, then frozen cells on top
    void renderCell(int rowIdx, int colIdx, double startX, double startY) {
      final colWidth = worksheet.getColumnWidth(colIdx);
      final rowHeight = worksheet.getRowHeight(rowIdx);
      if (rowHeight <= 0) return;

      final cellRect = Rect.fromLTWH(startX, startY, colWidth, rowHeight);
      final coord = CellCoordinate(rowIdx, colIdx);
      final cell = worksheet.getCell(coord);

      final isFrozen = rowIdx < frozenRows || colIdx < frozenCols;

      // Fill background (opaque white for frozen cells so scrolled data doesn't bleed)
      if (cell != null && cell.style.fillColor != null) {
        final fillPaint = Paint()
          ..color = Color(cell.style.fillColor!)
          ..style = PaintingStyle.fill;
        canvas.drawRect(cellRect, fillPaint);
      } else if (isFrozen) {
        final bgPaint = Paint()
          ..color = AppColors.canvasWhite
          ..style = PaintingStyle.fill;
        canvas.drawRect(cellRect, bgPaint);
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

      // Draw cell text
      if (cell != null && cell.formattedText.isNotEmpty) {
        _drawCellText(canvas, cell, cellRect);
      }
    }

    // 1. Scrolled body cells
    for (final colEntry in visibleCols.entries) {
      if (colEntry.key < frozenCols) continue;
      for (final rowEntry in visibleRows.entries) {
        if (rowEntry.key < frozenRows) continue;
        renderCell(rowEntry.key, colEntry.key, colEntry.value, rowEntry.value);
      }
    }

    // 2. Frozen rows and columns on top
    for (final colEntry in visibleCols.entries) {
      for (final rowEntry in visibleRows.entries) {
        if (colEntry.key < frozenCols || rowEntry.key < frozenRows) {
          renderCell(
            rowEntry.key,
            colEntry.key,
            colEntry.value,
            rowEntry.value,
          );
        }
      }
    }

    // 3. Draw freeze split borders
    final freezeBorderPaint = Paint()
      ..color = AppColors.neutralBorder
      ..strokeWidth = 2.0;

    if (frozenRows > 0 && frozenHeight > 0) {
      canvas.drawLine(
        Offset(0, frozenHeight),
        Offset(viewportWidth, frozenHeight),
        freezeBorderPaint,
      );
    }
    if (frozenCols > 0 && frozenWidth > 0) {
      canvas.drawLine(
        Offset(frozenWidth, 0),
        Offset(frozenWidth, viewportHeight),
        freezeBorderPaint,
      );
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
