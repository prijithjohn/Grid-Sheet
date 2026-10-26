import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../commands/replace_commands.dart';
import '../models/find_replace_options.dart';
import '../services/find_replace_engine.dart';

/// Desktop dialog for Find and Replace operations matching Stitch design system.
class FindReplaceDialog extends StatefulWidget {
  const FindReplaceDialog({
    super.key,
    required this.state,
    this.initialTab = 0, // 0 = Find, 1 = Replace
  });

  final WorkbookState state;
  final int initialTab;

  /// Shows the Find and Replace dialog.
  static Future<void> show(
    BuildContext context, {
    required WorkbookState state,
    int initialTab = 0,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          FindReplaceDialog(state: state, initialTab: initialTab),
    );
  }

  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog> {
  late int _activeTab; // 0 = Find, 1 = Replace
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();

  bool _matchCase = false;
  bool _matchEntireCell = false;
  bool _searchWorkbook = false;
  bool _searchFormulas = false;

  final FindReplaceEngine _engine = const FindReplaceEngine();
  List<FindReplaceMatch> _matches = [];
  int _currentMatchIndex = -1;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _findFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  FindReplaceOptions _buildOptions() {
    return FindReplaceOptions(
      query: _findController.text,
      replacement: _replaceController.text,
      matchCase: _matchCase,
      matchEntireCell: _matchEntireCell,
      searchWorkbook: _searchWorkbook,
      searchFormulas: _searchFormulas,
    );
  }

  void _search() {
    final options = _buildOptions();
    if (options.query.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
        _statusMessage = 'Enter search text.';
      });
      return;
    }

    final results = _engine.findAll(
      workbook: widget.state.workbook,
      activeSheetIndex: widget.state.activeSheetIndex,
      options: options,
    );

    setState(() {
      _matches = results;
      if (results.isEmpty) {
        _currentMatchIndex = -1;
        _statusMessage = 'No matches found.';
      } else {
        _currentMatchIndex = 0;
        _statusMessage = 'Match 1 of ${results.length}';
        _navigateToMatch(results[0]);
      }
    });
  }

  void _findNext() {
    if (_matches.isEmpty) {
      _search();
      return;
    }
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
      _statusMessage = 'Match ${_currentMatchIndex + 1} of ${_matches.length}';
      _navigateToMatch(_matches[_currentMatchIndex]);
    });
  }

  void _findPrevious() {
    if (_matches.isEmpty) {
      _search();
      return;
    }
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matches.length) % _matches.length;
      _statusMessage = 'Match ${_currentMatchIndex + 1} of ${_matches.length}';
      _navigateToMatch(_matches[_currentMatchIndex]);
    });
  }

  void _navigateToMatch(FindReplaceMatch match) {
    if (match.worksheetIndex != widget.state.activeSheetIndex) {
      widget.state.setActiveSheetIndex(match.worksheetIndex);
    }
    widget.state.selectCell(match.coordinate);
  }

  void _replaceCurrent() {
    if (_matches.isEmpty ||
        _currentMatchIndex < 0 ||
        _currentMatchIndex >= _matches.length) {
      _search();
      if (_matches.isEmpty) return;
    }

    final match = _matches[_currentMatchIndex];
    final options = _buildOptions();

    final cmd = ReplaceMatchCommand(
      workbook: widget.state.workbook,
      match: match,
      options: options,
      engine: widget.state.formulaEngine,
    );

    widget.state.executeCommand(cmd);

    // Refresh matches after modification
    final results = _engine.findAll(
      workbook: widget.state.workbook,
      activeSheetIndex: widget.state.activeSheetIndex,
      options: options,
    );

    setState(() {
      _matches = results;
      if (results.isEmpty) {
        _currentMatchIndex = -1;
        _statusMessage = 'Replaced. No further matches.';
      } else {
        _currentMatchIndex = _currentMatchIndex.clamp(0, results.length - 1);
        _statusMessage =
            'Replaced. Match ${_currentMatchIndex + 1} of ${results.length}';
        _navigateToMatch(results[_currentMatchIndex]);
      }
    });
  }

  void _replaceAll() {
    final options = _buildOptions();
    if (options.query.isEmpty) return;

    final results = _engine.findAll(
      workbook: widget.state.workbook,
      activeSheetIndex: widget.state.activeSheetIndex,
      options: options,
    );

    if (results.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
        _statusMessage = 'No matches found to replace.';
      });
      return;
    }

    final cmd = ReplaceAllCommand(
      workbook: widget.state.workbook,
      matches: results,
      options: options,
      engine: widget.state.formulaEngine,
    );

    widget.state.executeCommand(cmd);

    setState(() {
      _matches = [];
      _currentMatchIndex = -1;
      _statusMessage = 'Replaced ${cmd.replacedCount} occurrence(s).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 8,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: AppColors.canvasWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.neutralBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Tab Bar
            _buildTabBar(),

            // Content Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputRow(
                    label: 'Find what:',
                    controller: _findController,
                    focusNode: _findFocusNode,
                    onSubmitted: (_) => _findNext(),
                  ),
                  if (_activeTab == 1) ...[
                    const SizedBox(height: 10),
                    _buildInputRow(
                      label: 'Replace with:',
                      controller: _replaceController,
                      onSubmitted: (_) => _replaceCurrent(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Option checkboxes (2x2 grid)
                  Row(
                    children: [
                      Expanded(
                        child: _checkbox(
                          'Match case',
                          _matchCase,
                          (v) => setState(() => _matchCase = v ?? false),
                        ),
                      ),
                      Expanded(
                        child: _checkbox(
                          'Entire cell only',
                          _matchEntireCell,
                          (v) => setState(() => _matchEntireCell = v ?? false),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _checkbox(
                          'Search workbook',
                          _searchWorkbook,
                          (v) => setState(() => _searchWorkbook = v ?? false),
                        ),
                      ),
                      Expanded(
                        child: _checkbox(
                          'Look in formulas',
                          _searchFormulas,
                          (v) => setState(() => _searchFormulas = v ?? false),
                        ),
                      ),
                    ],
                  ),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFontFamily,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.neutralBorder),

            // Action Buttons Footer
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.recessedChrome,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
        border: Border(bottom: BorderSide(color: AppColors.neutralBorder)),
      ),
      child: Row(
        children: [
          _tabButton('Find', 0),
          _tabButton('Replace', 1),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.canvasWhite : Colors.transparent,
          border: isActive
              ? const Border(
                  top: BorderSide(color: AppColors.primary, width: 2),
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 28,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: AppColors.neutralBorder),
                ),
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_activeTab == 1) ...[
            OutlinedButton(
              onPressed: _replaceAll,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Replace All'),
            ),
            OutlinedButton(
              onPressed: _replaceCurrent,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Replace'),
            ),
          ],
          OutlinedButton(
            onPressed: _findPrevious,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Find Prev'),
          ),
          ElevatedButton(
            onPressed: _findNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.canvasWhite,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Find Next'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
