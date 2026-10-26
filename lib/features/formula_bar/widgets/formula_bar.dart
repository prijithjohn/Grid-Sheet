import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// Interactive formula bar with Name Box, fx assistant, and formula editor.
class FormulaBar extends StatefulWidget {
  const FormulaBar({super.key, required this.state});

  final WorkbookState state;

  @override
  State<FormulaBar> createState() => _FormulaBarState();
}

class _FormulaBarState extends State<FormulaBar> {
  late final TextEditingController _formulaController;
  late final TextEditingController _nameBoxController;
  final FocusNode _formulaFocusNode = FocusNode();
  final FocusNode _nameBoxFocusNode = FocusNode();
  bool _isEditingFormula = false;

  @override
  void initState() {
    super.initState();
    _formulaController = TextEditingController(
      text: widget.state.activeCellInput,
    );
    _nameBoxController = TextEditingController(
      text: widget.state.activeCellAddress,
    );
    widget.state.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;
    if (!_isEditingFormula) {
      if (_formulaController.text != widget.state.activeCellInput) {
        _formulaController.text = widget.state.activeCellInput;
      }
    }
    if (!_nameBoxFocusNode.hasFocus) {
      if (_nameBoxController.text != widget.state.activeCellAddress) {
        _nameBoxController.text = widget.state.activeCellAddress;
      }
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant FormulaBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChange);
      widget.state.addListener(_onStateChange);
    }
    if (!_isEditingFormula) {
      _formulaController.text = widget.state.activeCellInput;
    }
    if (!_nameBoxFocusNode.hasFocus) {
      _nameBoxController.text = widget.state.activeCellAddress;
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    _formulaController.dispose();
    _nameBoxController.dispose();
    _formulaFocusNode.dispose();
    _nameBoxFocusNode.dispose();
    super.dispose();
  }

  void _commitFormula() {
    widget.state.editActiveCell(_formulaController.text);
    setState(() => _isEditingFormula = false);
    _formulaFocusNode.unfocus();
  }

  void _cancelFormula() {
    _formulaController.text = widget.state.activeCellInput;
    setState(() => _isEditingFormula = false);
    _formulaFocusNode.unfocus();
  }

  void _handleNameBoxSubmit(String value) {
    try {
      final coord = CellCoordinate.fromA1(value.trim());
      widget.state.selectCell(coord);
    } catch (_) {
      _nameBoxController.text = widget.state.activeCellAddress;
    }
    _nameBoxFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.formulaBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.canvasWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.neutralBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Name Box (Coordinate indicator / Jump to cell)
          Container(
            width: AppDimensions.nameBoxWidth,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.recessedChrome,
              border: Border.all(color: AppColors.neutralBorder, width: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: TextField(
              controller: _nameBoxController,
              focusNode: _nameBoxFocusNode,
              textAlign: TextAlign.center,
              style: AppTypography.nameBox,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onSubmitted: _handleNameBoxSubmit,
            ),
          ),
          const SizedBox(width: 4),

          // Cancel Edit (X)
          if (_isEditingFormula) ...[
            InkWell(
              onTap: _cancelFormula,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.close, size: 14, color: AppColors.errorRed),
              ),
            ),
            // Commit Edit (Checkmark)
            InkWell(
              onTap: _commitFormula,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ],

          // fx Helper Button
          Container(
            width: AppDimensions.fxButtonWidth,
            alignment: Alignment.center,
            child: const Text(
              'fx',
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Vertical Separator
          Container(height: 16, width: 1, color: AppColors.neutralBorder),
          const SizedBox(width: 8),

          // Formula Input Field
          Expanded(
            child: TextField(
              controller: _formulaController,
              focusNode: _formulaFocusNode,
              style: AppTypography.formulaInput,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
                border: InputBorder.none,
                hintText: 'Enter a value or =formula',
                hintStyle: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              onChanged: (_) {
                if (!_isEditingFormula) {
                  setState(() => _isEditingFormula = true);
                }
              },
              onSubmitted: (_) => _commitFormula(),
            ),
          ),
        ],
      ),
    );
  }
}
