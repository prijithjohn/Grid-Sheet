import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// Modal dialog for configuring text and numeric filters on a specific column.
class ColumnFilterDialog extends StatefulWidget {
  const ColumnFilterDialog({
    super.key,
    required this.state,
    required this.colIndex,
  });

  final WorkbookState state;
  final int colIndex;

  /// Shows the column filter dialog.
  static Future<void> show(
    BuildContext context, {
    required WorkbookState state,
    required int colIndex,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          ColumnFilterDialog(state: state, colIndex: colIndex),
    );
  }

  @override
  State<ColumnFilterDialog> createState() => _ColumnFilterDialogState();
}

class _ColumnFilterDialogState extends State<ColumnFilterDialog> {
  final TextEditingController _containsController = TextEditingController();
  final TextEditingController _equalsController = TextEditingController();
  final TextEditingController _numericValueController = TextEditingController();

  NumericFilterOp? _selectedNumericOp;
  bool _showBlanks = true;
  bool _hideBlanks = false;

  @override
  void initState() {
    super.initState();
    final filter = widget.state.activeWorksheet.filter as WorksheetFilter?;
    final criteria = filter?.columnFilters[widget.colIndex];
    if (criteria != null) {
      _containsController.text = criteria.textContains ?? '';
      _equalsController.text = criteria.textEquals ?? '';
      _selectedNumericOp = criteria.numericOp;
      if (criteria.numericValue != null) {
        _numericValueController.text = criteria.numericValue.toString();
      }
      _showBlanks = criteria.showBlanks;
      _hideBlanks = criteria.hideBlanks;
    }
  }

  @override
  void dispose() {
    _containsController.dispose();
    _equalsController.dispose();
    _numericValueController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final numVal = double.tryParse(_numericValueController.text.trim());

    final criteria = ColumnFilterCriteria(
      textContains: _containsController.text.trim().isNotEmpty
          ? _containsController.text.trim()
          : null,
      textEquals: _equalsController.text.trim().isNotEmpty
          ? _equalsController.text.trim()
          : null,
      numericOp: numVal != null ? _selectedNumericOp : null,
      numericValue: numVal,
      showBlanks: _showBlanks,
      hideBlanks: _hideBlanks,
    );

    widget.state.applyColumnFilter(widget.colIndex, criteria);
    Navigator.of(context).pop();
  }

  void _clearFilter() {
    widget.state.clearColumnFilter(widget.colIndex);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colLetter = CellCoordinate.columnToLetters(widget.colIndex);

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
                    Icons.filter_alt_outlined,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Column $colLetter',
                    style: const TextStyle(
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

            // Form Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Contains
                  _buildTextField(
                    label: 'Text contains:',
                    controller: _containsController,
                    hint: 'e.g. sales, completed',
                  ),
                  const SizedBox(height: 10),

                  // Text Equals
                  _buildTextField(
                    label: 'Text equals:',
                    controller: _equalsController,
                    hint: 'e.g. Active, Pending',
                  ),
                  const SizedBox(height: 12),

                  // Numeric condition
                  const Text(
                    'Numeric Comparison:',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 30,
                        child: DropdownButtonFormField<NumericFilterOp>(
                          value: _selectedNumericOp,
                          isDense: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          hint: const Text(
                            'Op',
                            style: TextStyle(fontSize: 11),
                          ),
                          items: NumericFilterOp.values.map((op) {
                            return DropdownMenuItem<NumericFilterOp>(
                              value: op,
                              child: Text(
                                op.symbol,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedNumericOp = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: TextField(
                            controller: _numericValueController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Value (e.g. 100)',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Blank handling
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _hideBlanks,
                          onChanged: (v) {
                            setState(() {
                              _hideBlanks = v ?? false;
                              if (_hideBlanks) _showBlanks = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Hide blank cells',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.neutralBorder),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _clearFilter,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Clear Filter'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _applyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.canvasWhite,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 28,
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
