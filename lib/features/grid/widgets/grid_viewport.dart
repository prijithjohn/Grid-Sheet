import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';
import '../painters/grid_painter.dart';
import '../painters/selection_painter.dart';
import 'column_header_strip.dart';
import 'row_header_strip.dart';

/// Two-dimensional virtualized spreadsheet grid canvas with sticky headers,
/// cell hit-testing, selection highlights, and in-grid editing.
class GridViewport extends StatefulWidget {
  const GridViewport({super.key, required this.state});

  final WorkbookState state;

  @override
  State<GridViewport> createState() => _GridViewportState();
}

class _GridViewportState extends State<GridViewport> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  double _scrollX = 0;
  double _scrollY = 0;

  // In-grid editing state
  bool _isEditingCell = false;
  late final TextEditingController _cellEditController;
  final FocusNode _cellEditFocusNode = FocusNode();
  CellCoordinate? _panStartCoord;

  @override
  void initState() {
    super.initState();
    _cellEditController = TextEditingController();
    _horizontalScrollController.addListener(_onScroll);
    _verticalScrollController.addListener(_onScroll);
    widget.state.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant GridViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChange);
      widget.state.addListener(_onStateChange);
    }
  }

  void _onScroll() {
    setState(() {
      _scrollX = _horizontalScrollController.hasClients
          ? _horizontalScrollController.offset
          : 0;
      _scrollY = _verticalScrollController.hasClients
          ? _verticalScrollController.offset
          : 0;
    });
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _cellEditController.dispose();
    _cellEditFocusNode.dispose();
    super.dispose();
  }

  void _startEditingCell([String? initialText]) {
    final text = initialText ?? widget.state.activeCellInput;
    _cellEditController.text = text;
    _cellEditController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() => _isEditingCell = true);
    _cellEditFocusNode.requestFocus();
  }

  void _commitEditingCell({
    bool advanceDown = false,
    bool advanceRight = false,
  }) {
    if (!_isEditingCell) return;
    widget.state.editActiveCell(_cellEditController.text);
    setState(() => _isEditingCell = false);
    _cellEditFocusNode.unfocus();

    if (advanceDown) {
      final curr = widget.state.selection.primaryCell;
      widget.state.selectCell(
        curr.copyWith(row: (curr.row + 1).clamp(0, CellCoordinate.maxRows - 1)),
      );
    } else if (advanceRight) {
      final curr = widget.state.selection.primaryCell;
      widget.state.selectCell(
        curr.copyWith(col: (curr.col + 1).clamp(0, CellCoordinate.maxCols - 1)),
      );
    }
  }

  void _cancelEditingCell() {
    setState(() => _isEditingCell = false);
    _cellEditFocusNode.unfocus();
  }

  CellCoordinate? _hitTestCoordinate(Offset localOffset) {
    final worksheet = widget.state.activeWorksheet;
    final frozenCols = worksheet.frozenCols;
    final frozenRows = worksheet.frozenRows;

    // Check frozen columns first
    double currentX = 0;
    int col = 0;
    bool inFrozenCol = false;
    while (col < frozenCols) {
      final width = worksheet.getColumnWidth(col);
      if (localOffset.dx >= currentX && localOffset.dx < currentX + width) {
        inFrozenCol = true;
        break;
      }
      currentX += width;
      col++;
    }

    if (!inFrozenCol) {
      final targetX = localOffset.dx + _scrollX;
      currentX = 0;
      col = 0;
      while (col < CellCoordinate.maxCols) {
        final width = worksheet.getColumnWidth(col);
        if (targetX >= currentX && targetX < currentX + width) break;
        currentX += width;
        col++;
      }
    }

    // Check frozen rows first
    double currentY = 0;
    int row = 0;
    bool inFrozenRow = false;
    while (row < frozenRows) {
      final height = worksheet.getRowHeight(row);
      if (height > 0 &&
          localOffset.dy >= currentY &&
          localOffset.dy < currentY + height) {
        inFrozenRow = true;
        break;
      }
      currentY += height;
      row++;
    }

    if (!inFrozenRow) {
      final targetY = localOffset.dy + _scrollY;
      currentY = 0;
      row = 0;
      while (row < CellCoordinate.maxRows) {
        final height = worksheet.getRowHeight(row);
        if (height > 0 && targetY >= currentY && targetY < currentY + height) {
          break;
        }
        currentY += height;
        row++;
      }
    }

    if (col < CellCoordinate.maxCols && row < CellCoordinate.maxRows) {
      return CellCoordinate(row, col);
    }
    return null;
  }

  Rect _getCellRect(CellCoordinate coord) {
    final worksheet = widget.state.activeWorksheet;

    double x = 0;
    for (int c = 0; c < coord.col; c++) {
      x += worksheet.getColumnWidth(c);
    }
    final width = worksheet.getColumnWidth(coord.col);

    double y = 0;
    for (int r = 0; r < coord.row; r++) {
      y += worksheet.getRowHeight(r);
    }
    final height = worksheet.getRowHeight(coord.row);

    final offsetX = coord.col < worksheet.frozenCols ? x : x - _scrollX;
    final offsetY = coord.row < worksheet.frozenRows ? y : y - _scrollY;

    return Rect.fromLTWH(offsetX, offsetY, width, height);
  }

  @override
  Widget build(BuildContext context) {
    final worksheet = widget.state.activeWorksheet;

    // Estimate total virtual dimensions (first 100 columns and 500 rows for scrolling)
    double totalWidth = 0;
    for (int c = 0; c < 100; c++) {
      totalWidth += worksheet.getColumnWidth(c);
    }
    double totalHeight = 0;
    for (int r = 0; r < 500; r++) {
      totalHeight += worksheet.getRowHeight(r);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyWidth = constraints.maxWidth - AppDimensions.rowHeaderWidth;
        final bodyHeight =
            constraints.maxHeight - AppDimensions.columnHeaderHeight;

        final activeCellCoord = widget.state.selection.primaryCell;
        final activeCellRect = _getCellRect(activeCellCoord);

        return Container(
          color: AppColors.canvasWhite,
          child: Column(
            children: [
              // Header Row: Top-Left Corner Box + Column Headers
              Row(
                children: [
                  // Select All Corner Box
                  InkWell(
                    onTap: widget.state.selectAll,
                    child: Container(
                      width: AppDimensions.rowHeaderWidth,
                      height: AppDimensions.columnHeaderHeight,
                      decoration: const BoxDecoration(
                        color: AppColors.recessedChrome,
                        border: Border(
                          right: BorderSide(
                            color: AppColors.neutralBorder,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: AppColors.neutralBorder,
                            width: 1,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Synchronized Column Header Strip
                  Expanded(
                    child: ColumnHeaderStrip(
                      state: widget.state,
                      scrollX: _scrollX,
                      viewportWidth: bodyWidth,
                    ),
                  ),
                ],
              ),

              // Body: Sticky Row Headers + Virtualized Canvas
              Expanded(
                child: Row(
                  children: [
                    // Synchronized Row Header Strip
                    RowHeaderStrip(
                      state: widget.state,
                      scrollY: _scrollY,
                      viewportHeight: bodyHeight,
                    ),

                    // Grid Body Viewport
                    Expanded(
                      child: Stack(
                        children: [
                          // 2D Scroll Viewport
                          Scrollbar(
                            controller: _verticalScrollController,
                            thumbVisibility: true,
                            child: Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              notificationPredicate: (notif) =>
                                  notif.depth == 1,
                              child: SingleChildScrollView(
                                controller: _verticalScrollController,
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  controller: _horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: totalWidth,
                                    height: totalHeight,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Custom Canvas Layer (Pinned to viewport)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) {
                                if (_isEditingCell) {
                                  _commitEditingCell();
                                }
                                final coord = _hitTestCoordinate(
                                  details.localPosition,
                                );
                                if (coord != null) {
                                  widget.state.selectCell(coord);
                                }
                              },
                              onDoubleTapDown: (details) {
                                final coord = _hitTestCoordinate(
                                  details.localPosition,
                                );
                                if (coord != null) {
                                  widget.state.selectCell(coord);
                                  _startEditingCell();
                                }
                              },
                              onPanDown: (details) {
                                final coord = _hitTestCoordinate(
                                  details.localPosition,
                                );
                                _panStartCoord = coord;
                              },
                              onPanStart: (details) {
                                if (_isEditingCell) {
                                  _commitEditingCell();
                                }
                                if (_panStartCoord != null) {
                                  widget.state.selectCell(_panStartCoord!);
                                }
                                final currentCoord = _hitTestCoordinate(
                                  details.localPosition,
                                );
                                if (currentCoord != null &&
                                    _panStartCoord != null &&
                                    currentCoord != _panStartCoord) {
                                  widget.state.extendSelection(currentCoord);
                                }
                              },
                              onPanUpdate: (details) {
                                final coord = _hitTestCoordinate(
                                  details.localPosition,
                                );
                                if (coord != null) {
                                  widget.state.extendSelection(coord);
                                }
                              },
                              onPanEnd: (_) => _panStartCoord = null,
                              onPanCancel: () => _panStartCoord = null,
                              child: Stack(
                                children: [
                                  // Grid Background & Text Painter
                                  CustomPaint(
                                    size: Size(bodyWidth, bodyHeight),
                                    painter: GridPainter(
                                      worksheet: worksheet,
                                      scrollX: _scrollX,
                                      scrollY: _scrollY,
                                      viewportWidth: bodyWidth,
                                      viewportHeight: bodyHeight,
                                    ),
                                  ),

                                  // Selection Ring & Autofill Painter
                                  CustomPaint(
                                    size: Size(bodyWidth, bodyHeight),
                                    painter: SelectionPainter(
                                      worksheet: worksheet,
                                      selection: widget.state.selection,
                                      scrollX: _scrollX,
                                      scrollY: _scrollY,
                                    ),
                                  ),

                                  // In-Grid Text Editing Overlay
                                  if (_isEditingCell &&
                                      activeCellRect.right > 0 &&
                                      activeCellRect.left < bodyWidth &&
                                      activeCellRect.bottom > 0 &&
                                      activeCellRect.top < bodyHeight)
                                    Positioned(
                                      left: activeCellRect.left,
                                      top: activeCellRect.top,
                                      width: activeCellRect.width,
                                      height: activeCellRect.height,
                                      child: _InGridCellEditor(
                                        controller: _cellEditController,
                                        focusNode: _cellEditFocusNode,
                                        onCommit: () => _commitEditingCell(
                                          advanceDown: true,
                                        ),
                                        onCommitTab: () => _commitEditingCell(
                                          advanceRight: true,
                                        ),
                                        onCancel: _cancelEditingCell,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InGridCellEditor extends StatelessWidget {
  const _InGridCellEditor({
    required this.controller,
    required this.focusNode,
    required this.onCommit,
    required this.onCommitTab,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCommit;
  final VoidCallback onCommitTab;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasWhite,
        border: Border.all(color: AppColors.primaryContainer, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              onCommit();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.tab) {
              onCommitTab();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              onCancel();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: AppTypography.cellText,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onCommit(),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
