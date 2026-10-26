import 'dart:convert';

import '../../domain/domain.dart';
import 'gsheet_format.dart';

/// Exception thrown when a workbook file cannot be loaded.
class WorkbookLoadException implements Exception {
  final String message;
  const WorkbookLoadException(this.message);

  @override
  String toString() => 'WorkbookLoadException: $message';
}

/// Serializes and deserializes [Workbook] objects to/from the `.gsheet` JSON format.
///
/// Only populated cells are serialized (sparse representation).
/// Style fields equal to their defaults are omitted to keep files compact.
class WorkbookSerializer {
  const WorkbookSerializer();

  // ---------------------------------------------------------------------------
  // Serialize
  // ---------------------------------------------------------------------------

  /// Encodes [workbook] to a UTF-8 JSON string in the `.gsheet` format.
  String encode(Workbook workbook) {
    final json = _workbookToJson(workbook);
    return jsonEncode({
      kKeySchemaVersion: kGsheetFormatVersion,
      kKeyVersion: kGsheetFormatVersion,
      kKeyWorkbook: json,
    });
  }

  Map<String, dynamic> _workbookToJson(Workbook workbook) {
    return {
      kKeyId: workbook.id,
      kKeyTitle: workbook.title,
      kKeyActiveSheet: workbook.activeSheetIndex,
      kKeySheets: workbook.sheets.map(_worksheetToJson).toList(),
    };
  }

  Map<String, dynamic> _worksheetToJson(Worksheet sheet) {
    final cells = <Map<String, dynamic>>[];
    for (final cell in sheet.populatedCells) {
      cells.add(_cellToJson(cell));
    }

    final json = <String, dynamic>{
      kKeyId: sheet.id,
      kKeyName: sheet.name,
      kKeyCells: cells,
    };

    // Only write custom dimensions if present
    if (sheet.customColumnWidths.isNotEmpty) {
      json[kKeyColumnWidths] = sheet.customColumnWidths.map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    if (sheet.customRowHeights.isNotEmpty) {
      json[kKeyRowHeights] = sheet.customRowHeights.map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    if (sheet.frozenRows > 0) {
      json['frozenRows'] = sheet.frozenRows;
    }
    if (sheet.frozenCols > 0) {
      json['frozenCols'] = sheet.frozenCols;
    }

    return json;
  }

  Map<String, dynamic> _cellToJson(Cell cell) {
    final json = <String, dynamic>{
      kKeyRow: cell.coordinate.row,
      kKeyCol: cell.coordinate.col,
      kKeyInput: cell.rawInput,
    };

    // Serialize computed value if non-empty
    if (cell.computedValue is! EmptyCellValue) {
      final computedJson = _computedValueToJson(cell.computedValue);
      if (computedJson != null) {
        json[kKeyComputedValue] = computedJson;
      }
    }

    // Serialize style only if non-default
    final style = cell.style;
    if (style != CellStyle.defaultStyle) {
      json[kKeyStyle] = _styleToJson(style);
    }

    return json;
  }

  Map<String, dynamic>? _computedValueToJson(CellValue val) {
    switch (val) {
      case NumberCellValue(:final value):
        return {kKeyValType: 'number', kKeyValValue: value};
      case TextCellValue(:final text):
        return {kKeyValType: 'text', kKeyValValue: text};
      case BooleanCellValue(:final value):
        return {kKeyValType: 'bool', kKeyValValue: value};
      case DateTimeCellValue(:final dateTime):
        return {
          kKeyValType: 'datetime',
          kKeyValValue: dateTime.toIso8601String(),
        };
      case ErrorCellValue(:final error):
        return {kKeyValType: 'error', kKeyValValue: error.name};
      case EmptyCellValue():
        return null;
    }
  }

  Map<String, dynamic> _styleToJson(CellStyle s) {
    final j = <String, dynamic>{};
    const d = CellStyle.defaultStyle;

    if (s.fontFamily != d.fontFamily) j[kKeyFontFamily] = s.fontFamily;
    if (s.fontSize != d.fontSize) j[kKeyFontSize] = s.fontSize;
    if (s.isBold) j[kKeyBold] = true;
    if (s.isItalic) j[kKeyItalic] = true;
    if (s.isUnderline) j[kKeyUnderline] = true;
    if (s.isStrikethrough) j[kKeyStrike] = true;
    if (s.textColor != d.textColor) j[kKeyTextColor] = s.textColor;
    if (s.fillColor != null) j[kKeyFillColor] = s.fillColor;
    if (s.horizontalAlignment != d.horizontalAlignment) {
      j[kKeyHAlign] = s.horizontalAlignment.name;
    }
    if (s.verticalAlignment != d.verticalAlignment) {
      j[kKeyVAlign] = s.verticalAlignment.name;
    }
    if (s.isWrapped) j[kKeyWrapped] = true;
    if (s.numberFormat != CellNumberFormat.general) {
      j[kKeyNumberFormat] = _numberFormatToJson(s.numberFormat);
    }
    if (s.borders != CellBorders.none) {
      j[kKeyBorders] = _bordersToJson(s.borders);
    }
    return j;
  }

  Map<String, dynamic> _numberFormatToJson(CellNumberFormat f) => {
    kKeyNumFmtType: f.type.name,
    kKeyNumFmtDecimals: f.decimalPlaces,
    kKeyNumFmtCurrency: f.currencySymbol,
    kKeyNumFmtThousands: f.useThousandsSeparator,
  };

  Map<String, dynamic> _bordersToJson(CellBorders b) {
    final j = <String, dynamic>{};
    if (b.top != CellBorderSide.none) {
      j[kKeyBorderTop] = _borderSideToJson(b.top);
    }
    if (b.bottom != CellBorderSide.none) {
      j[kKeyBorderBottom] = _borderSideToJson(b.bottom);
    }
    if (b.left != CellBorderSide.none) {
      j[kKeyBorderLeft] = _borderSideToJson(b.left);
    }
    if (b.right != CellBorderSide.none) {
      j[kKeyBorderRight] = _borderSideToJson(b.right);
    }
    return j;
  }

  Map<String, dynamic> _borderSideToJson(CellBorderSide side) => {
    kKeyBorderStyle: side.style.name,
    kKeyBorderColor: side.color,
  };

  // ---------------------------------------------------------------------------
  // Deserialize
  // ---------------------------------------------------------------------------

  /// Decodes a JSON [content] string to a [Workbook].
  ///
  /// Throws [WorkbookLoadException] on version mismatch, missing keys, or parse errors.
  Workbook decode(String content) {
    final dynamic raw;
    try {
      raw = jsonDecode(content);
    } catch (e) {
      throw const WorkbookLoadException('File is not valid JSON');
    }

    if (raw is! Map<String, dynamic>) {
      throw const WorkbookLoadException('Unexpected file structure');
    }

    // Version check (accepts schemaVersion or version)
    final version = raw[kKeySchemaVersion] ?? raw[kKeyVersion];
    if (version is! int) {
      throw const WorkbookLoadException('Missing or invalid format version');
    }
    if (version < kGsheetMinSupportedVersion ||
        version > kGsheetFormatVersion) {
      throw WorkbookLoadException(
        'Unsupported file version $version '
        '(supported: $kGsheetMinSupportedVersion–$kGsheetFormatVersion)',
      );
    }

    final wbJson = raw[kKeyWorkbook];
    if (wbJson is! Map<String, dynamic>) {
      throw const WorkbookLoadException('Missing workbook data');
    }

    return _workbookFromJson(wbJson);
  }

  Workbook _workbookFromJson(Map<String, dynamic> json) {
    final id = _requireString(json, kKeyId, 'workbook.id');
    final title = json[kKeyTitle] as String? ?? 'Untitled.gsheet';
    final activeSheetIndex = json[kKeyActiveSheet] as int? ?? 0;

    final sheetsRaw = json[kKeySheets];
    if (sheetsRaw is! List || sheetsRaw.isEmpty) {
      throw const WorkbookLoadException(
        'Workbook must contain at least one sheet',
      );
    }

    final sheets = <Worksheet>[];
    for (final s in sheetsRaw) {
      if (s is! Map<String, dynamic>) {
        throw const WorkbookLoadException('Invalid sheet entry in file');
      }
      sheets.add(_worksheetFromJson(s));
    }

    final workbook = Workbook(id: id, title: title, initialSheets: sheets);

    final clampedIndex = activeSheetIndex.clamp(0, sheets.length - 1);
    workbook.activeSheetIndex = clampedIndex;

    return workbook;
  }

  Worksheet _worksheetFromJson(Map<String, dynamic> json) {
    final id = _requireString(json, kKeyId, 'sheet.id');
    final name = _requireString(json, kKeyName, 'sheet.name');

    final sheet = Worksheet(id: id, name: name);

    // Cells
    final cellsRaw = json[kKeyCells];
    if (cellsRaw is List) {
      for (final c in cellsRaw) {
        if (c is! Map<String, dynamic>) continue;
        final cell = _cellFromJson(c);
        if (cell != null) sheet.setCell(cell);
      }
    }

    // Column widths
    final colWidths = json[kKeyColumnWidths];
    if (colWidths is Map) {
      for (final entry in colWidths.entries) {
        final col = int.tryParse(entry.key.toString());
        final width = (entry.value as num?)?.toDouble();
        if (col != null && width != null) {
          sheet.setColumnWidth(col, width);
        }
      }
    }

    // Row heights
    final rowHeights = json[kKeyRowHeights];
    if (rowHeights is Map) {
      for (final entry in rowHeights.entries) {
        final row = int.tryParse(entry.key.toString());
        final height = (entry.value as num?)?.toDouble();
        if (row != null && height != null) {
          sheet.setRowHeight(row, height);
        }
      }
    }

    final frozenRows = (json['frozenRows'] as num?)?.toInt() ?? 0;
    final frozenCols = (json['frozenCols'] as num?)?.toInt() ?? 0;
    if (frozenRows > 0 || frozenCols > 0) {
      sheet.freezePanes(rows: frozenRows, cols: frozenCols);
    }

    return sheet;
  }

  Cell? _cellFromJson(Map<String, dynamic> json) {
    final row = json[kKeyRow] as int?;
    final col = json[kKeyCol] as int?;
    final input = json[kKeyInput] as String?;

    if (row == null || col == null || input == null) return null;
    if (row < 0 || col < 0) return null;

    final coord = CellCoordinate(row, col);
    final styleJson = json[kKeyStyle];
    final style = styleJson is Map<String, dynamic>
        ? _styleFromJson(styleJson)
        : CellStyle.defaultStyle;

    final computedJson = json[kKeyComputedValue];
    final computed = computedJson is Map<String, dynamic>
        ? _computedValueFromJson(computedJson)
        : null;

    return Cell.fromInput(coord, input, style: style, computedValue: computed);
  }

  CellValue? _computedValueFromJson(Map<String, dynamic> j) {
    final type = j[kKeyValType] as String?;
    final val = j[kKeyValValue];
    switch (type) {
      case 'number':
        if (val is num) return NumberCellValue(val);
      case 'text':
        if (val is String) return TextCellValue(val);
      case 'bool':
        if (val is bool) return BooleanCellValue(val);
      case 'datetime':
        if (val is String) {
          final dt = DateTime.tryParse(val);
          if (dt != null) return DateTimeCellValue(dt);
        }
      case 'error':
        if (val is String) {
          final err = CellError.values.firstWhere(
            (e) => e.name == val,
            orElse: () => CellError.value,
          );
          return ErrorCellValue(err);
        }
    }
    return null;
  }

  CellStyle _styleFromJson(Map<String, dynamic> j) {
    return CellStyle(
      fontFamily:
          j[kKeyFontFamily] as String? ?? CellStyle.defaultStyle.fontFamily,
      fontSize:
          (j[kKeyFontSize] as num?)?.toDouble() ??
          CellStyle.defaultStyle.fontSize,
      isBold: j[kKeyBold] as bool? ?? false,
      isItalic: j[kKeyItalic] as bool? ?? false,
      isUnderline: j[kKeyUnderline] as bool? ?? false,
      isStrikethrough: j[kKeyStrike] as bool? ?? false,
      textColor: j[kKeyTextColor] as int? ?? CellStyle.defaultStyle.textColor,
      fillColor: j[kKeyFillColor] as int?,
      horizontalAlignment: _parseHAlign(j[kKeyHAlign] as String?),
      verticalAlignment: _parseVAlign(j[kKeyVAlign] as String?),
      isWrapped: j[kKeyWrapped] as bool? ?? false,
      numberFormat: _numberFormatFromJson(j[kKeyNumberFormat]),
      borders: _bordersFromJson(j[kKeyBorders]),
    );
  }

  CellHorizontalAlignment _parseHAlign(String? name) {
    return CellHorizontalAlignment.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CellHorizontalAlignment.general,
    );
  }

  CellVerticalAlignment _parseVAlign(String? name) {
    return CellVerticalAlignment.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CellVerticalAlignment.bottom,
    );
  }

  CellNumberFormat _numberFormatFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return CellNumberFormat.general;
    final type = NumberFormatType.values.firstWhere(
      (e) => e.name == raw[kKeyNumFmtType],
      orElse: () => NumberFormatType.general,
    );
    return CellNumberFormat(
      type: type,
      decimalPlaces: raw[kKeyNumFmtDecimals] as int? ?? 2,
      currencySymbol: raw[kKeyNumFmtCurrency] as String? ?? '\$',
      useThousandsSeparator: raw[kKeyNumFmtThousands] as bool? ?? true,
    );
  }

  CellBorders _bordersFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return CellBorders.none;
    return CellBorders(
      top: _borderSideFromJson(raw[kKeyBorderTop]),
      bottom: _borderSideFromJson(raw[kKeyBorderBottom]),
      left: _borderSideFromJson(raw[kKeyBorderLeft]),
      right: _borderSideFromJson(raw[kKeyBorderRight]),
    );
  }

  CellBorderSide _borderSideFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return CellBorderSide.none;
    final style = CellBorderStyle.values.firstWhere(
      (e) => e.name == raw[kKeyBorderStyle],
      orElse: () => CellBorderStyle.none,
    );
    return CellBorderSide(
      style: style,
      color: raw[kKeyBorderColor] as int? ?? 0xFFE3E7E4,
    );
  }

  String _requireString(Map<String, dynamic> json, String key, String context) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw WorkbookLoadException('Missing required field "$key" in $context');
    }
    return value;
  }
}
