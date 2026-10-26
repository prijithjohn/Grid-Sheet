import 'command.dart';

/// Manages the Undo and Redo history stack for Grid Sheet commands.
///
/// Features:
/// - Configurable maximum history depth (defaults to 100).
/// - History branch eviction: executing a new command clears the redo stack.
/// - Change notification callbacks when stack capability changes.
class CommandStack {
  /// Creates a [CommandStack] with an optional [maxDepth] limit.
  CommandStack({this.maxDepth = 100})
    : assert(maxDepth > 0, 'maxDepth must be greater than 0');

  /// Maximum number of undoable commands stored in history.
  final int maxDepth;

  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final List<void Function()> _listeners = [];

  /// Returns an unmodifiable view of commands currently on the undo stack.
  List<Command> get undoStack => List.unmodifiable(_undoStack);

  /// Returns an unmodifiable view of commands currently on the redo stack.
  List<Command> get redoStack => List.unmodifiable(_redoStack);

  /// Number of commands currently available to undo.
  int get undoCount => _undoStack.length;

  /// Number of commands currently available to redo.
  int get redoCount => _redoStack.length;

  /// Whether an undo operation can currently be performed.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether a redo operation can currently be performed.
  bool get canRedo => _redoStack.isNotEmpty;

  /// The description of the next command to be undone, or `null` if none.
  String? get nextUndoDescription =>
      canUndo ? _undoStack.last.description : null;

  /// The description of the next command to be redone, or `null` if none.
  String? get nextRedoDescription =>
      canRedo ? _redoStack.last.description : null;

  /// Executes [command], pushes it onto the undo stack, and clears the redo stack.
  ///
  /// If [command.canExecute] is false, execution is skipped.
  /// If the undo stack exceeds [maxDepth], the oldest command is evicted.
  void execute(Command command) {
    if (!command.canExecute) return;

    command.execute();
    _undoStack.add(command);
    _redoStack.clear();

    if (_undoStack.length > maxDepth) {
      _undoStack.removeAt(0);
    }

    _notifyListeners();
  }

  /// Reverts the most recent command on the undo stack and moves it to the redo stack.
  ///
  /// Returns the undone [Command], or `null` if the undo stack is empty.
  Command? undo() {
    if (!canUndo) return null;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    _notifyListeners();
    return command;
  }

  /// Re-executes the most recently undone command and moves it back to the undo stack.
  ///
  /// Returns the redone [Command], or `null` if the redo stack is empty.
  Command? redo() {
    if (!canRedo) return null;

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);

    _notifyListeners();
    return command;
  }

  /// Clears all undo and redo history.
  void clear() {
    if (_undoStack.isEmpty && _redoStack.isEmpty) return;
    _undoStack.clear();
    _redoStack.clear();
    _notifyListeners();
  }

  /// Registers a [listener] callback to be notified when the stack state changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Unregisters a previously registered [listener] callback.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }
}
