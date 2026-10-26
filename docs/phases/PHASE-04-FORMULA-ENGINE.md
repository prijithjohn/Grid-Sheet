# Phase 04 — Formula Engine & Calculation Subsystem

## 1. Phase Metadata
- **Phase Number:** `04`
- **Phase Name:** Formula Engine
- **Status:** `NOT STARTED`
- **Prerequisites:** Phase 01 (Domain Coordinates & Cell Models), Phase 02 (Application State).
- **Implementation Branch:** `feature/phase-04-formula-engine`
- **Remote CI Run:** Pending implementation.

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Construct a deterministic, high-performance formula calculation subsystem capable of tokenizing formula strings, parsing AST expressions, resolving cell and range dependencies in a Directed Acyclic Graph (DAG), detecting circular references, and evaluating standard spreadsheet functions.
- **Expected Outcome:** Entering `=SUM(A1:A10)` or `=IF(B2>100, B2*1.1, B2)` evaluates instantly and displays the computed numerical or textual result in the grid cell, with instant reactive recalculation of dependent cells when precedents change.

---

## 3. Verified Starting State
- Phase 01 domain models provide `CellValue` sealed hierarchy with standard spreadsheet error tokens (`#DIV/0!`, `#VALUE!`, `#REF!`, `#NAME?`, `#NUM!`, `#N/A!`, `#CIRCULAR!`).
- `CellModel` holds `rawInput` and formula detection flag (`isFormula`).

---

## 4. Scope Included
- **Formula Lexer (`formula_lexer.dart`):** Tokenizes numbers, strings, cell coordinates (`A1`), absolute coordinates (`$A$1`), ranges (`A1:C10`), arithmetic operators (`+`, `-`, `*`, `/`, `^`, `%`), comparison operators (`=`, `<>`, `<`, `<=`, `>`, `>=`), punctuation (`(`, `)`, `,`), and function identifiers.
- **Formula AST Parser (`formula_parser.dart`):** Recursive descent / Pratt parser with standard operator precedence constructing immutable `FormulaNode` AST.
- **Dependency Graph (`dependency_graph.dart`):** Directed Acyclic Graph (DAG) mapping cell dependencies, tracking precedent-dependent relationships, and detecting circular references (Tarjan's algorithm or DFS cycle detection).
- **Evaluation Engine (`formula_evaluator.dart`):** Topological evaluator calculating cells in dependency order with automated error propagation.
- **Built-in Function Library (`function_registry.dart`):**
  - Math: `SUM`, `AVERAGE`, `MIN`, `MAX`, `ABS`, `ROUND`, `MOD`.
  - Counting: `COUNT`, `COUNTA`, `COUNTIF`.
  - Logical: `IF`, `AND`, `OR`, `NOT`.
  - Lookup: `VLOOKUP`, `INDEX`, `MATCH`.
  - Conditionals: `SUMIF`, `SUMIFS`.
- Pure Dart unit test suite covering precedence, error conditions, deep DAG trees, and circular dependency checks (100+ tests).

---

## 5. Explicit Out-of-Scope Items
- External workbook links or cross-file formulas (deferred).
- Array formulas / dynamic array spilling (deferred to future enhancement).
- Formatting dialogs and in-cell rendering (handled in Phase 03 and 05).

---

## 6. Dependencies on Earlier Phases
- **Phase 01:** `CellCoordinate`, `CellRange`, `CellValue`, `CellModel`, `Worksheet`.
- **Phase 02:** `WorkbookState` mutation pipeline.

---

## 7. Relevant Architecture & Existing Files
- `lib/domain/cell/cell_value.dart`: Sealed value classes and error constants.
- `lib/domain/cell/cell_coordinate.dart`: Coordinate parsing and offsets.
- `lib/domain/cell/cell_range.dart`: Range geometry and iteration.
- Target path: `lib/domain/formula/`.

---

## 8. Proposed Implementation Steps
1. Implement `FormulaToken` and `FormulaLexer` in `lib/domain/formula/lexer/`.
2. Implement `FormulaNode` AST hierarchy (Literal, Reference, Range, BinaryOp, UnaryOp, FunctionCall).
3. Implement `FormulaParser` with operator precedence climbing.
4. Implement `DependencyGraph` with cycle detection in `lib/domain/formula/graph/`.
5. Implement `FunctionRegistry` and standard mathematical/logical functions in `lib/domain/formula/functions/`.
6. Implement `FormulaEvaluator` with topological sorting and error handling.
7. Connect evaluator to `WorkbookState` so cell edits trigger DAG invalidation and re-evaluation.
8. Author comprehensive formula test suites.

---

## 9. Required Tests & Verification
- Unit Tests:
  - `test/unit/formula/formula_lexer_test.dart` (tokens, operators, strings)
  - `test/unit/formula/formula_parser_test.dart` (AST nodes, precedence)
  - `test/unit/formula/dependency_graph_test.dart` (DAG, cycle detection `#CIRCULAR!`)
  - `test/unit/formula/formula_evaluator_test.dart` (arithmetic, error propagation `#DIV/0!`, `#VALUE!`)
  - `test/unit/formula/functions_test.dart` (SUM, AVERAGE, IF, SUMIFS, VLOOKUP)
- Target: 100+ formula unit tests, 100% pass rate.

---

## 10. Exact Acceptance Criteria
- [ ] Lexer and Parser correctly handle expressions with mixed precedence, parentheses, and nested function calls.
- [ ] Dependency graph detects circular references (`A1 = B1 + 1`, `B1 = A1 * 2`) and assigns `#CIRCULAR!`.
- [ ] Division by zero yields `#DIV/0!`.
- [ ] Invalid cell references yield `#REF!`.
- [ ] Unknown function names yield `#NAME?`.
- [ ] Built-in functions (`SUM`, `AVERAGE`, `COUNT`, `MIN`, `MAX`, `IF`, `SUMIF`, `VLOOKUP`) calculate identical results to standard spreadsheet software.
- [ ] Editing a precedent cell automatically recalculates all dependent cells in the sheet.

---

## 11. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test test/unit/formula/
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-04-formula-engine`
- Base: Verified Phase 03 branch.

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Deep dependency trees causing stack overflow or slow recalculations. Mitigated by iterative topological sort rather than naive recursion.
- **Rollback:** `git revert <commit-sha>`.

---

## 14. Required Evidence for Completion
- 100+ formula tests passing.
- 0 analysis issues.
- Phase Execution Report filed.

---

## 15. Entry Gate
- Phase 02 & 03 completed and verified.

## 16. Exit Gate
- All 7 acceptance criteria verified, formula test suite green.

---

## 17. Status & Evidence Links
- Status: `NOT STARTED` ([`PHASE-STATUS.md`](../engineering/phase-control/PHASE-STATUS.md)).
