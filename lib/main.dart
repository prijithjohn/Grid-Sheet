import 'package:flutter/material.dart';

import 'app/state/workbook_state.dart';
import 'core/theme/app_theme.dart';
import 'domain/domain.dart';
import 'features/workbook/screens/workbook_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Create initial demo workbook with corporate sample data matching Stitch Screen 1
  final workbook = Workbook.createDefault(title: 'Expenses 2024.gsheet');
  final sheet = workbook.activeSheet;
  sheet.name = 'Expenses 2024';

  // Header row (Row 0 = spreadsheet Row 1, Col 0..3 = A..D)
  sheet.setCell(
    CellModel.fromInput(
      const CellCoordinate(0, 0),
      'Category',
      style: const CellStyle(isBold: true, fillColor: 0xFFE2F0D9),
    ),
  );
  sheet.setCell(
    CellModel.fromInput(
      const CellCoordinate(0, 1),
      'Budget',
      style: const CellStyle(
        isBold: true,
        fillColor: 0xFFE2F0D9,
        horizontalAlignment: CellHorizontalAlignment.right,
      ),
    ),
  );
  sheet.setCell(
    CellModel.fromInput(
      const CellCoordinate(0, 2),
      'Actual',
      style: const CellStyle(
        isBold: true,
        fillColor: 0xFFE2F0D9,
        horizontalAlignment: CellHorizontalAlignment.right,
      ),
    ),
  );
  sheet.setCell(
    CellModel.fromInput(
      const CellCoordinate(0, 3),
      'Variance',
      style: const CellStyle(
        isBold: true,
        fillColor: 0xFFE2F0D9,
        horizontalAlignment: CellHorizontalAlignment.right,
      ),
    ),
  );

  // Sample data rows (Rows 1..5 = spreadsheet Rows 2..6)
  final sampleData = [
    ['Marketing & Ads', '12500', '11800', '700'],
    ['Engineering Cloud', '8400', '8950', '-550'],
    ['Office Lease', '6200', '6200', '0'],
    ['Travel & Events', '3100', '2850', '250'],
    ['Software Licenses', '4500', '4620', '-120'],
  ];

  for (int r = 0; r < sampleData.length; r++) {
    final rowIdx = r + 1;
    sheet.setCell(
      CellModel.fromInput(CellCoordinate(rowIdx, 0), sampleData[r][0]),
    );
    sheet.setCell(
      CellModel.fromInput(
        CellCoordinate(rowIdx, 1),
        sampleData[r][1],
        style: const CellStyle(
          horizontalAlignment: CellHorizontalAlignment.right,
        ),
      ),
    );
    sheet.setCell(
      CellModel.fromInput(
        CellCoordinate(rowIdx, 2),
        sampleData[r][2],
        style: const CellStyle(
          horizontalAlignment: CellHorizontalAlignment.right,
        ),
      ),
    );
    sheet.setCell(
      CellModel.fromInput(
        CellCoordinate(rowIdx, 3),
        sampleData[r][3],
        style: const CellStyle(
          horizontalAlignment: CellHorizontalAlignment.right,
        ),
      ),
    );
  }

  // Adjust column widths for content (0-indexed)
  sheet.setColumnWidth(0, 160.0);
  sheet.setColumnWidth(1, 100.0);
  sheet.setColumnWidth(2, 100.0);
  sheet.setColumnWidth(3, 100.0);

  // Additional worksheets
  workbook.createSheet(name: 'Q3 Summary');
  workbook.createSheet(name: 'Raw Invoices');

  final workbookState = WorkbookState(initialWorkbook: workbook);

  runApp(GridSheetApp(state: workbookState));
}

/// Root application widget for Grid Sheet.
class GridSheetApp extends StatelessWidget {
  const GridSheetApp({super.key, required this.state});

  final WorkbookState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grid Sheet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: WorkbookScreen(state: state),
    );
  }
}
