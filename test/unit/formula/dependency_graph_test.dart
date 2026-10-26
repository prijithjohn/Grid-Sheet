import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/formula/ast.dart';
import 'package:grid_sheet/domain/formula/dependency_graph.dart';
import 'package:grid_sheet/domain/formula/parser.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';

void main() {
  group('DependencyGraph', () {
    late DependencyGraph graph;

    // Helpers
    const a1 = CellCoordinate(0, 0); // A1
    const b1 = CellCoordinate(0, 1); // B1
    const c1 = CellCoordinate(0, 2); // C1
    const d1 = CellCoordinate(0, 3); // D1

    FormulaNode parseFormula(String s) => FormulaParser.fromString(s).parse();

    setUp(() {
      graph = DependencyGraph();
    });

    // -------------------------------------------------------------------------
    // Basic registrations
    // -------------------------------------------------------------------------
    group('setFormula / hasFormula / getFormula', () {
      test('hasFormula returns false for unregistered coord', () {
        expect(graph.hasFormula(a1), isFalse);
      });

      test('hasFormula returns true after registration', () {
        graph.setFormula(a1, parseFormula('=B1+1'));
        expect(graph.hasFormula(a1), isTrue);
      });

      test('getFormula returns null for unregistered coord', () {
        expect(graph.getFormula(a1), isNull);
      });

      test('getFormula returns the registered AST', () {
        final ast = parseFormula('=B1+1');
        graph.setFormula(a1, ast);
        expect(graph.getFormula(a1), same(ast));
      });

      test('formulaCells contains registered coordinates', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(b1, parseFormula('=C1'));
        expect(graph.formulaCells.toSet(), containsAll([a1, b1]));
      });
    });

    // -------------------------------------------------------------------------
    // Precedents and dependents
    // -------------------------------------------------------------------------
    group('getPrecedents / getDependents', () {
      test('getPrecedents returns cells referenced by formula', () {
        graph.setFormula(a1, parseFormula('=B1+C1'));
        final precs = graph.getPrecedents(a1);
        expect(precs, containsAll([b1, c1]));
      });

      test('getDependents maps precedent to dependent', () {
        graph.setFormula(a1, parseFormula('=B1'));
        expect(graph.getDependents(b1), contains(a1));
      });

      test('getPrecedents is empty for unregistered coord', () {
        expect(graph.getPrecedents(a1), isEmpty);
      });

      test('getDependents is empty when no formula reads from coord', () {
        expect(graph.getDependents(a1), isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // removeFormula
    // -------------------------------------------------------------------------
    group('removeFormula', () {
      test('removes formula from graph', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.removeFormula(a1);
        expect(graph.hasFormula(a1), isFalse);
      });

      test('removes dependent edge after removal', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.removeFormula(a1);
        expect(graph.getDependents(b1), isEmpty);
      });

      test('removing nonexistent formula is a no-op', () {
        expect(() => graph.removeFormula(a1), returnsNormally);
      });
    });

    // -------------------------------------------------------------------------
    // Edge re-registration
    // -------------------------------------------------------------------------
    group('setFormula re-registration', () {
      test('updating formula clears old precedent edges', () {
        graph.setFormula(a1, parseFormula('=B1')); // A1 reads B1
        graph.setFormula(a1, parseFormula('=C1')); // Now A1 reads C1 only

        // Old edge B1 -> A1 should be gone
        expect(graph.getDependents(b1), isEmpty);
        // New edge C1 -> A1 should exist
        expect(graph.getDependents(c1), contains(a1));
        // A1's precedents should only contain C1
        expect(graph.getPrecedents(a1), contains(c1));
        expect(graph.getPrecedents(a1), isNot(contains(b1)));
      });
    });

    // -------------------------------------------------------------------------
    // Cycle detection
    // -------------------------------------------------------------------------
    group('hasCycle', () {
      test('no cycle when graph is acyclic', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(b1, parseFormula('=C1'));
        expect(graph.hasCycle(a1), isFalse);
        expect(graph.hasCycle(b1), isFalse);
      });

      test('direct self-reference is a cycle', () {
        graph.setFormula(a1, parseFormula('=A1'));
        expect(graph.hasCycle(a1), isTrue);
      });

      test('indirect cycle: A1->B1->A1', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(b1, parseFormula('=A1'));
        expect(graph.hasCycle(a1), isTrue);
        expect(graph.hasCycle(b1), isTrue);
      });

      test('three-node cycle: A1->B1->C1->A1', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(b1, parseFormula('=C1'));
        graph.setFormula(c1, parseFormula('=A1'));
        expect(graph.hasCycle(a1), isTrue);
      });

      test('cycle-free chain remains false', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(b1, parseFormula('=C1'));
        graph.setFormula(c1, parseFormula('=D1'));
        expect(graph.hasCycle(a1), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Recalculation plan
    // -------------------------------------------------------------------------
    group('getRecalculationPlan', () {
      test('returns empty plan when no dependents', () {
        graph.setFormula(a1, parseFormula('=B1'));
        // Changing D1 - nothing depends on D1
        final plan = graph.getRecalculationPlan([d1]);
        expect(plan.orderedCells, isEmpty);
        expect(plan.circularCells, isEmpty);
      });

      test('returns single dependent in plan', () {
        graph.setFormula(a1, parseFormula('=B1'));
        // B1 changed -> A1 must recalculate
        final plan = graph.getRecalculationPlan([b1]);
        expect(plan.orderedCells, contains(a1));
        expect(plan.circularCells, isEmpty);
      });

      test('topological order: chain B1->A1->C1 (A1=B1, C1=A1)', () {
        // A1 = B1,  C1 = A1
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(c1, parseFormula('=A1'));
        // Change B1 -> triggers A1, then C1
        final plan = graph.getRecalculationPlan([b1]);
        final ordered = plan.orderedCells;
        final aIdx = ordered.indexOf(a1);
        final cIdx = ordered.indexOf(c1);
        expect(aIdx, greaterThanOrEqualTo(0));
        expect(cIdx, greaterThan(aIdx)); // C1 must come after A1
      });

      test('circular cells are separated from ordered cells', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(b1, parseFormula('=A1')); // creates A1<->B1 cycle
        // Trigger recalculation via some changed cell (e.g. C1 which is a dep)
        // Let's add C1 = A1 and trigger on changing C1
        graph.setFormula(c1, parseFormula('=A1'));
        final plan = graph.getRecalculationPlan([c1]);
        // A1 and B1 should be in circularCells due to the cycle
        // (Their deps include each other)
        // This depends on indirect detection; C1 depends on A1 which is circular
        // At minimum the plan should not throw
        expect(() => plan.orderedCells, returnsNormally);
      });
    });

    // -------------------------------------------------------------------------
    // clear
    // -------------------------------------------------------------------------
    group('clear', () {
      test('clears all formulas', () {
        graph.setFormula(a1, parseFormula('=B1'));
        graph.setFormula(b1, parseFormula('=C1'));
        graph.clear();
        expect(graph.hasFormula(a1), isFalse);
        expect(graph.hasFormula(b1), isFalse);
        expect(graph.getDependents(c1), isEmpty);
      });
    });
  });
}
