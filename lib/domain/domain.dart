/// Grid Sheet Core Domain Model Barrel File
///
/// Pure Dart entities and aggregates for spreadsheet modeling:
/// - Coordinates and Ranges (`CellCoordinate`, `CellRange`)
/// - Cell values and styles (`Cell`, `CellValue`, `CellStyle`, `CellError`)
/// - Sparse matrix worksheets (`Worksheet`)
/// - Multi-sheet workbooks (`Workbook`)
library;

export 'cell/cell_coordinate.dart';
export 'cell/cell_model.dart';
export 'cell/cell_range.dart';
export 'cell/cell_style.dart';
export 'cell/cell_value.dart';
export 'workbook/workbook_model.dart';
export 'worksheet/worksheet_model.dart';
