import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/import_export/csv_engine.dart';
import '../../../data/import_export/csv_service.dart';

/// Result returned when the user confirms the CSV import dialog.
class CsvImportDialogResult {
  const CsvImportDialogResult({required this.file, required this.options});

  final File file;
  final CsvImportOptions options;
}

/// Interactive 20-row CSV/TSV import configuration and preview dialog.
///
/// Corresponds to Stitch Screen 16:
/// `file_workflow_csv_import_configuration_preview`.
class CsvImportDialog extends StatefulWidget {
  const CsvImportDialog({
    super.key,
    required this.file,
    required this.initialPreviewRows,
    required this.suggestedDelimiter,
  });

  final File file;
  final List<List<String>> initialPreviewRows;
  final CsvDelimiter suggestedDelimiter;

  /// Opens the dialog and awaits user confirmation.
  ///
  /// Returns [CsvImportDialogResult] on confirm, or `null` if cancelled.
  static Future<CsvImportDialogResult?> show(
    BuildContext context, {
    required File file,
    required List<List<String>> initialPreviewRows,
    required CsvDelimiter suggestedDelimiter,
  }) {
    return showDialog<CsvImportDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CsvImportDialog(
        file: file,
        initialPreviewRows: initialPreviewRows,
        suggestedDelimiter: suggestedDelimiter,
      ),
    );
  }

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  late CsvDelimiter _delimiter;
  late CsvEncoding _encoding;
  bool _firstRowIsHeader = false;
  CsvImportDestination _destination = CsvImportDestination.activeCell;
  late List<List<String>> _previewRows;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _delimiter = widget.suggestedDelimiter;
    _encoding = CsvEncoding.utf8;
    _previewRows = widget.initialPreviewRows;
  }

  Future<void> _reload() async {
    setState(() => _reloading = true);
    try {
      const engine = CsvEngine();
      final rows = await engine.parseFile(
        widget.file,
        delimiter: _delimiter,
        encoding: _encoding,
      );
      setState(() {
        _previewRows = rows.take(20).toList();
        _reloading = false;
      });
    } catch (_) {
      setState(() => _reloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.canvasWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 780,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOptions(),
                    const SizedBox(height: 16),
                    _buildPreviewTable(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final fileName = widget.file.path
        .replaceAll('\\', '/')
        .split('/')
        .last;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.table_chart_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import CSV / TSV',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _buildDelimiterSelector(),
        _buildEncodingSelector(),
        _buildDestinationSelector(),
        _buildHeaderCheckbox(),
      ],
    );
  }

  Widget _buildDelimiterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Delimiter'),
        const SizedBox(height: 4),
        DropdownButton<CsvDelimiter>(
          value: _delimiter,
          items: CsvDelimiter.values
              .map(
                (d) => DropdownMenuItem(value: d, child: Text(d.label)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null && v != _delimiter) {
              _delimiter = v;
              _reload();
            }
          },
          style: _dropdownStyle(),
          isDense: true,
        ),
      ],
    );
  }

  Widget _buildEncodingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Encoding'),
        const SizedBox(height: 4),
        DropdownButton<CsvEncoding>(
          value: _encoding,
          items: CsvEncoding.values
              .map(
                (e) => DropdownMenuItem(value: e, child: Text(e.label)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null && v != _encoding) {
              setState(() => _encoding = v);
              _reload();
            }
          },
          style: _dropdownStyle(),
          isDense: true,
        ),
      ],
    );
  }

  Widget _buildDestinationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Import Into'),
        const SizedBox(height: 4),
        DropdownButton<CsvImportDestination>(
          value: _destination,
          items: CsvImportDestination.values
              .map(
                (d) => DropdownMenuItem(value: d, child: Text(d.label)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _destination = v);
          },
          style: _dropdownStyle(),
          isDense: true,
        ),
      ],
    );
  }

  Widget _buildHeaderCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _firstRowIsHeader,
          onChanged: (v) => setState(() => _firstRowIsHeader = v ?? false),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Text(
          'First row contains column headers',
          style: _dropdownStyle(),
        ),
      ],
    );
  }

  Widget _buildPreviewTable() {
    if (_reloading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_previewRows.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const Text(
          'No data to preview.',
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final maxCols = _previewRows.fold<int>(
      0,
      (m, r) => r.length > m ? r.length : m,
    );

    final displayRows =
        _firstRowIsHeader && _previewRows.length > 1
            ? _previewRows.sublist(1)
            : _previewRows;

    final headers =
        _firstRowIsHeader && _previewRows.isNotEmpty
            ? _previewRows.first
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Preview (first ${displayRows.length} data rows)',
              style: const TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_previewRows.length} rows × $maxCols cols detected',
              style: const TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutralBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: headers != null ? 30 : 0,
              dataRowMinHeight: 22,
              dataRowMaxHeight: 24,
              columnSpacing: 12,
              horizontalMargin: 8,
              headingRowColor: WidgetStateProperty.all(
                AppColors.recessedChrome,
              ),
              columns: List.generate(
                maxCols,
                (i) => DataColumn(
                  label: Text(
                    headers != null && i < headers.length
                        ? headers[i]
                        : _colLetter(i),
                    style: const TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              rows: displayRows.map((row) {
                return DataRow(
                  cells: List.generate(
                    maxCols,
                    (c) => DataCell(
                      Text(
                        c < row.length ? row[c] : '',
                        style: const TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(
                CsvImportDialogResult(
                  file: widget.file,
                  options: CsvImportOptions(
                    delimiter: _delimiter,
                    encoding: _encoding,
                    firstRowIsHeader: _firstRowIsHeader,
                    destination: _destination,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.canvasWhite,
              textStyle: const TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppTypography.uiFontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );

  TextStyle _dropdownStyle() => const TextStyle(
    fontFamily: AppTypography.uiFontFamily,
    fontSize: 12,
    color: AppColors.textPrimary,
  );

  String _colLetter(int col) {
    var result = '';
    var n = col;
    do {
      result = String.fromCharCode(65 + n % 26) + result;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return result;
  }
}

/// Convenience widget integrating the [CsvService] workflow:
/// pick file → show preview dialog → execute import into [WorkbookState].
class CsvImportWorkflow {
  const CsvImportWorkflow({CsvService? service})
      : _service = service ?? const CsvService();

  final CsvService _service;

  /// Runs the full import workflow:
  /// 1. Opens a native file picker.
  /// 2. Shows the [CsvImportDialog] preview.
  /// 3. Imports data into [state].
  ///
  /// Returns [CsvOperationResult] describing the outcome.
  Future<CsvOperationResult> run(
    BuildContext context,
    WorkbookState state,
  ) async {
    final picked = await _service.pickAndPreview();
    if (picked == null) return CsvOperationResult.cancelled;
    if (!context.mounted) return CsvOperationResult.cancelled;

    final result = await CsvImportDialog.show(
      context,
      file: picked.file,
      initialPreviewRows: picked.preview,
      suggestedDelimiter: picked.suggested,
    );
    if (result == null) return CsvOperationResult.cancelled;

    return _service.importFile(result.file, state, options: result.options);
  }
}
