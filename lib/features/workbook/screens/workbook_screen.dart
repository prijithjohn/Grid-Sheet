import 'package:flutter/material.dart';

import '../../../app/state/workbook_state.dart';
import '../../../core/keyboard/desktop_shortcuts.dart';
import '../../file_management/file_management.dart';
import '../../formula_bar/widgets/formula_bar.dart';
import '../../grid/widgets/grid_viewport.dart';
import '../../grid/widgets/status_bar.dart';
import '../../worksheets/widgets/sheet_tab_strip.dart';
import '../widgets/ribbon_bar.dart';
import '../widgets/window_title_bar.dart';

/// Master desktop spreadsheet workspace screen coordinating all chrome zones, grid,
/// and file persistence workflows.
class WorkbookScreen extends StatefulWidget {
  const WorkbookScreen({super.key, required this.state, this.fileController});

  final WorkbookState state;
  final FileWorkflowController? fileController;

  @override
  State<WorkbookScreen> createState() => _WorkbookScreenState();
}

class _WorkbookScreenState extends State<WorkbookScreen> {
  late final FileWorkflowController _fileController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.fileController != null) {
      _fileController = widget.fileController!;
      _ownsController = false;
    } else {
      _fileController = FileWorkflowController(state: widget.state);
      _ownsController = true;
    }

    // Check for crash recovery journals on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fileController.checkRecoveryOnStartup(context);
      }
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _fileController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (widget.state.isDirty) {
      final action = await UnsavedChangesDialog.show(
        context,
        fileName: widget.state.filePath ?? widget.state.title,
      );
      if (action == UnsavedChangesAction.cancel || action == null) {
        return;
      }
      if (action == UnsavedChangesAction.save) {
        if (!mounted) return;
        final saved = await _fileController.save(context: context);
        if (!saved) return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return DesktopShortcuts(
          state: widget.state,
          onSave: () => _fileController.save(context: context),
          onSaveAs: () => _fileController.saveAs(context: context),
          onOpen: () => _fileController.open(context: context),
          onNew: () => _fileController.newWorkbook(context: context),
          child: Scaffold(
            body: Column(
              children: [
                // 1. Title Command Bar (36px)
                WindowTitleBar(
                  state: widget.state,
                  onSave: () => _fileController.save(context: context),
                  onClose: _handleClose,
                ),

                // 2. Ribbon Command Bar (88px / 32px)
                RibbonBar(
                  state: widget.state,
                  onNew: () => _fileController.newWorkbook(context: context),
                  onOpen: () => _fileController.open(context: context),
                  onSave: () => _fileController.save(context: context),
                  onSaveAs: () => _fileController.saveAs(context: context),
                ),

                // 3. Formula Bar (28px)
                FormulaBar(state: widget.state),

                // 4. Main Spreadsheet Grid Canvas (Expanded)
                Expanded(child: GridViewport(state: widget.state)),

                // 5. Sheet Tab Strip (28px)
                SheetTabStrip(state: widget.state),

                // 6. Status Bar (22px)
                StatusBar(state: widget.state),
              ],
            ),
          ),
        );
      },
    );
  }
}
