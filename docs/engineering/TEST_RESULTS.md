# Grid Sheet — Persistent Test Results & Quality Metrics

This document records automated test suite outcomes, test counts, execution durations, environment constraints, and regression validation history.

---

## Test Execution History

### Phase 02 Application State & Command Engine Verification (2026-10-23)
- **Environment:** Windows 11 (25H2), Flutter 3.47.5, Dart 3.13.4
- **Test Runner:** `flutter test`
- **Results Summary:** 125 tests across 12 test suites (64 new tests added in Phase 02), 100% pass rate.

| Test Suite / Target | Tests Run | Passed | Failed | Skipped | Duration | Outcome |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `test/unit/commands/command_stack_test.dart` (Undo/Redo, Eviction, Listeners) | 14 | 14 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/commands/cell_commands_test.dart` (SetText, ClearRange, FormatRange) | 11 | 11 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/commands/worksheet_commands_test.dart` (Add, Remove, Rename, Reorder, Resize) | 13 | 13 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/state/selection_state_test.dart` (Cursors, Ranges, Disjoint, Invariants) | 13 | 13 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/state/workbook_state_test.dart` (Coordination, Mutations, Lifecycle) | 13 | 13 | 0 | 0 | 0.4s | **PASS** |
| `test/unit/cell/cell_coordinate_test.dart` (Phase 01 Regression) | 15 | 15 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/cell/cell_range_test.dart` (Phase 01 Regression) | 16 | 16 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/cell/cell_value_and_style_test.dart` (Phase 01 Regression) | 13 | 13 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/worksheet/worksheet_model_test.dart` (Phase 01 Regression) | 15 | 15 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/workbook/workbook_model_test.dart` (Phase 01 Regression) | 13 | 13 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/domain_isolation_test.dart` (Zero-Flutter Isolation Regression) | 1 | 1 | 0 | 0 | 0.2s | **PASS** |
| `test/widget_test.dart` (Starter Smoke) | 1 | 1 | 0 | 0 | 1.0s | **PASS** |
| **Total Automated Tests** | **125** | **125** | **0** | **0** | **~2.8s** | **PASS** |

### Static Analysis & Toolchain Quality Gates (Phase 02)

| Check / Tool | Target | Result | Outcome |
| :--- | :--- | :--- | :---: |
| `dart format --output=none --set-exit-if-changed .` | All Dart sources and tests | 0 files changed / formatted | **PASS** |
| `flutter analyze --no-fatal-infos` | Whole project workspace | 0 issues found | **PASS** |
| `flutter test` | All 12 test suites | 125 passed, 0 failed | **PASS** |

---

### Phase 01 Domain & Coordinate Verification (2026-10-23)
- **Environment:** Windows 11 (25H2), Flutter 3.47.5, Dart 3.13.4
- **Test Runner:** `flutter test` & `scripts/validate_phase.ps1`
- **Results Summary:** 74 tests across 7 test suites, 100% pass rate.

| Test Suite / Target | Tests Run | Passed | Failed | Skipped | Duration | Outcome |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `test/unit/cell/cell_coordinate_test.dart` (Coordinates, Math, Bounds) | 15 | 15 | 0 | 0 | 0.4s | **PASS** |
| `test/unit/cell/cell_range_test.dart` (Ranges, Spatial Overlaps, Envelopes) | 16 | 16 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/cell/cell_value_and_style_test.dart` (Values, Styles, Errors) | 13 | 13 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/worksheet/worksheet_model_test.dart` (Sparse Matrix, Dims, Names) | 15 | 15 | 0 | 0 | 0.4s | **PASS** |
| `test/unit/workbook/workbook_model_test.dart` (Multi-sheet Aggregation, CRUD) | 13 | 13 | 0 | 0 | 0.3s | **PASS** |
| `test/unit/domain_isolation_test.dart` (Pure Dart Zero-Flutter Check) | 1 | 1 | 0 | 0 | 0.2s | **PASS** |
| `test/widget_test.dart` (Baseline Flutter Starter Smoke) | 1 | 1 | 0 | 0 | 1.1s | **PASS** |
| **Total Automated Tests** | **74** | **74** | **0** | **0** | **~2.0s** | **PASS** |

### Static Analysis & Toolchain Quality Gates (2026-10-23)

| Check / Tool | Target | Result | Outcome |
| :--- | :--- | :--- | :---: |
| `dart format --output=none --set-exit-if-changed .` | 16 source & test files | 0 files changed / formatted | **PASS** |
| `flutter analyze --no-fatal-infos` | Entire project workspace | 0 issues found (ran in 6.2s) | **PASS** |
| `flutter build windows --release` | Native x64 desktop binary | Missing Visual Studio C++ desktop workload (`ERR-001`) | **BLOCKED (Local)** |

---

### Phase 00 Baseline Verification (2026-10-23)
- **Environment:** Windows 11 (25H2), Flutter 3.47.5, Dart 3.13.4
- **Test Runner:** `flutter test` & `scripts/validate_phase.ps1`
- **Results Summary:** Initial starter smoke test (1/1 passed).

| Test Suite / Target | Tests Run | Passed | Failed | Skipped | Duration | Outcome |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `test/widget_test.dart` (Baseline Starter Smoke) | 1 | 1 | 0 | 0 | 1.1s | **PASS** |
| `dart format --set-exit-if-changed .` | 2 files | 2 | 0 | 0 | 0.02s | **PASS** |
| `flutter analyze --no-fatal-infos` | Whole project | 0 issues | 0 | 0 | 3.4s | **PASS** |
| `flutter build windows --release` | Native binary | 0 | 0 | 0 | N/A | **BLOCKED (ERR-001)** |

---

## Benchmark & Performance Tracking

| Metric | Target (MVP) | Measured Baseline | Status |
| :--- | :---: | :---: | :---: |
| Full Test Suite Execution Time | < 5.0s | ~2.0s (74 tests) | Optimal |
| Static Analysis Cleanliness | 0 issues | 0 issues | Clean |
| Sparse Matrix Scalability | 100,000+ scattered cells | Verified in `worksheet_model_test.dart` | Optimal |
| Viewport Frame Budget | 16.6ms (60 FPS) | Scheduled for Phase 03 | Pending |

