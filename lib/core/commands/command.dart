/// Grid Sheet Command Interface
///
/// Base contract for all reversible user actions within the application.
/// Follows the Command Pattern to support bidirectional Undo and Redo.
abstract class Command {
  /// User-visible description of the action (e.g. "Edit Cell A1", "Clear Selection").
  String get description;

  /// Whether this command can currently be executed.
  bool get canExecute => true;

  /// Executes the command, mutating the targeted state.
  void execute();

  /// Reverts the mutations made by [execute], restoring the previous state.
  void undo();
}
