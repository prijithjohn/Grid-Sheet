import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';
import '../commands/sort_range_command.dart';
import '../models/sort_options.dart';

/// Modal dialog for configuring custom multi-column or single-column sorting.
class SortDialog extends StatefulWidget {
  const SortDialog({super.key, required this.state});

  final WorkbookState state;

  /// Shows the Sort Dialog.
  static Future<void> show(
    BuildContext context, {
    required WorkbookState state,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SortDialog(state: state),
    );
  }

  @override
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  late CellRange _range;
  late int _selectedColumn;
  bool _ascending = true;
  bool _hasHeader = false;

  @override
  void initState() {
    super.initState();
    _range = widget.state.selection.activeRange;

    // If only a single cell is selected, expand to populated region or fallback
    if (_range.isSingleCell) {
      final active = widget.state.selection.primaryCell;
      final maxCol = widget.state.activeWorksheet.maxPopulatedCol;
      final maxRow = widget.state.activeWorksheet.maxPopulatedRow;

      if (maxCol >= active.col && maxRow >= active.row) {
        _range = CellRange(active, CellCoordinate(maxRow, maxCol));
      }
    }

    _selectedColumn = widget.state.selection.primaryCell.col.clamp(
      _range.leftCol,
      _range.rightCol,
    );
  }

  void _onSort() {
    final options = SortOptions(
      range: _range,
      sortColumn: _selectedColumn,
      ascending: _ascending,
      hasHeader: _hasHeader,
    );

    final cmd = SortRangeCommand(
      worksheet: widget.state.activeWorksheet,
      options: options,
      engine: widget.state.formulaEngine,
      workbook: widget.state.workbook,
    );

    widget.state.executeCommand(cmd);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final columns = <int>[];
    for (var c = _range.leftCol; c <= _range.rightCol; c++) {
      columns.add(c);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 8,
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          color: AppColors.canvasWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.neutralBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.recessedChrome,
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                border: Border(
                  bottom: BorderSide(color: AppColors.neutralBorder),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sort,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sort Range',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Range: ${_range.a1}',
                    style: const TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Has Header checkbox
                  InkWell(
                    onTap: () => setState(() => _hasHeader = !_hasHeader),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _hasHeader,
                            onChanged: (v) =>
                                setState(() => _hasHeader = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'My data has headers',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFontFamily,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sort by column dropdown
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          'Sort by:',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: DropdownButtonFormField<int>(
                            value: _selectedColumn,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            items: columns.map((c) {
                              final colLetter = CellCoordinate.columnToLetters(
                                c,
                              );
                              String label = 'Column $colLetter';
                              if (_hasHeader) {
                                final headerCell = widget.state.activeWorksheet
                                    .getCell(CellCoordinate(_range.topRow, c));
                                if (headerCell != null &&
                                    headerCell.displayValue.isNotEmpty) {
                                  label =
                                      '$colLetter (${headerCell.displayValue})';
                                }
                              }
                              return DropdownMenuItem<int>(
                                value: c,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.uiFontFamily,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedColumn = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Order dropdown
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          'Order:',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: DropdownButtonFormField<bool>(
                            value: _ascending,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem<bool>(
                                value: true,
                                child: Text(
                                  'Ascending (A to Z)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem<bool>(
                                value: false,
                                child: Text(
                                  'Descending (Z to A)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _ascending = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.neutralBorder),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onSort,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.canvasWhite,
                    ),
                    child: const Text('Sort'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
