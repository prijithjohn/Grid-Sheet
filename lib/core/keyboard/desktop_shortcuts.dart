import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/state/workbook_state.dart';
import '../../domain/domain.dart';

// Intents
class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class MoveCursorIntent extends Intent {
  const MoveCursorIntent({required this.rowDelta, required this.colDelta});
  final int rowDelta;
  final int colDelta;
}

class ExtendSelectionIntent extends Intent {
  const ExtendSelectionIntent({required this.rowDelta, required this.colDelta});
  final int rowDelta;
  final int colDelta;
}

class ToggleBoldIntent extends Intent {
  const ToggleBoldIntent();
}

class ToggleItalicIntent extends Intent {
  const ToggleItalicIntent();
}

class ToggleUnderlineIntent extends Intent {
  const ToggleUnderlineIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SaveAsIntent extends Intent {
  const SaveAsIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class NewWorkbookIntent extends Intent {
  const NewWorkbookIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class CutIntent extends Intent {
  const CutIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class FindIntent extends Intent {
  const FindIntent();
}

class ReplaceIntent extends Intent {
  const ReplaceIntent();
}

class FillDownIntent extends Intent {
  const FillDownIntent();
}

class FillRightIntent extends Intent {
  const FillRightIntent();
}

/// Wraps children with spreadsheet desktop keyboard shortcut listeners.
class DesktopShortcuts extends StatelessWidget {
  const DesktopShortcuts({
    super.key,
    required this.state,
    required this.child,
    this.onSave,
    this.onSaveAs,
    this.onOpen,
    this.onNew,
    this.onCopy,
    this.onCut,
    this.onPaste,
    this.onFind,
    this.onReplace,
    this.onFillDown,
    this.onFillRight,
  });

  final WorkbookState state;
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;
  final VoidCallback? onOpen;
  final VoidCallback? onNew;
  final VoidCallback? onCopy;
  final VoidCallback? onCut;
  final VoidCallback? onPaste;
  final VoidCallback? onFind;
  final VoidCallback? onReplace;
  final VoidCallback? onFillDown;
  final VoidCallback? onFillRight;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // Undo / Redo
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            RedoIntent(),

        // Selection & Clear
        SingleActivator(LogicalKeyboardKey.delete): ClearSelectionIntent(),
        SingleActivator(LogicalKeyboardKey.backspace): ClearSelectionIntent(),
        SingleActivator(LogicalKeyboardKey.keyA, control: true):
            SelectAllIntent(),

        // Cursor Navigation
        SingleActivator(LogicalKeyboardKey.arrowUp): MoveCursorIntent(
          rowDelta: -1,
          colDelta: 0,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown): MoveCursorIntent(
          rowDelta: 1,
          colDelta: 0,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): MoveCursorIntent(
          rowDelta: 0,
          colDelta: -1,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): MoveCursorIntent(
          rowDelta: 0,
          colDelta: 1,
        ),
        SingleActivator(LogicalKeyboardKey.tab): MoveCursorIntent(
          rowDelta: 0,
          colDelta: 1,
        ),
        SingleActivator(LogicalKeyboardKey.tab, shift: true): MoveCursorIntent(
          rowDelta: 0,
          colDelta: -1,
        ),
        SingleActivator(LogicalKeyboardKey.enter): MoveCursorIntent(
          rowDelta: 1,
          colDelta: 0,
        ),
        SingleActivator(LogicalKeyboardKey.enter, shift: true):
            MoveCursorIntent(rowDelta: -1, colDelta: 0),

        // Range Extension
        SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            ExtendSelectionIntent(rowDelta: -1, colDelta: 0),
        SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            ExtendSelectionIntent(rowDelta: 1, colDelta: 0),
        SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            ExtendSelectionIntent(rowDelta: 0, colDelta: -1),
        SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            ExtendSelectionIntent(rowDelta: 0, colDelta: 1),

        // Formatting
        SingleActivator(LogicalKeyboardKey.keyB, control: true):
            ToggleBoldIntent(),
        SingleActivator(LogicalKeyboardKey.keyI, control: true):
            ToggleItalicIntent(),
        SingleActivator(LogicalKeyboardKey.keyU, control: true):
            ToggleUnderlineIntent(),

        // File Operations
        SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true):
            SaveAsIntent(),
        SingleActivator(LogicalKeyboardKey.keyO, control: true): OpenIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true):
            NewWorkbookIntent(),

        // Clipboard
        SingleActivator(LogicalKeyboardKey.keyC, control: true): CopyIntent(),
        SingleActivator(LogicalKeyboardKey.keyX, control: true): CutIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteIntent(),

        // Workflows: Find, Replace, Fill Down, Fill Right
        SingleActivator(LogicalKeyboardKey.keyF, control: true): FindIntent(),
        SingleActivator(LogicalKeyboardKey.keyH, control: true):
            ReplaceIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, control: true):
            FillDownIntent(),
        SingleActivator(LogicalKeyboardKey.keyR, control: true):
            FillRightIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => state.undo()),
          RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => state.redo()),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) => state.clearSelection(),
          ),
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (_) => state.selectAll(),
          ),
          FindIntent: CallbackAction<FindIntent>(
            onInvoke: (_) {
              onFind?.call();
              return null;
            },
          ),
          ReplaceIntent: CallbackAction<ReplaceIntent>(
            onInvoke: (_) {
              onReplace?.call();
              return null;
            },
          ),
          FillDownIntent: CallbackAction<FillDownIntent>(
            onInvoke: (_) {
              if (onFillDown != null) {
                onFillDown!();
              } else {
                state.fillDownSelection();
              }
              return null;
            },
          ),
          FillRightIntent: CallbackAction<FillRightIntent>(
            onInvoke: (_) {
              if (onFillRight != null) {
                onFillRight!();
              } else {
                state.fillRightSelection();
              }
              return null;
            },
          ),
          MoveCursorIntent: CallbackAction<MoveCursorIntent>(
            onInvoke: (intent) {
              final curr = state.selection.primaryCell;
              var newRow = (curr.row + intent.rowDelta).clamp(
                0,
                CellCoordinate.maxRows - 1,
              );
              final newCol = (curr.col + intent.colDelta).clamp(
                0,
                CellCoordinate.maxCols - 1,
              );

              // Skip hidden rows
              if (intent.rowDelta != 0) {
                final sheet = state.activeWorksheet;
                while (sheet.isRowHidden(newRow) &&
                    newRow > 0 &&
                    newRow < CellCoordinate.maxRows - 1) {
                  newRow += intent.rowDelta > 0 ? 1 : -1;
                }
              }

              state.selectCell(curr.copyWith(row: newRow, col: newCol));
              return null;
            },
          ),
          ExtendSelectionIntent: CallbackAction<ExtendSelectionIntent>(
            onInvoke: (intent) {
              final active = state.selection.activeRange.end;
              var newRow = (active.row + intent.rowDelta).clamp(
                0,
                CellCoordinate.maxRows - 1,
              );
              final newCol = (active.col + intent.colDelta).clamp(
                0,
                CellCoordinate.maxCols - 1,
              );

              // Skip hidden rows
              if (intent.rowDelta != 0) {
                final sheet = state.activeWorksheet;
                while (sheet.isRowHidden(newRow) &&
                    newRow > 0 &&
                    newRow < CellCoordinate.maxRows - 1) {
                  newRow += intent.rowDelta > 0 ? 1 : -1;
                }
              }

              state.extendSelection(active.copyWith(row: newRow, col: newCol));
              return null;
            },
          ),
          ToggleBoldIntent: CallbackAction<ToggleBoldIntent>(
            onInvoke: (_) {
              state.applyStyleToSelection(
                (curr) => curr.copyWith(isBold: !curr.isBold),
                description: 'Toggle Bold',
              );
              return null;
            },
          ),
          ToggleItalicIntent: CallbackAction<ToggleItalicIntent>(
            onInvoke: (_) {
              state.applyStyleToSelection(
                (curr) => curr.copyWith(isItalic: !curr.isItalic),
                description: 'Toggle Italic',
              );
              return null;
            },
          ),
          ToggleUnderlineIntent: CallbackAction<ToggleUnderlineIntent>(
            onInvoke: (_) {
              state.applyStyleToSelection(
                (curr) => curr.copyWith(isUnderline: !curr.isUnderline),
                description: 'Toggle Underline',
              );
              return null;
            },
          ),
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (_) {
              onSave?.call();
              return null;
            },
          ),
          SaveAsIntent: CallbackAction<SaveAsIntent>(
            onInvoke: (_) {
              onSaveAs?.call();
              return null;
            },
          ),
          OpenIntent: CallbackAction<OpenIntent>(
            onInvoke: (_) {
              onOpen?.call();
              return null;
            },
          ),
          NewWorkbookIntent: CallbackAction<NewWorkbookIntent>(
            onInvoke: (_) {
              onNew?.call();
              return null;
            },
          ),
          CopyIntent: CallbackAction<CopyIntent>(
            onInvoke: (_) {
              onCopy?.call();
              return null;
            },
          ),
          CutIntent: CallbackAction<CutIntent>(
            onInvoke: (_) {
              onCut?.call();
              return null;
            },
          ),
          PasteIntent: CallbackAction<PasteIntent>(
            onInvoke: (_) {
              onPaste?.call();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
