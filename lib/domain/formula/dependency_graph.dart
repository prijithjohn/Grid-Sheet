import 'dart:collection';

import '../cell/cell_coordinate.dart';
import '../cell/cell_range.dart';
import 'ast.dart';

/// Directed dependency graph managing precedent-dependent relationships between formula cells.
///
/// Precedents: cells that a formula cell reads from.
/// Dependents: formula cells that rely on a cell's value.
class DependencyGraph {
  /// Maps precedent coordinate -> set of dependent formula coordinates.
  final Map<CellCoordinate, Set<CellCoordinate>> _dependents = {};

  /// Maps dependent formula coordinate -> set of precedent coordinates it reads from.
  final Map<CellCoordinate, Set<CellCoordinate>> _precedents = {};

  /// Maps formula coordinate -> parsed AST node.
  final Map<CellCoordinate, FormulaNode> _formulas = {};

  /// Returns true if [coordinate] currently holds a registered formula.
  bool hasFormula(CellCoordinate coordinate) =>
      _formulas.containsKey(coordinate);

  /// Returns the parsed AST for [coordinate], or null if unpopulated or not a formula.
  FormulaNode? getFormula(CellCoordinate coordinate) => _formulas[coordinate];

  /// Returns all currently registered formula coordinates.
  Iterable<CellCoordinate> get formulaCells => _formulas.keys;

  /// Returns the immediate precedents for [coordinate].
  Set<CellCoordinate> getPrecedents(CellCoordinate coordinate) =>
      _precedents[coordinate] ?? const {};

  /// Returns the immediate dependents for [coordinate].
  Set<CellCoordinate> getDependents(CellCoordinate coordinate) =>
      _dependents[coordinate] ?? const {};

  /// Registers or updates a formula at [coordinate] with its parsed [ast].
  ///
  /// Cleans up any prior dependencies to prevent stale edges.
  void setFormula(CellCoordinate coordinate, FormulaNode ast) {
    // 1. Remove previous precedents
    final oldPrecedents = _precedents.remove(coordinate);
    if (oldPrecedents != null) {
      for (final p in oldPrecedents) {
        final deps = _dependents[p];
        if (deps != null) {
          deps.remove(coordinate);
          if (deps.isEmpty) _dependents.remove(p);
        }
      }
    }

    // 2. Register AST
    _formulas[coordinate] = ast;

    // 3. Extract new precedents
    final coords = <CellCoordinate>[];
    final ranges = <CellRange>[];
    ast.collectReferences(coordinates: coords, ranges: ranges);

    final newPrecedents = coords.toSet();
    _precedents[coordinate] = newPrecedents;

    // 4. Update dependents mapping
    for (final p in newPrecedents) {
      _dependents.putIfAbsent(p, () => <CellCoordinate>{}).add(coordinate);
    }
  }

  /// Removes a formula at [coordinate], clearing its precedents and dependent edges.
  void removeFormula(CellCoordinate coordinate) {
    _formulas.remove(coordinate);

    final precedents = _precedents.remove(coordinate);
    if (precedents != null) {
      for (final p in precedents) {
        final deps = _dependents[p];
        if (deps != null) {
          deps.remove(coordinate);
          if (deps.isEmpty) _dependents.remove(p);
        }
      }
    }
  }

  /// Clears all formula registrations and dependency edges.
  void clear() {
    _dependents.clear();
    _precedents.clear();
    _formulas.clear();
  }

  /// Checks if [coordinate] is involved in a direct or indirect circular reference.
  bool hasCycle(CellCoordinate coordinate) {
    final visited = <CellCoordinate>{};
    final inStack = <CellCoordinate>{};

    bool dfs(CellCoordinate current) {
      visited.add(current);
      inStack.add(current);

      final precedents = _precedents[current] ?? const {};
      for (final p in precedents) {
        if (p == coordinate) return true; // Direct loop to target
        if (!visited.contains(p)) {
          if (dfs(p)) return true;
        } else if (inStack.contains(p)) {
          return true; // Indirect cycle detected
        }
      }

      inStack.remove(current);
      return false;
    }

    return dfs(coordinate);
  }

  /// Finds all transitive dependents that must be recalculated when [changedCells] are modified.
  ///
  /// Returns a record with:
  /// - `orderedCells`: Topologically sorted list of non-circular formula cells in evaluation order.
  /// - `circularCells`: Set of formula cells trapped in circular dependencies.
  ({List<CellCoordinate> orderedCells, Set<CellCoordinate> circularCells})
      getRecalculationPlan(Iterable<CellCoordinate> changedCells) {
    // 1. Collect all transitive dependents
    final affected = <CellCoordinate>{};
    final queue = Queue<CellCoordinate>.from(changedCells);
    final seen = <CellCoordinate>{...changedCells};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final deps = _dependents[current] ?? const {};
      for (final dep in deps) {
        if (_formulas.containsKey(dep)) {
          affected.add(dep);
        }
        if (!seen.contains(dep)) {
          seen.add(dep);
          queue.add(dep);
        }
      }
    }

    if (affected.isEmpty) {
      return (orderedCells: const [], circularCells: const {});
    }

    // 2. Identify circular cells among affected
    final circular = <CellCoordinate>{};
    for (final cell in affected) {
      if (hasCycle(cell)) {
        circular.add(cell);
      }
    }

    // Any cell whose precedents include a circular cell also cannot evaluate properly
    bool addedMoreCircular = true;
    while (addedMoreCircular) {
      addedMoreCircular = false;
      for (final cell in affected) {
        if (!circular.contains(cell)) {
          final precedents = _precedents[cell] ?? const {};
          if (precedents.any((p) => circular.contains(p))) {
            circular.add(cell);
            addedMoreCircular = true;
          }
        }
      }
    }

    final nonCircular = affected.difference(circular);

    // 3. Topologically sort non-circular affected formula cells (Kahn's algorithm)
    // Compute in-degrees restricted to the nonCircular affected set
    final inDegree = <CellCoordinate, int>{};
    for (final cell in nonCircular) {
      inDegree[cell] = 0;
    }

    for (final cell in nonCircular) {
      final deps = _dependents[cell] ?? const {};
      for (final dep in deps) {
        if (nonCircular.contains(dep)) {
          inDegree[dep] = (inDegree[dep] ?? 0) + 1;
        }
      }
    }

    // Priority queue / sorted queue for determinism: row, then col
    final readyList = inDegree.entries
        .where((e) => e.value == 0)
        .map((e) => e.key)
        .toList();

    _sortCoordinates(readyList);
    final sortedQueue = Queue<CellCoordinate>.from(readyList);
    final ordered = <CellCoordinate>[];

    while (sortedQueue.isNotEmpty) {
      final node = sortedQueue.removeFirst();
      ordered.add(node);

      final nextReady = <CellCoordinate>[];
      final deps = _dependents[node] ?? const {};
      for (final dep in deps) {
        if (nonCircular.contains(dep)) {
          final newDeg = (inDegree[dep] ?? 1) - 1;
          inDegree[dep] = newDeg;
          if (newDeg == 0) {
            nextReady.add(dep);
          }
        }
      }

      if (nextReady.isNotEmpty) {
        _sortCoordinates(nextReady);
        sortedQueue.addAll(nextReady);
      }
    }

    // In case of unexpected dangling cycle, any remaining in nonCircular goes to circular
    if (ordered.length < nonCircular.length) {
      for (final cell in nonCircular) {
        if (!ordered.contains(cell)) {
          circular.add(cell);
        }
      }
    }

    return (orderedCells: ordered, circularCells: circular);
  }

  void _sortCoordinates(List<CellCoordinate> list) {
    list.sort((a, b) {
      final rowCmp = a.row.compareTo(b.row);
      if (rowCmp != 0) return rowCmp;
      return a.col.compareTo(b.col);
    });
  }
}
