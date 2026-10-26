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

/// Wraps children with spreadsheet desktop keyboard shortcut listeners.
class DesktopShortcuts extends StatelessWidget {
  const DesktopShortcuts({super.key, required this.state, required this.child});

  final WorkbookState state;
  final Widget child;

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
        SingleActivator(LogicalKeyboardKey.keyB, control: true): ToggleBoldIntent(),
        SingleActivator(LogicalKeyboardKey.keyI, control: true): ToggleItalicIntent(),
        SingleActivator(LogicalKeyboardKey.keyU, control: true): ToggleUnderlineIntent(),
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
          MoveCursorIntent: CallbackAction<MoveCursorIntent>(
            onInvoke: (intent) {
              final curr = state.selection.primaryCell;
              final newRow = (curr.row + intent.rowDelta).clamp(
                0,
                CellCoordinate.maxRows - 1,
              );
              final newCol = (curr.col + intent.colDelta).clamp(
                0,
                CellCoordinate.maxCols - 1,
              );
              state.selectCell(curr.copyWith(row: newRow, col: newCol));
              return null;
            },
          ),
          ExtendSelectionIntent: CallbackAction<ExtendSelectionIntent>(
            onInvoke: (intent) {
              final active = state.selection.activeRange.end;
              final newRow = (active.row + intent.rowDelta).clamp(
                0,
                CellCoordinate.maxRows - 1,
              );
              final newCol = (active.col + intent.colDelta).clamp(
                0,
                CellCoordinate.maxCols - 1,
              );
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
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
