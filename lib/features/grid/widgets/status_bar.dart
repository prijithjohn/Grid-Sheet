import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/domain.dart';

/// Desktop status bar displaying calculation state, selection aggregates, and zoom.
class StatusBar extends StatefulWidget {
  const StatusBar({super.key, required this.state});

  final WorkbookState state;

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    final selection = widget.state.selection;
    final worksheet = widget.state.activeWorksheet;

    int cellCount = 0;
    double numericSum = 0;
    int numericCount = 0;

    // Calculate aggregates across the active selection range
    final range = selection.activeRange;
    if (range.cellCount <= 1000) {
      for (final coord in range.coordinates) {
        final cell = worksheet.getCell(coord);
        if (cell != null && cell.rawInput.trim().isNotEmpty) {
          cellCount++;
          final val = cell.value;
          if (val is NumberCellValue) {
            numericSum += val.value.toDouble();
            numericCount++;
          }
        }
      }
    } else {
      for (final cell in worksheet.populatedCells) {
        if (range.contains(cell.coordinate) &&
            cell.rawInput.trim().isNotEmpty) {
          cellCount++;
          final val = cell.value;
          if (val is NumberCellValue) {
            numericSum += val.value.toDouble();
            numericCount++;
          }
        }
      }
    }

    final hasAggregates = cellCount > 0;
    final average = numericCount > 0 ? numericSum / numericCount : 0.0;

    return Container(
      height: AppDimensions.statusBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.recessedChrome,
        border: Border(
          top: BorderSide(color: AppColors.neutralBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Ready State
          const Text('Ready', style: AppTypography.statusBar),
          const SizedBox(width: 16),

          // Selection Aggregates
          if (hasAggregates) ...[
            if (numericCount > 0) ...[
              _StatChip(label: 'Average', value: average.toStringAsFixed(2)),
              const SizedBox(width: 8),
            ],
            _StatChip(label: 'Count', value: cellCount.toString()),
            const SizedBox(width: 8),
            if (numericCount > 0) ...[
              _StatChip(label: 'Sum', value: numericSum.toStringAsFixed(2)),
              const SizedBox(width: 8),
            ],
          ],

          const Spacer(),

          // Zoom Controls
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: AppColors.primaryContainer,
                inactiveTrackColor: AppColors.neutralBorder,
                thumbColor: AppColors.primaryContainer,
              ),
              child: Slider(
                value: _zoomLevel,
                min: 0.5,
                max: 2.0,
                onChanged: (val) => setState(() => _zoomLevel = val),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(_zoomLevel * 100).toInt()}%',
            style: const TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.canvasWhite,
        border: Border.all(color: AppColors.neutralBorder, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: AppTypography.uiFontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
