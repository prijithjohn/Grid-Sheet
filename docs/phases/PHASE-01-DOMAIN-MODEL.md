# Phase 01 — Core Domain Model & Coordinate Engine

## 1. Phase Metadata
- **Phase Number:** `01`
- **Phase Name:** Core Domain Model & Coordinate Engine
- **Status:** `VERIFIED — AWAITING REVIEW`
- **Prerequisites:** Phase 00 complete and verified.
- **Implementation Branch:** `feature/phase-01-domain-model`
- **Completion Commit:** `53d600c`
- **Remote CI Run:** `39938340151` (Pull Request #1, Status: `completed`, Conclusion: `success`)

---

## 2. Purpose & Expected User-Visible Outcome
- **Purpose:** Construct the pure Dart domain foundation for coordinates, cell models, values, styles, sparse matrix worksheets, and multi-sheet workbooks. Maintain absolute architectural isolation (zero Flutter UI dependencies) to ensure high computation performance and testability.
- **Expected Outcome:** High-performance coordinate translation (A1 to XFD1048576), range intersection math, typed cell values with standard error tokens, immutable cell styles, sparse matrix storage scaling to 100k+ cells, and workbook tab management.

---

## 3. Verified Starting State
- Phase 00 baseline at commit `b2727e9` on `main`.
- 1 starter test passing, clean lint and format.

---

## 4. Scope Included
- `CellCoordinate`: 1-based `(row, col)` addressing, bi-directional A1 conversions up to row 1,048,576 and column 16,384 (`XFD`), anchor syntax parsing (`$A$1`), offset arithmetic.
- `CellRange`: Bounding rectangles, canonical coordinate normalization, spatial containment, range intersection.
- `CellValue`: Sealed class hierarchy (`StringCellValue`, `NumericCellValue`, `BooleanCellValue`, `ErrorCellValue`, `EmptyCellValue`) and standard spreadsheet error tokens (`#DIV/0!`, `#VALUE!`, `#REF!`, `#NAME?`, `#NUM!`, `#N/A!`, `#CIRCULAR!`).
- `CellStyle`: Immutable typography, font weight, fill color, text color, alignment, borders, number format tokens.
- `CellModel`: Composite container with automatic text parsing (numbers, booleans, formulas, strings).
- `Worksheet`: Sparse matrix storage (`Map<CellCoordinate, CellModel>`), custom row heights and column widths with minimum clamping (preventing UI collapse), Excel-compliant sheet name validation.
- `Workbook`: Multi-sheet aggregation, active sheet pointer, sheet CRUD, unique name generation, last-sheet deletion protection.
- Comprehensive pure-Dart unit test suite (73 domain tests + 1 isolation test).

---

## 5. Explicit Out-of-Scope Items
- Flutter widgets, painters, or UI rendering (strictly zero Flutter in `lib/domain/`).
- Reactive application state and Undo/Redo commands (deferred to Phase 02).
- Formula expression parsing and evaluation engine (deferred to Phase 04).

---

## 6. Dependencies on Earlier Phases
- **Phase 00:** Toolchain configuration, lint rules, CI automation.

---

## 7. Relevant Architecture & Existing Files
- `lib/domain/cell/cell_coordinate.dart`: Coordinate arithmetic and A1 formatting.
- `lib/domain/cell/cell_range.dart`: Range geometry and intersections.
- `lib/domain/cell/cell_value.dart`: Sealed value hierarchy and error constants.
- `lib/domain/cell/cell_style.dart`: Immutable styling representation.
- `lib/domain/cell/cell_model.dart`: Cell aggregate.
- `lib/domain/worksheet/worksheet_model.dart`: Sparse matrix worksheet.
- `lib/domain/workbook/workbook_model.dart`: Multi-sheet workbook aggregate.
- `lib/domain/domain.dart`: Barrel export file.

---

## 8. Proposed Implementation Steps (Executed)
1. Implement `CellCoordinate` with coordinate bounds (row 1..1048576, col 1..16384).
2. Implement `CellRange` with normalization and spatial intersection math.
3. Implement `CellValue` sealed hierarchy with standard spreadsheet errors.
4. Implement `CellStyle` immutable value object with copyWith semantics.
5. Implement `CellModel` with input type auto-detection.
6. Implement `Worksheet` sparse matrix model with dimension maps.
7. Implement `Workbook` multi-sheet aggregate with CRUD methods.
8. Author pure Dart unit test suites and zero-Flutter architectural isolation test.

---

## 9. Required Tests & Verification
- Unit Tests:
  - `test/unit/cell/cell_coordinate_test.dart` (15 tests)
  - `test/unit/cell/cell_range_test.dart` (16 tests)
  - `test/unit/cell/cell_value_and_style_test.dart` (13 tests)
  - `test/unit/worksheet/worksheet_model_test.dart` (15 tests)
  - `test/unit/workbook/workbook_model_test.dart` (13 tests)
  - `test/unit/domain_isolation_test.dart` (1 test verifying zero `flutter` imports)
- Total Tests: 74/74 passed.
- Analysis: 0 warnings, 0 errors.

---

## 10. Exact Acceptance Criteria
- [x] Bi-directional A1 coordinate translation accurate across entire Excel coordinate space (A1 to XFD1048576).
- [x] Sparse matrix storage demonstrably avoids allocating memory for unpopulated cells.
- [x] Sheet name validation enforces Excel rules (1..31 chars, no `\ / ? * : [ ]`).
- [x] Workbook prevents removing the last remaining worksheet.
- [x] Architectural test confirms zero Flutter package imports in `lib/domain/`.
- [x] 100% automated test pass rate across 74 tests.

---

## 11. Commands Needed for Verification
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test
```

---

## 12. Git & CI Requirements
- Feature Branch: `feature/phase-01-domain-model`
- Commit Message: `feat(domain): phase 01 core domain model and coordinate engine`
- Remote CI: Pull Request #1 verified green (Run `39938340151`).

---

## 13. Known Risks & Rollback Considerations
- **Risk:** Memory bloat if full 2D arrays were used. Mitigated by `Map<CellCoordinate, CellModel>` sparse matrix.
- **Rollback:** Safe revert on feature branch.

---

## 14. Required Evidence for Completion
- Commit `53d600c` pushed to origin.
- CI Workflow Run `39938340151` passed.
- Test logs documented in [`docs/engineering/TEST_RESULTS.md`](../engineering/TEST_RESULTS.md).

---

## 15. Entry Gate
- Phase 00 verified and complete.

## 16. Exit Gate
- All 6 acceptance criteria verified, 74 tests passed, CI green.

---

## 17. Status & Evidence Links
- Commit: `53d600c` on `feature/phase-01-domain-model`.
- PR #1: [GitHub PR #1](https://github.com/prijithjohn/Grid-Sheet/pull/1).
- Actions Run: `39938340151` ([Actions Run](https://github.com/prijithjohn/Grid-Sheet/actions/runs/39938340151)).
