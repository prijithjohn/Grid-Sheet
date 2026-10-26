import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/keyboard/desktop_shortcuts.dart';
import '../../formula_bar/widgets/formula_bar.dart';
import '../../grid/widgets/grid_viewport.dart';
import '../../grid/widgets/status_bar.dart';
import '../../worksheets/widgets/sheet_tab_strip.dart';
import '../widgets/ribbon_bar.dart';
import '../widgets/window_title_bar.dart';

/// Master desktop spreadsheet workspace screen coordinating all 5 chrome zones and grid.
class WorkbookScreen extends StatelessWidget {
  const WorkbookScreen({super.key, required this.state});

  final WorkbookState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return DesktopShortcuts(
          state: state,
          child: Scaffold(
            body: Column(
              children: [
                // 1. Title Command Bar (36px)
                WindowTitleBar(state: state),

                // 2. Ribbon Command Bar (88px / 32px)
                RibbonBar(state: state),

                // 3. Formula Bar (28px)
                FormulaBar(state: state),

                // 4. Main Spreadsheet Grid Canvas (Expanded)
                Expanded(child: GridViewport(state: state)),

                // 5. Sheet Tab Strip (28px)
                SheetTabStrip(state: state),

                // 6. Status Bar (22px)
                StatusBar(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}
