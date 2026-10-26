import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// Tabbed ribbon command bar matching Stitch specifications.
///
/// Features expandable/collapsible toolbar groups, Undo/Redo integration,
/// and common formatting action clusters.
class RibbonBar extends StatefulWidget {
  const RibbonBar({
    super.key,
    required this.state,
    this.onNew,
    this.onOpen,
    this.onSave,
    this.onSaveAs,
  });

  final WorkbookState state;
  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;

  @override
  State<RibbonBar> createState() => _RibbonBarState();
}

class _RibbonBarState extends State<RibbonBar> {
  int _activeTabIndex = 1; // 0: File, 1: Home, 2: Insert, 3: View
  bool _isExpanded = true;

  final List<String> _tabs = const [
    'File',
    'Home',
    'Insert',
    'Page Layout',
    'Formulas',
    'Data',
    'View',
  ];

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.recessedChrome,
        border: Border(
          bottom: BorderSide(color: AppColors.neutralBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ribbon Tab Bar
          SizedBox(
            height: AppDimensions.ribbonTabHeight,
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  _RibbonTabHeader(
                    label: _tabs[i],
                    isActive: _activeTabIndex == i,
                    isFile: i == 0,
                    onTap: () {
                      if (_activeTabIndex == i && i != 0) {
                        _toggleExpanded();
                      } else {
                        setState(() {
                          _activeTabIndex = i;
                          _isExpanded = true;
                        });
                      }
                    },
                  ),
                const Spacer(),
                // Collapse / Expand toggle button
                IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: _isExpanded
                      ? 'Collapse Ribbon (Ctrl+F1)'
                      : 'Pin Ribbon (Ctrl+F1)',
                  onPressed: _toggleExpanded,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // Ribbon Action Panel
          if (_isExpanded)
            Container(
              height: AppDimensions.ribbonActionHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.canvasWhite,
                border: Border(
                  top: BorderSide(color: AppColors.neutralBorder, width: 0.5),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _activeTabIndex == 0
                    ? _buildFileActions()
                    : Row(
                        children: [
                          // Undo / Redo Quick Cluster
                          _RibbonActionButton(
                            icon: Icons.undo,
                            label: 'Undo',
                            tooltip: 'Undo (Ctrl+Z)',
                            enabled: widget.state.canUndo,
                            onPressed: widget.state.canUndo
                                ? widget.state.undo
                                : null,
                          ),
                          _RibbonActionButton(
                            icon: Icons.redo,
                            label: 'Redo',
                            tooltip: 'Redo (Ctrl+Y)',
                            enabled: widget.state.canRedo,
                            onPressed: widget.state.canRedo
                                ? widget.state.redo
                                : null,
                          ),

                          _RibbonDivider(),

                          // Clipboard Cluster
                          _RibbonActionButton(
                            icon: Icons.content_paste,
                            label: 'Paste',
                            tooltip: 'Paste (Ctrl+V)',
                            onPressed: () {},
                          ),
                          _RibbonActionButton(
                            icon: Icons.content_cut,
                            label: 'Cut',
                            tooltip: 'Cut (Ctrl+X)',
                            onPressed: () {},
                          ),
                          _RibbonActionButton(
                            icon: Icons.content_copy,
                            label: 'Copy',
                            tooltip: 'Copy (Ctrl+C)',
                            onPressed: () {},
                          ),

                          _RibbonDivider(),

                          // Quick Formatting Cluster
                          _RibbonActionButton(
                            icon: Icons.format_bold,
                            label: 'Bold',
                            tooltip: 'Bold (Ctrl+B)',
                            onPressed: () {
                              widget.state.applyStyleToSelection(
                                (curr) => curr.copyWith(isBold: !curr.isBold),
                              );
                            },
                          ),
                          _RibbonActionButton(
                            icon: Icons.format_italic,
                            label: 'Italic',
                            tooltip: 'Italic (Ctrl+I)',
                            onPressed: () {
                              widget.state.applyStyleToSelection(
                                (curr) =>
                                    curr.copyWith(isItalic: !curr.isItalic),
                              );
                            },
                          ),
                          _RibbonActionButton(
                            icon: Icons.format_underlined,
                            label: 'Underline',
                            tooltip: 'Underline (Ctrl+U)',
                            onPressed: () {
                              widget.state.applyStyleToSelection(
                                (curr) => curr.copyWith(
                                  isUnderline: !curr.isUnderline,
                                ),
                              );
                            },
                          ),

                          _RibbonDivider(),

                          // Alignment Cluster
                          _RibbonActionButton(
                            icon: Icons.format_align_left,
                            label: 'Left',
                            tooltip: 'Align Left',
                            onPressed: () {
                              widget.state.applyStyleToSelection(
                                (curr) => curr.copyWith(
                                  horizontalAlignment:
                                      CellHorizontalAlignment.left,
                                ),
                              );
                            },
                          ),
                          _RibbonActionButton(
                            icon: Icons.format_align_center,
                            label: 'Center',
                            tooltip: 'Align Center',
                            onPressed: () {
                              widget.state.applyStyleToSelection(
                                (curr) => curr.copyWith(
                                  horizontalAlignment:
                                      CellHorizontalAlignment.center,
                                ),
                              );
                            },
                          ),
                          _RibbonActionButton(
                            icon: Icons.format_align_right,
                            label: 'Right',
                            tooltip: 'Align Right',
                            onPressed: () {
                              widget.state.applyStyleToSelection(
                                (curr) => curr.copyWith(
                                  horizontalAlignment:
                                      CellHorizontalAlignment.right,
                                ),
                              );
                            },
                          ),

                          _RibbonDivider(),

                          // Editing Actions
                          _RibbonActionButton(
                            icon: Icons.clear_all,
                            label: 'Clear',
                            tooltip: 'Clear Selected Cells (Delete)',
                            onPressed: widget.state.clearSelection,
                          ),
                          _RibbonActionButton(
                            icon: Icons.functions,
                            label: 'AutoSum',
                            tooltip: 'AutoSum (=SUM(...))',
                            onPressed: () {
                              widget.state.editActiveCell('=SUM(A1:A10)');
                            },
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileActions() {
    return Row(
      children: [
        _RibbonActionButton(
          key: const Key('ribbon_file_new_button'),
          icon: Icons.note_add_outlined,
          label: 'New',
          tooltip: 'New Workbook (Ctrl+N)',
          onPressed: widget.onNew,
        ),
        _RibbonActionButton(
          key: const Key('ribbon_file_open_button'),
          icon: Icons.folder_open_outlined,
          label: 'Open',
          tooltip: 'Open Workbook (Ctrl+O)',
          onPressed: widget.onOpen,
        ),
        _RibbonDivider(),
        _RibbonActionButton(
          key: const Key('ribbon_file_save_button'),
          icon: Icons.save_outlined,
          label: 'Save',
          tooltip: 'Save (Ctrl+S)',
          onPressed: widget.onSave,
        ),
        _RibbonActionButton(
          key: const Key('ribbon_file_save_as_button'),
          icon: Icons.save_as_outlined,
          label: 'Save As',
          tooltip: 'Save As (Ctrl+Shift+S)',
          onPressed: widget.onSaveAs,
        ),
      ],
    );
  }
}

class _RibbonTabHeader extends StatelessWidget {
  const _RibbonTabHeader({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isFile = false,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isFile;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color fg = AppColors.textPrimary;

    if (isFile) {
      bg = AppColors.primary;
      fg = AppColors.canvasWhite;
    } else if (isActive) {
      bg = AppColors.canvasWhite;
      fg = AppColors.primary;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppDimensions.ribbonTabHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: isActive && !isFile
              ? const Border(
                  top: BorderSide(color: AppColors.primary, width: 2),
                  left: BorderSide(color: AppColors.neutralBorder, width: 0.5),
                  right: BorderSide(color: AppColors.neutralBorder, width: 0.5),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 12,
            fontWeight: isActive || isFile ? FontWeight.w600 : FontWeight.w400,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _RibbonActionButton extends StatelessWidget {
  const _RibbonActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.4);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: effectiveColor),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 10,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.neutralBorder,
    );
  }
}
