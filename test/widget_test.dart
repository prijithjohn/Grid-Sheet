import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/main.dart';

void main() {
  testWidgets('GridSheetApp mounts and renders desktop shell components', (
    WidgetTester tester,
  ) async {
    final workbook = Workbook.createDefault();
    final state = WorkbookState(initialWorkbook: workbook);

    await tester.pumpWidget(GridSheetApp(state: state));
    await tester.pump();

    // Verify Title bar and branding
    expect(find.text('Grid Sheet'), findsWidgets);
    expect(find.text('Ready'), findsOneWidget);

    // Verify Formula bar name box starts at A1
    expect(find.text('A1'), findsOneWidget);

    // Verify initial sheet tab
    expect(find.text('Sheet1'), findsOneWidget);
  });
}
