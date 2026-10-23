import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/core/commands/commands.dart';

class _MockCommand implements Command {
  _MockCommand(this.name, {this.executable = true});

  final String name;
  final bool executable;
  int executeCount = 0;
  int undoCount = 0;

  @override
  String get description => 'Mock $name';

  @override
  bool get canExecute => executable;

  @override
  void execute() {
    executeCount++;
  }

  @override
  void undo() {
    undoCount++;
  }
}

void main() {
  group('CommandStack - Lifecycle & Invariants', () {
    test('initializes empty with zero undo and redo capability', () {
      final stack = CommandStack();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
      expect(stack.undoCount, equals(0));
      expect(stack.redoCount, equals(0));
      expect(stack.nextUndoDescription, isNull);
      expect(stack.nextRedoDescription, isNull);
      expect(stack.undoStack, isEmpty);
      expect(stack.redoStack, isEmpty);
    });

    test('executes command and adds it to undo stack', () {
      final stack = CommandStack();
      final cmd = _MockCommand('Action 1');

      stack.execute(cmd);

      expect(cmd.executeCount, equals(1));
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);
      expect(stack.undoCount, equals(1));
      expect(stack.nextUndoDescription, equals('Mock Action 1'));
    });

    test('undo reverts command and enables redo', () {
      final stack = CommandStack();
      final cmd = _MockCommand('Action 1');
      stack.execute(cmd);

      final undone = stack.undo();

      expect(undone, same(cmd));
      expect(cmd.undoCount, equals(1));
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isTrue);
      expect(stack.redoCount, equals(1));
      expect(stack.nextRedoDescription, equals('Mock Action 1'));
    });

    test('redo re-executes command and restores undo', () {
      final stack = CommandStack();
      final cmd = _MockCommand('Action 1');
      stack.execute(cmd);
      stack.undo();

      final redone = stack.redo();

      expect(redone, same(cmd));
      expect(cmd.executeCount, equals(2));
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);
      expect(stack.undoCount, equals(1));
    });

    test('undo and redo on empty stack returns null gracefully', () {
      final stack = CommandStack();
      expect(stack.undo(), isNull);
      expect(stack.redo(), isNull);
    });

    test('ignores command execution when canExecute is false', () {
      final stack = CommandStack();
      final cmd = _MockCommand('Disabled', executable: false);

      stack.execute(cmd);

      expect(cmd.executeCount, equals(0));
      expect(stack.canUndo, isFalse);
      expect(stack.undoCount, equals(0));
    });
  });

  group('CommandStack - Branching & Depth Bounds', () {
    test(
      'executing new command after undo clears redo stack (branch eviction)',
      () {
        final stack = CommandStack();
        final cmd1 = _MockCommand('1');
        final cmd2 = _MockCommand('2');
        final cmd3 = _MockCommand('3');

        stack.execute(cmd1);
        stack.execute(cmd2);
        expect(stack.undoCount, equals(2));

        stack.undo(); // undo cmd2 -> cmd2 on redo
        expect(stack.canRedo, isTrue);

        stack.execute(cmd3); // Branch history: cmd2 discarded
        expect(stack.canRedo, isFalse);
        expect(stack.redoCount, equals(0));
        expect(stack.undoCount, equals(2));
        expect(stack.nextUndoDescription, equals('Mock 3'));
      },
    );

    test('evicts oldest command when maxDepth threshold is exceeded', () {
      final stack = CommandStack(maxDepth: 3);
      final c1 = _MockCommand('1');
      final c2 = _MockCommand('2');
      final c3 = _MockCommand('3');
      final c4 = _MockCommand('4');

      stack.execute(c1);
      stack.execute(c2);
      stack.execute(c3);
      expect(stack.undoCount, equals(3));

      stack.execute(c4);
      expect(stack.undoCount, equals(3));
      expect(stack.undoStack, containsAllInOrder([c2, c3, c4]));
      expect(stack.undoStack, isNot(contains(c1)));
    });

    test('clear wipes both undo and redo stacks', () {
      final stack = CommandStack();
      stack.execute(_MockCommand('1'));
      stack.execute(_MockCommand('2'));
      stack.undo();
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isTrue);

      stack.clear();

      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
      expect(stack.undoCount, equals(0));
      expect(stack.redoCount, equals(0));
    });
  });

  group('CommandStack - Change Notifications', () {
    test('notifies listeners on execute, undo, redo and clear', () {
      final stack = CommandStack();
      var notificationCount = 0;
      stack.addListener(() => notificationCount++);

      stack.execute(_MockCommand('1'));
      expect(notificationCount, equals(1));

      stack.undo();
      expect(notificationCount, equals(2));

      stack.redo();
      expect(notificationCount, equals(3));

      stack.clear();
      expect(notificationCount, equals(4));
    });

    test('unregistered listeners do not receive subsequent notifications', () {
      final stack = CommandStack();
      var notificationCount = 0;
      void listener() => notificationCount++;

      stack.addListener(listener);
      stack.execute(_MockCommand('1'));
      expect(notificationCount, equals(1));

      stack.removeListener(listener);
      stack.execute(_MockCommand('2'));
      expect(notificationCount, equals(1));
    });
  });
}
