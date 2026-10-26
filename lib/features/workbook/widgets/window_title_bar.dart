import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Custom Windows title command bar matching Stitch Screen 1.
///
/// Displays application branding, document name, unsaved changes indicator,
/// command search bar, and desktop window controls.
class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    super.key,
    required this.state,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
    this.onSave,
  });

  final WorkbookState state;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final fileName = state.filePath != null
            ? state.filePath!.split(RegExp(r'[\\/]')).last
            : (state.title.isNotEmpty ? state.title : 'Untitled.gsheet');

        return Container(
          height: AppDimensions.titleBarHeight,
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // App Logo / Monogram
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.canvasWhite,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'G',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // App Title
              const Text(
                'Grid Sheet',
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.canvasWhite,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 12),

              // Divider
              Container(
                height: 14,
                width: 1,
                color: AppColors.canvasWhite.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),

              // Quick Access Save
              if (onSave != null) ...[
                Tooltip(
                  message: 'Save (Ctrl+S)',
                  child: InkWell(
                    key: const Key('quick_save_button'),
                    onTap: onSave,
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.save_outlined,
                        size: 15,
                        color: AppColors.canvasWhite.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // File Name & Dirty Indicator
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.canvasWhite,
                        ),
                      ),
                    ),
                    if (state.isDirty) ...[
                      const SizedBox(width: 6),
                      Container(
                        key: const Key('dirty_indicator'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepGreen,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: AppColors.canvasWhite.withValues(alpha: 0.4),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          'Edited',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.canvasWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Command Search Palette Trigger (Stitch Alt+Q)
              Container(
                width: 180,
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: AppColors.canvasWhite.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 13,
                      color: AppColors.canvasWhite.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tell me what you want to do (Alt+Q)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 10,
                          color: AppColors.canvasWhite.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Window Caption Controls
              _WindowCaptionButton(
                icon: Icons.remove,
                tooltip: 'Minimize',
                onPressed: onMinimize,
              ),
              _WindowCaptionButton(
                icon: Icons.crop_square,
                tooltip: 'Maximize',
                onPressed: onMaximize,
              ),
              _WindowCaptionButton(
                icon: Icons.close,
                tooltip: 'Close',
                isClose: true,
                onPressed: onClose,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WindowCaptionButton extends StatefulWidget {
  const _WindowCaptionButton({
    required this.icon,
    required this.tooltip,
    this.isClose = false,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isClose;
  final VoidCallback? onPressed;

  @override
  State<_WindowCaptionButton> createState() => _WindowCaptionButtonState();
}

class _WindowCaptionButtonState extends State<_WindowCaptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    if (_isHovered) {
      bg = widget.isClose
          ? const Color(0xFFE81123)
          : AppColors.canvasWhite.withValues(alpha: 0.15);
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 32,
            height: AppDimensions.titleBarHeight,
            color: bg,
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 13, color: AppColors.canvasWhite),
          ),
        ),
      ),
    );
  }
}
