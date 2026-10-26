/// Grid Sheet native workbook format constants and contract documentation.
///
/// File format: `.gsheet`
/// Encoding: UTF-8 JSON
/// Version history:
///   - 1: Initial format (Phase 06). Sparse cell representation.
library;

/// Current format version written to every saved file.
const int kGsheetFormatVersion = 1;

/// Minimum version that this reader can load without error.
const int kGsheetMinSupportedVersion = 1;

/// The file extension (without dot) for Grid Sheet workbooks.
const String kGsheetExtension = 'gsheet';

/// Top-level JSON keys.
const String kKeyVersion = 'version';
const String kKeySchemaVersion = 'schemaVersion';
const String kKeyWorkbook = 'workbook';
const String kKeyId = 'id';
const String kKeyTitle = 'title';
const String kKeyActiveSheet = 'activeSheet';
const String kKeySheets = 'sheets';
const String kKeyName = 'name';
const String kKeyCells = 'cells';
const String kKeyRow = 'r';
const String kKeyCol = 'c';
const String kKeyInput = 'input';
const String kKeyComputedValue = 'computed';
const String kKeyValType = 'type';
const String kKeyValValue = 'val';
const String kKeyColumnWidths = 'colWidths';
const String kKeyRowHeights = 'rowHeights';
const String kKeyStyle = 'style';

// Style keys
const String kKeyFontFamily = 'fontFamily';
const String kKeyFontSize = 'fontSize';
const String kKeyBold = 'bold';
const String kKeyItalic = 'italic';
const String kKeyUnderline = 'underline';
const String kKeyStrike = 'strike';
const String kKeyTextColor = 'textColor';
const String kKeyFillColor = 'fillColor';
const String kKeyHAlign = 'hAlign';
const String kKeyVAlign = 'vAlign';
const String kKeyWrapped = 'wrapped';
const String kKeyNumberFormat = 'numFmt';
const String kKeyNumFmtType = 'type';
const String kKeyNumFmtDecimals = 'decimals';
const String kKeyNumFmtCurrency = 'currency';
const String kKeyNumFmtThousands = 'thousands';
const String kKeyBorders = 'borders';
const String kKeyBorderTop = 'top';
const String kKeyBorderBottom = 'bottom';
const String kKeyBorderLeft = 'left';
const String kKeyBorderRight = 'right';
const String kKeyBorderStyle = 'style';
const String kKeyBorderColor = 'color';

// Recovery-specific keys
const String kKeyRecovery = 'recovery';
const String kKeySourcePath = 'sourcePath';
const String kKeySavedAt = 'savedAt';
const String kKeyDirty = 'dirty';
